resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"
}

resource "aws_launch_configuration" "ecs" {
  name_prefix          = "${var.project_name}-launch-configuration-"
  image_id             = data.aws_ami.ecs.id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ecs_instance_profile.name
  user_data            = <<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_ami" "ecs" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

data "aws_iam_policy_document" "ecs_instance_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name               = "${var.project_name}-ecs-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_instance_assume_role.json
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.project_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_instance_policy_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_autoscaling_group" "ecs" {
  launch_configuration = aws_launch_configuration.ecs.id
  min_size             = 1
  max_size             = 1
  desired_capacity     = 1
  vpc_zone_identifier  = var.subnet_ids

  tag {
    key                 = "Name"
    value               = "${var.project_name}-ecs-instance"
    propagate_at_launch = true
  }
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/${var.project_name}/ecs"
  retention_in_days = 1
  tags              = var.tags
}

data "aws_iam_policy_document" "ecs_task_role_assume_policy" {
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
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "custom_ecs_task_policy" {
  name = "${var.project_name}-ecs-task-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sts:AssumeRole"
        ],
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/cryptra-collector-role"
      },
      {
        Effect = "Allow",
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_custom_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.custom_ecs_task_policy.arn
}

resource "aws_ecs_task_definition" "ecs_task_definitions" {
  for_each = {
    for task in local.tasks :
    lower("${task.exchange}-${task.contract_type}-${task.symbol}") => task
  }

  family             = "${var.project_name}-${each.key}-task"
  network_mode       = "bridge"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${var.ecr_registry}:latest"
      essential = true
      memory    = 512
      cpu       = 256
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
          containerPort = 80
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
          value = each.value.contract_type
        },
        {
          name  = "SYMBOL"
          value = each.value.symbol
        },
        {
          name  = "AWS_ROLE_ARN"
          value = var.aws_role_arn
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        }
      ]
    }
  ])
}

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  vpc_id      = var.vpc_id
  description = "ECS security group"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "app" {
  name               = "${var.project_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs.id]
  subnets            = var.subnet_ids
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_ecs_service" "this" {
  for_each             = aws_ecs_task_definition.ecs_task_definitions
  name                 = "${var.project_name}-${each.key}-service"
  cluster              = aws_ecs_cluster.this.id
  task_definition      = each.value.arn
  desired_count        = 1
  launch_type          = "EC2"
  force_new_deployment = true

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 80
  }

  health_check_grace_period_seconds = 60

  deployment_controller {
    type = "ECS"
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  depends_on = [aws_lb_listener.app]
}
