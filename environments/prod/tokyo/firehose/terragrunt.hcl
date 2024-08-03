include "root" {
  path           = find_in_parent_folders()
  expose         = true
  merge_strategy = "deep"
}

terraform {
  source = "../../../../modules/firehose"
}

locals {
  aws_account_id = get_env("AWS_ACCOUNT_ID")
}

inputs = {
  project_name   = include.root.locals.conf.project_name
  aws_region     = include.root.locals.conf.region
  aws_account_id = local.aws_account_id
  stream_name    = "${include.root.locals.conf.project_name}-collector"
  tags           = include.root.locals.tags
}