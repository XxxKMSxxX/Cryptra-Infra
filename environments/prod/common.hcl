

locals {
  project_name = "cryptra"

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
