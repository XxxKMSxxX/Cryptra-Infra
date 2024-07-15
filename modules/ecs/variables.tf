variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_ids" {
  description = "The list of subnet IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}
