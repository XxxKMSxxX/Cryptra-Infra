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
    for collect in local.raw_collects : 
    "${collect.exchange}-${collect.contract_type}-${collect.symbol}" => {
      exchange      = collect.exchange,
      contract_type = collect.contract_type,
      symbol        = collect.symbol
    }
  }
}