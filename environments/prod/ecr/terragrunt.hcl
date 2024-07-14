terraform {
  source = "../../../modules/ecr"
}

include {
  path = find_in_parent_folders("environments/prod/common.hcl")
}

inputs = {
  repository_name = "${local.project_name}-collector"
}
