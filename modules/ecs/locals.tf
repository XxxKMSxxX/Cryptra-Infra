locals {
  raw_collects = flatten([
    for exchange, contracts in var.collects : [
      for contract, symbols in contracts : [
        for symbol in symbols : {
          exchange = exchange,
          contract = contract,
          symbol   = symbol
        }
      ]
    ]
  ])

  collects = {
    for collect in local.raw_collects :
    lower("${collect.exchange}-${collect.contract}-${collect.symbol}") => {
      exchange = collect.exchange,
      contract = collect.contract,
      symbol   = collect.symbol
    }
  }
}
