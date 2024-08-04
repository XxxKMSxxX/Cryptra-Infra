locals {
  collects = {
    for collect in flatten([
      for exchange, contracts in var.collects : [
        for contract, symbols in contracts : [
          for symbol in symbols : {
            exchange = exchange,
            contract = contract,
            symbol   = symbol
          }
        ]
      ]
    ]) :
    lower("${collect.exchange}-${collect.contract}-${collect.symbol}") => {
      exchange = collect.exchange,
      contract = collect.contract,
      symbol   = collect.symbol
    }
  }
}
