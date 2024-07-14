include {
  path = find_in_parent_folders("common.hcl")
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("env.yaml")))
}

terraform {
  source = "../../../modules/kinesis"
}

inputs = {
  project_name = local.common_vars.project_name
  collects     = local.common_vars.collects
}
