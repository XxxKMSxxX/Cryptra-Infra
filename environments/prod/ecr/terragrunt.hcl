include {
  path = find_in_parent_folders("common.hcl")
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("env.yaml")))
}

terraform {
  source = "../../../modules/ecr"
}

inputs = {
  repository_name = "${local.common_vars.project_name}-collector"
}