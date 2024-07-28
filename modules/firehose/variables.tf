variable "stream_name" {
  description = "The name of the Firehose stream"
  type        = string
}

variable "role_arn" {
  description = "The ARN of the IAM role for Firehose"
  type        = string
}

variable "bucket_arn" {
  description = "The ARN of the S3 bucket for Firehose to deliver data"
  type        = string
}

variable "s3_prefix" {
  description = "The prefix for the S3 bucket"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to assign to the repository"
  type        = map(string)
  default     = {}
}
