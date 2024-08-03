####################
# ami
####################
data "aws_ami" "ecs" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

####################
# ec2
####################
# resource "aws_instance" "main" {
#   instance_type          = var.instance_type
#   ami                    = data.aws_ami.latest_amazon_linux2.id
#   subnet_id              = aws_subnet.private_1a.id
#   vpc_security_group_ids = [aws_security_group.main.id]
#   iam_instance_profile   = aws_iam_instance_profile.instance_profile.name
#   user_data              = <<-EOF
#               #!/bin/bash
#               echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
#               EOF

#   root_block_device {
#     volume_size           = 8
#     volume_type           = "gp3"
#     iops                  = 3000
#     throughput            = 125
#     delete_on_termination = true

#     # EBSのNameタグ
#     tags = var.tags
#   }
#   lifecycle {
#     ignore_changes = [
#       ami,
#     ]
#   }

#   tags = var.tags
# }

####################
# security group
####################
resource "aws_security_group" "main" {
  name   = "${var.project_name}-sg"
  vpc_id = aws_vpc.main.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

####################
# ec2 iam role
####################
# インスタンスプロファイルを作成
resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.instance_role.name
}

resource "aws_iam_role" "instance_role" {
  name               = "${var.project_name}-instance_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
