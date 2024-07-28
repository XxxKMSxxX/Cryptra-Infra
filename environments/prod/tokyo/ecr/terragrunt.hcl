include "root" {
  path           = find_in_parent_folders()
  expose         = true
  merge_strategy = "deep"
}

terraform {
  source = "../../../../modules/ecr"
}

inputs = {
  repository_name = "${include.root.locals.conf.project_name}-collector"
  tags            = include.root.locals.conf.tags
}
