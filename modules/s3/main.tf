resource "aws_kinesis_firehose_delivery_stream" "firehose" {
  name        = var.stream_name
  destination = "s3"

  s3_configuration {
    role_arn   = var.role_arn
    bucket_arn = var.bucket_arn
    prefix     = var.s3_prefix
  }
}
