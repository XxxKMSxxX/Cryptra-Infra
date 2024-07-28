data "aws_caller_identity" "current" {}

data "aws_kinesis_stream" "existing_kinesis_stream" {
  name = var.stream_name
}

resource "aws_cloudwatch_log_group" "firehose_log_group" {
  name              = "/firehose/${var.project_name}"
  retention_in_days = 1
  tags              = var.tags
}

resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "${var.project_name}-kinesis-firehose-extended-s3-stream"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = data.aws_kinesis_stream.existing_kinesis_stream.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose_role.arn
    bucket_arn         = aws_s3_bucket.bucket.arn
    buffering_size     = 64
    buffering_interval = 300
    compression_format = "UNCOMPRESSED"

    dynamic_partitioning_configuration {
      enabled = true
    }

    prefix              = "data/exchange=!{partitionKeyFromQuery:exchange}/contract=!{partitionKeyFromQuery:contract}/symbol=!{partitionKeyFromQuery:symbol}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/!{firehose:error-output-type}/"

    data_format_conversion_configuration {
      enabled = true

      input_format_configuration {
        deserializer {
          open_x_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        role_arn      = aws_iam_role.firehose_role.arn
        catalog_id    = data.aws_caller_identity.current.account_id
        database_name = aws_glue_catalog_database.my_database.name
        table_name    = aws_glue_catalog_table.my_table.name
        region        = var.aws_region
        version_id    = "LATEST"
      }
    }

    processing_configuration {
      enabled = true

      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{exchange:.exchange,contract:.contract,symbol:.symbol}"
        }
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_log_group.name
      log_stream_name = "firehose-delivery"
    }
  }

  tags = var.tags
}

resource "aws_glue_catalog_database" "my_database" {
  name = "${var.project_name}-database"
  tags = var.tags
}

resource "aws_glue_catalog_table" "my_table" {
  name          = "${var.project_name}-table"
  database_name = aws_glue_catalog_database.my_database.name

  storage_descriptor {
    columns {
      name = "timestamp"
      type = "string"
    }
    columns {
      name = "open"
      type = "double"
    }
    columns {
      name = "high"
      type = "double"
    }
    columns {
      name = "low"
      type = "double"
    }
    columns {
      name = "close"
      type = "double"
    }
    columns {
      name = "volume"
      type = "double"
    }
    columns {
      name = "buy_volume"
      type = "double"
    }
    columns {
      name = "sell_volume"
      type = "double"
    }
    columns {
      name = "count"
      type = "int"
    }
    columns {
      name = "buy_count"
      type = "int"
    }
    columns {
      name = "sell_count"
      type = "int"
    }
    columns {
      name = "value"
      type = "double"
    }
    columns {
      name = "buy_value"
      type = "double"
    }
    columns {
      name = "sell_value"
      type = "double"
    }

    location      = "s3://${aws_s3_bucket.bucket.bucket}/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "parquet"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }
  }

  tags = var.tags
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.project_name}-collector"
  tags   = var.tags
}

data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "firehose_role" {
  name               = "${var.project_name}-firehose-role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "firehose_policy" {
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.bucket.arn}",
          "${aws_s3_bucket.bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords"
        ],
        Resource = data.aws_kinesis_stream.existing_kinesis_stream.arn
      },
      {
        Effect = "Allow",
        Action = [
          "glue:GetTable",
          "glue:GetTableVersion",
          "glue:GetTableVersions",
          "glue:CreateDatabase",
          "glue:DeleteDatabase",
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:UpdateDatabase"
        ],
        Resource = "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:catalog"
      },
      {
        Effect = "Allow",
        Action = [
          "firehose:CreateDeliveryStream",
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ],
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/firehose/${var.project_name}:*"
      }
    ]
  })
}
