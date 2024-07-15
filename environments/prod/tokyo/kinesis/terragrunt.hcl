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
  collects     = include.root.locals.conf.collects
}
