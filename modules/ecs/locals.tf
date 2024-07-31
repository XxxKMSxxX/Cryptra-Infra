locals {
  base_port = 8080
  exchange_names = keys(var.collects)
  tasks = flatten([
    for exchange_idx in range(length(local.exchange_names)) : [
      for contract_type in keys(var.collects[local.exchange_names[exchange_idx]]) : [
        for symbol_idx in range(length(var.collects[local.exchange_names[exchange_idx]][contract_type])) : {
          exchange      = local.exchange_names[exchange_idx],
          contract_type = contract_type,
          symbol        = var.collects[local.exchange_names[exchange_idx]][contract_type][symbol_idx],
          host_port     = local.base_port + exchange_idx * 10000 + find(keys(var.collects[local.exchange_names[exchange_idx]]), contract_type) * 1000 + symbol_idx
        }
      ]
    ]
  ])
}