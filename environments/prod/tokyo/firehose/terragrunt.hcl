include "root" {
  path           = find_in_parent_folders()
  expose         = true
  merge_strategy = "deep"
}

terraform {
  source = "../../../../modules/firehose"
}

inputs = {
  project_name = include.root.locals.conf.project_name
  aws_region   = include.root.locals.conf.region
  stream_name  = "${include.root.locals.conf.project_name}-collector"
  tags         = include.root.locals.tags
}