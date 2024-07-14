locals {
  streams = flatten([
    for exchange_name, exchange in var.collects : [
      for contract_type, symbols in exchange : [
        for symbol in symbols : {
          exchange      = exchange_name,
          contract_type = contract_type,
          symbol        = symbol
        }
      ]
    ]
  ])
}

resource "aws_kinesis_stream" "kinesis_streams" {
  for_each = { for idx, stream in local.streams : "${stream.exchange}-${stream.contract_type}-${stream.symbol}" => stream }

  name             = "${var.project_name}-${each.value.exchange}-${each.value.contract_type}-${each.value.symbol}"
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
    Name = "${var.project_name}-${each.value.exchange}-${each.value.contract_type}-${each.value.symbol}"
  }
}