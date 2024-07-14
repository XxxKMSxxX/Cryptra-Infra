terraform {
  source = "../../../modules/kinesis"
}

include {
  path = "${get_terragrunt_dir()}/../common.hcl"
}

inputs = {
  project_name = local.project_name
  collects     = local.collects
}
