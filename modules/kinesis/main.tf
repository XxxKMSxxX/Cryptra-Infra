resource "aws_kinesis_stream" "kinesis_streams" {
  for_each = { for stream in local.streams : lower("${stream.exchange}-${stream.contract_type}-${stream.symbol}") => stream }

  name             = lower("${var.project_name}-${each.value.exchange}-${each.value.contract_type}-${each.value.symbol}")
  shard_count      = 1
  retention_period = 24

  shard_level_metrics = [
    "IncomingBytes",
    "IncomingRecords",
    "OutgoingBytes",
    "OutgoingRecords",
    "WriteProvisionedThroughputExceeded",
    "ReadProvisionedThroughputExceeded",
    "IteratorAgeMilliseconds",
  ]

  tags = {
    Name = lower("${var.project_name}-${each.value.exchange}-${each.value.contract_type}-${each.value.symbol}")
  }
}
