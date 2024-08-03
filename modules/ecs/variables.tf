variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "vpc" {
  description = "Parameter for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet" {
  description = "Parameter for public subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "private_subnet" {
  description = "Parameter for private subnet"
  type        = string
  default     = "10.0.128.0/24"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "ecr_registry" {
  description = "ECR registry URI"
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

variable "tags" {
  description = "A map of tags to assign to the repository"
  type        = map(string)
  default     = {}
}
