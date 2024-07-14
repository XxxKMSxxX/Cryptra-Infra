locals {
  common_vars = yamldecode(file(find_in_parent_folders("common.yaml")))
}

terraform {
  source = "../../../modules/ecr"
}

inputs = {
  repository_name = "${local.common_vars.project_name}-collector"
}