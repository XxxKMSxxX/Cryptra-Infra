include {
  path = find_in_parent_folders("terragrunt.hcl")
}

locals {
  common_vars  = yamldecode(file(find_in_parent_folders("env.yaml")))
  project_name = local.common_vars.project_name
}

terraform {
  source = "../../../modules/ecr"
}

inputs = {
  repository_name = "${local.project_name}-collector"
}