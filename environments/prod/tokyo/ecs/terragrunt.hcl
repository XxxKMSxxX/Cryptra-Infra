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
}

inputs = {
  project_name  = include.root.locals.conf.project_name
  region        = include.root.locals.conf.region
  vpc_id        = local.vpc_id
  instance_type = local.instance_type
  subnet_ids    = local.subnet_ids
}
