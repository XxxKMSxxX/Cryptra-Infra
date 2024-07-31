variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "collects" {
  description = "The collects configuration"
  type        = map(map(list(string)))
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_role_arn" {
  description = "AWS role arn"
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "The list of subnet IDs"
  type        = list(string)
}

variable "ecr_registry" {
  description = "ECR registry URI"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the repository"
  type        = map(string)
  default     = {}
}

variable "host_port_start" {
  type    = number
  default = 8080
}

variable "container_port" {
  type    = number
  default = 8080
}
