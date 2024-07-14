variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "collects" {
  description = "The trading pairs for different exchanges"
  type        = map(any)
}
