terraform {
  source = "../../../modules/ecr"
}

include {
  path = "${get_terragrunt_dir()}/../common.hcl"
}

inputs = {
  repository_name = "${local.project_name}-collector"
}
