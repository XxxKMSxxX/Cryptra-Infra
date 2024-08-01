provider "aws" {
  region = "us-west-2"
}

resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"
  tags = var.tags
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

resource "aws_ecs_task_definition" "ecs_task_definitions" {
  for_each = local.collects

  family        = "${var.project_name}-collector-${each.key}-task"
  network_mode  = "bridge"
  task_role_arn = aws_iam_role.ecs_task_role.arn

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
          containerPort = var.container_port
          hostPort      = each.value.host_port
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
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = var.tags
}

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  vpc_id      = var.vpc_id
  description = "ECS security group"

  dynamic "ingress" {
    for_each = local.collects
    content {
      from_port   = ingress.value.host_port
      to_port     = ingress.value.host_port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_ecs_service" "this" {
  for_each = local.collects

  name                 = "${var.project_name}-collector-${each.key}-service"
  cluster              = aws_ecs_cluster.this.id
  task_definition      = aws_ecs_task_definition.ecs_task_definitions[each.key].arn
  desired_count        = 1
  launch_type          = "EC2"
  force_new_deployment = true

  health_check_grace_period_seconds = 60

  deployment_controller {
    type = "ECS"
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
}