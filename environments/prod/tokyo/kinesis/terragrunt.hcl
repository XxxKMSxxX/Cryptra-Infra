include "root" {
  path           = find_in_parent_folders()
  expose         = true
  merge_strategy = "deep"
}

terraform {
  source = "../../../../modules/kinesis"
}

inputs = {
  project_name = include.root.locals.conf.project_name
  stream_name  = "${include.root.locals.conf.project_name}-collector"
  tags         = include.root.locals.conf.tags
}
