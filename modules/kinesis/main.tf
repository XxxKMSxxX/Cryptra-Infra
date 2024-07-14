resource "aws_kinesis_stream" "kinesis_streams" {
  for_each = {
    for exchange_name, exchange in var.collects : exchange_name => flatten([
      for contract_type, symbols in exchange.contracts : [
        for symbol in symbols : {
          exchange       = exchange_name
          contract_type  = contract_type
          symbol         = symbol
        }
      ]
    ])
  }

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
}
