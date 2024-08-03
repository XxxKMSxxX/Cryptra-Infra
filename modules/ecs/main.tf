####################
# ECS Cluster
####################
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-ecs-cluster"
  tags = var.tags
}

####################
# Launch Template
####################
resource "aws_launch_template" "ecs_instance" {
  name_prefix   = "${var.project_name}-launch-configuration-"
  image_id      = data.aws_ami.ecs.id
  instance_type = var.instance_type
  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
    EOF
  )

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
  }
}

####################
# Auto Scaling Group
####################
resource "aws_autoscaling_group" "ecs_asg" {
  desired_capacity    = 1
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.private_1a.id]

  launch_template {
    id      = aws_launch_template.ecs_instance.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-ecs-instance"
    propagate_at_launch = true
  }
}

# スケールアウト
resource "aws_autoscaling_policy" "scale_out_policy" {
  name                   = "${var.project_name}-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ecs_asg.name
}

# スケールイン
resource "aws_autoscaling_policy" "scale_in_policy" {
  name                   = "${var.project_name}-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ecs_asg.name
}

resource "aws_cloudwatch_metric_alarm" "scale_out_alarm" {
  alarm_name          = "${var.project_name}-scale-out-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "Scale out if CPUUtilization >= 75% for 2 minutes"
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_out_policy.arn]
}

resource "aws_cloudwatch_metric_alarm" "scale_in_alarm" {
  alarm_name          = "${var.project_name}-scale-in-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "25"
  alarm_description   = "Scale in if CPUUtilization <= 25% for 2 minutes"
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_in_policy.arn]
}

####################
# ECS Task Definition
####################
resource "aws_ecs_task_definition" "ecs_task_definitions" {
  for_each = local.collects

  family                   = "${var.project_name}-collector-${each.key}-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${var.ecr_registry}:latest"
      essential = true
      memory    = 96
      cpu       = 96
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/${var.project_name}/ecs"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 0
        }
      ]
      environment = [
        {
          name  = "EXCHANGE"
          value = each.value.exchange
        },
        {
          name  = "CONTRACT"
          value = each.value.contract
        },
        {
          name  = "SYMBOL"
          value = each.value.symbol
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = var.tags
}

####################
# CloudWatch Log Group
####################
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/${var.project_name}/ecs"
  retention_in_days = 1
  tags              = var.tags
}

####################
# ECS Service
####################
resource "aws_ecs_service" "this" {
  for_each = { for k, v in aws_ecs_task_definition.ecs_task_definitions : replace(v.family, "task", "service") => v }

  name            = each.key
  cluster         = aws_ecs_cluster.main.id
  task_definition = each.value.arn
  desired_count   = 1
  launch_type     = "EC2"

  deployment_controller {
    type = "ECS"
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
}

####################
# IAM Role for ECS Task
####################
data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.project_name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
}

####################
# IAM Role Policy Attachment for EC2
####################
resource "aws_iam_role_policy_attachment" "ecs_for_ec2_role" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
