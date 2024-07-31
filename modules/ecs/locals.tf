variable "base_port" {
  type    = number
  default = 8080
}

locals {
  raw_tasks = flatten([
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

  tasks = [
    for idx in range(length(local.raw_tasks)) : {
      exchange      = local.raw_tasks[idx].exchange,
      contract_type = local.raw_tasks[idx].contract_type,
      symbol        = local.raw_tasks[idx].symbol,
      host_port     = var.base_port + idx
    }
  ]

  task_map = {
    for idx, task in local.tasks : 
    "${task.exchange}-${task.contract_type}-${task.symbol}" => idx
  }
}