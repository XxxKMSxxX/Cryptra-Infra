locals {
  base_port = 8080
  exchange_names = keys(var.collects)
  tasks = flatten([
    for exchange_idx in range(length(local.exchange_names)) : [
      for contract_idx in range(length(keys(var.collects[local.exchange_names[exchange_idx]]))) : [
        for symbol_idx in range(length(var.collects[local.exchange_names[exchange_idx]][keys(var.collects[local.exchange_names[exchange_idx]])[contract_idx]])) : {
          exchange      = local.exchange_names[exchange_idx],
          contract_type = keys(var.collects[local.exchange_names[exchange_idx]])[contract_idx],
          symbol        = var.collects[local.exchange_names[exchange_idx]][keys(var.collects[local.exchange_names[exchange_idx]])[contract_idx]][symbol_idx],
          host_port     = local.base_port + exchange_idx * 10000 + contract_idx * 1000 + symbol_idx
        }
      ]
    ]
  ])
}