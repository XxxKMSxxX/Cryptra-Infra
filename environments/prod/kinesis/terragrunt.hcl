terraform {
  source = "../../../modules/kinesis"
}

include {
  path = find_in_parent_folders("environments/prod/terragrunt.hcl")
}

locals {
  project_name = read_terragrunt_config(find_in_parent_folders("environments/prod/terragrunt.hcl")).locals.project_name
  collects     = read_terragrunt_config(find_in_parent_folders("environments/prod/terragrunt.hcl")).locals.collects
}

inputs = {
  project_name = local.project_name
  collects     = local.collects
}
