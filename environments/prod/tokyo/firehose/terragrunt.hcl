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
//   stream_name  = "${include.root.locals.conf.project_name}-collector"
//   role_arn     = "arn:aws:iam::123456789012:role/FirehoseDeliveryRole"
//   bucket_arn   = "arn:aws:s3:::${include.root.locals.conf.project_name}-collector"
//   s3_prefix    = "firehose"
//   environment  = "prod"
//   tags         = include.root.locals.tags
// }