variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "collects" {
  description = "The collects configuration"
  type = map(object({
    contracts = map(list(string))
  }))
}
