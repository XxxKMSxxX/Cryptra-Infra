locals {
  base_port = 8080
  tasks = flatten([
    for exchange_name, exchange in var.collects : [
      for contract_type, symbols in exchange : [
        for i, symbol in symbols : {
          exchange      = exchange_name,
          contract_type = contract_type,
          symbol        = symbol,
          host_port     = local.base_port + i
        }
      ]
    ]
  ])
}