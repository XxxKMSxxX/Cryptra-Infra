locals {
  tasks = flatten([
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
