terraform {
  source = "../../../modules/ecr"
}

include {
  path = find_in_parent_folders("environments/prod/terragrunt.hcl")
}

locals {
  project_name = read_terragrunt_config(find_in_parent_folders("environments/prod/terragrunt.hcl")).locals.project_name
}

inputs = {
  repository_name = "${local.project_name}-collector"
}
