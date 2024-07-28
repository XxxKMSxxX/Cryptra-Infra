// include "root" {
//   path           = find_in_parent_folders()
//   expose         = true
//   merge_strategy = "deep"
// }

// terraform {
//   source = "../../../../modules/firehose"
// }

// inputs = {
//   project_name = include.root.locals.conf.project_name
//   tags         = include.root.locals.tags
// }