variable "stream_name" {
  description = "The name of stream"
  type        = string
}
variable "tags" {
  description = "A map of tags to assign to the repository"
  type        = map(string)
  default     = {}
}
