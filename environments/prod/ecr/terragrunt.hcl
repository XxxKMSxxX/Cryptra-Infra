include {
  path = find_in_parent_folders("common.hcl")
}

terraform {
  source = "../../../modules/ecr"
}

inputs = {
  repository_name = "${local.project_name}-collector"
}
