include "root" {
  path           = find_in_parent_folders()
  expose         = true
  merge_strategy = "deep"
}

terraform {
  source = "../../../../modules/ecs"
}

locals {
  instance_type = "t3.small"
  aws_account_id = get_env("AWS_ACCOUNT_ID")
}

inputs = {
  project_name  = include.root.locals.conf.project_name
  collects      = include.root.locals.conf.collects
  instance_type = local.instance_type
  ecr_registry  = "${local.aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${include.root.locals.conf.project_name}-collector"
  tags          = include.root.locals.tags
}
