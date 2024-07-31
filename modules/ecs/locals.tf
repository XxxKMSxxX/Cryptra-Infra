locals {
  base_port = 8080
  tasks = flatten([
    for exchange_idx, exchange_name in keys(var.collects) : [
      for contract_idx, contract_type in keys(var.collects[exchange_name]) : [
        for symbol_idx, symbol in enumerate(var.collects[exchange_name][contract_type]) : {
          exchange      = exchange_name,
          contract_type = contract_type,
          symbol        = symbol,
          host_port     = local.base_port + exchange_idx * 10000 + contract_idx * 1000 + symbol_idx
        }
      ]
    ]
  ])
}