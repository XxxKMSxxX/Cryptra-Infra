include {
  path = "../common.hcl"
}

terraform {
  source = "../../../modules/kinesis"
}

inputs = {
  project_name = local.project_name
  collects     = local.collects
}
