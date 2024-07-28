variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "stream_name" {
  description = "The name of stream"
  type        = string
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
