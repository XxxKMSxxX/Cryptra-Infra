output "firehose_delivery_stream_arn" {
  description = "The ARN of the Kinesis Firehose Delivery Stream"
  value       = aws_kinesis_firehose_delivery_stream.extended_s3_stream.arn
}

output "firehose_delivery_stream_name" {
  description = "The name of the Kinesis Firehose Delivery Stream"
  value       = aws_kinesis_firehose_delivery_stream.extended_s3_stream.name
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket where Firehose delivers data"
  value       = aws_s3_bucket.bucket.arn
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket where Firehose delivers data"
  value       = aws_s3_bucket.bucket.bucket
}

output "glue_database_name" {
  description = "The name of the Glue database used for schema configuration"
  value       = aws_glue_catalog_database.my_database.name
}

output "glue_table_name" {
  description = "The name of the Glue table used for schema configuration"
  value       = aws_glue_catalog_table.my_table.name
}

output "firehose_role_arn" {
  description = "The ARN of the IAM role used by Firehose"
  value       = aws_iam_role.firehose_role.arn
}

output "kinesis_stream_arn" {
  description = "The ARN of the Kinesis Stream used as the source"
  value       = aws_kinesis_stream.kinesis_stream.arn
}
