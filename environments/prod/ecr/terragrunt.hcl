include {
  path = "../common.hcl"
}

terraform {
  source = "../../../modules/ecr"
}

inputs = {
  repository_name = "${local.project_name}-collector"
}
