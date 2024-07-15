resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"
}

resource "aws_launch_configuration" "ecs" {
  name                 = "${var.project_name}-launch-configuration"
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

resource "aws_iam_role" "ecs_instance_role" {
  name               = "${var.project_name}-ecs-instance-role"
  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
    EOF
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

resource "aws_ecs_task_definition" "ecs_task_definitions" {
  for_each = {
    for task in local.tasks :
    lower("${task.exchange}-${task.contract_type}-${task.symbol}") => task
  }

  family       = "${var.project_name}-${each.key}-task"
  network_mode = "bridge"
  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${var.ecr_registry}:latest"
      essential = true
      memory    = 512
      cpu       = 256
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
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

resource "aws_iam_role" "ecs_service_linked_role" {
  name               = "${var.project_name}-ecs-service-role"
  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "ecs.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  EOF
}

resource "aws_iam_policy" "ecs_custom_service_policy" {
  name        = "${var.project_name}-ecs-service-policy"
  description = "Custom policy for ECS service role"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ecs:CreateCluster",
          "ecs:DeleteCluster",
          "ecs:DeregisterContainerInstance",
          "ecs:DiscoverPollEndpoint",
          "ecs:Poll",
          "ecs:RegisterContainerInstance",
          "ecs:StartTelemetrySession",
          "ecs:Submit*",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:Describe*",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "elasticloadbalancing:Describe*",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_service_linked_role_attachment" {
  role       = aws_iam_role.ecs_service_linked_role.name
  policy_arn = aws_iam_policy.ecs_custom_service_policy.arn
}

resource "aws_ecs_service" "this" {
  for_each        = aws_ecs_task_definition.ecs_task_definitions
  name            = "${var.project_name}-${each.key}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = each.value.arn
  desired_count   = 1
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 80
  }

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.ecs.id]
  }

  health_check_grace_period_seconds = 60

  deployment_controller {
    type = "ECS"
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  depends_on = [
    aws_lb_listener.app,
    aws_iam_role.ecs_service_linked_role,
    aws_iam_role_policy_attachment.ecs_service_linked_role_attachment
  ]
}
