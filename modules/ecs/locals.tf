locals {
  raw_collects = flatten([
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

  collects = {
    for idx, collect in local.raw_collects :
    idx => {
      exchange      = collect.exchange,
      contract_type = collect.contract_type,
      symbol        = collect.symbol,
      host_port     = var.host_port_start + idx
    }
  }
}
