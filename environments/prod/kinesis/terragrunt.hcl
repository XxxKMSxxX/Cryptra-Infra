terraform {
  source = "../../../modules/kinesis"
}

include {
  path = find_in_parent_folders("environments/prod/terragrunt.hcl")
}

inputs = {
  project_name = local.project_name
  collects     = local.collects
}
