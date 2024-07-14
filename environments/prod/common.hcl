generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region = "ap-northeast-1"
}
EOF
}

generate "version" {
  path      = "version.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_version = ">= 0.14"
}
EOF
}

locals {
  project_name = "Cryptra"

  collects = {
    bybit = {
      contracts = {
        spot      = ["BTCUSDT", "ETHUSDT", "SOLUSDT"],
        linear    = ["BTCUSDT", "ETHUSDT", "SOLUSDT"],
        inverse   = ["BTCUSD", "ETHUSD", "SOLUSD"],
      }
    },
    binance = {
      contracts = {
        spot           = ["btcusdt", "btcjpy", "ethusdt", "ethjpy", "solusdt", "soljpy"],
        usdt_perpetual = ["btcusdt", "ethusdt", "solusdt"],
      }
    },
    bitflyer = {
      contracts = {
        spot = ["BTC_JPY", "ETH_JPY"],
        fx   = ["FX_BTC_JPY"],
      }
    }
  }
}
