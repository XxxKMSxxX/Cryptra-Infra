include "root" {
  path           = find_in_parent_folders()
  expose         = true
  merge_strategy = "deep"
}

terraform {
  source = "../../../../modules/ecs"
}

locals {
  vpc_id        = "vpc-0fbffb61f92c041a2"
  instance_type = "t3.micro"
  subnet_ids    = [
    "subnet-0fd0dc95fec72eea9",
    "subnet-05493d8c872b22de6"
  ]
  aws_account_id = get_env("AWS_ACCOUNT_ID")
}

inputs = {
  project_name  = include.root.locals.conf.project_name
  collects      = include.root.locals.conf.collects
  aws_region    = include.root.locals.conf.region
  instance_type = local.instance_type
  vpc_id        = local.vpc_id
  subnet_ids    = local.subnet_ids
  ecr_registry  = "${locals.aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${include.root.locals.conf.project_name}-collector"
}
