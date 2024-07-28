# resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
#   name        = "${var.project_name}-kinesis-firehose-extended-s3-stream"
#   destination = "extended_s3"

#   extended_s3_configuration {
#     role_arn   = aws_iam_role.firehose_role.arn
#     bucket_arn = aws_s3_bucket.bucket.arn

#     buffering_size = 64

#     # https://docs.aws.amazon.com/firehose/latest/dev/dynamic-partitioning.html
#     dynamic_partitioning_configuration {
#       enabled = "true"
#     }

#     # Example prefix using partitionKeyFromQuery, applicable to JQ processor
#     prefix              = "data/customer_id=!{partitionKeyFromQuery:customer_id}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
#     error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/!{firehose:error-output-type}/"

#     processing_configuration {
#       enabled = "true"

#       # Multi-record deaggregation processor example
#       processors {
#         type = "RecordDeAggregation"
#         parameters {
#           parameter_name  = "SubRecordType"
#           parameter_value = "JSON"
#         }
#       }

#       # New line delimiter processor example
#       processors {
#         type = "AppendDelimiterToRecord"
#       }

#       # JQ processor example
#       processors {
#         type = "MetadataExtraction"
#         parameters {
#           parameter_name  = "JsonParsingEngine"
#           parameter_value = "JQ-1.6"
#         }
#         parameters {
#           parameter_name  = "MetadataExtractionQuery"
#           parameter_value = "{customer_id:.customer_id}"
#         }
#       }
#     }
#   }
# }

# resource "aws_s3_bucket" "bucket" {
#   bucket = "${var.project_name}-collector"
# }

# resource "aws_s3_bucket_acl" "bucket_acl" {
#   bucket = aws_s3_bucket.bucket.id
#   acl    = "private"
# }

# data "aws_iam_policy_document" "firehose_assume_role" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["firehose.amazonaws.com"]
#     }

#     actions = ["sts:AssumeRole"]
#   }
# }

# resource "aws_iam_role" "firehose_role" {
#   name               = "${var.project_name}-firehose-role"
#   assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
# }
