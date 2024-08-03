####################
# ECS Cluster
####################
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-ecs-cluster"
  tags = var.tags
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
        command     = ["CMD", "curl -f http://localhost:8080/health || exit 1"]
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

  network_configuration {
    subnets         = [aws_subnet.private_1a.id]
    security_groups = [aws_security_group.main.id]
  }

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
