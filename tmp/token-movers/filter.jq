def stable_ids:
  ["tether","usd-coin","dai","first-digital-usd","ethena-usde","usde","true-usd","tusd","usdd","paypal-usd","pyusd","fdusd","paxg","frax","binance-usd","busd","usdp","gusd","lusd","ethena-staked-usde","susde","usds","usd1","global-dollar","fei-usd","magic-internet-money","mim","ondo-us-dollar-yield","usdy","level-usd","lvlusd","openeden-tbill","ousg","tether-eurt","stasis-eurs","tether-gold","pax-gold","usdt0","usdtb","world-liberty-financial-usd","usual-usd","makerdao-usds","skyusd","resolv-usr","usr"];

def wrapped_dupes:
  ["wrapped-bitcoin","wrapped-eeth","wrapped-steth","wrapped-beacon-eth","weth","binance-bitcoin","tbtc","wrapped-solana","msol","jupiter-staked-sol","jito-staked-sol","binance-staked-sol","marinade-staked-sol","rocket-pool-eth","lido-staked-ether","staked-ether","coinbase-wrapped-staked-eth","bitcoin-avalanche-bridged-btc-b","renbtc","wrapped-avax","ankreth","frax-ether","staked-frax-ether","binance-peg-cardano","binance-peg-dogecoin","binance-peg-bnb","wrapped-tron","wrapped-near","lombard-staked-btc","kelp-dao-restaked-eth","renzo-restaked-eth","ether-fi-staked-eth","solv-protocol-solvbtc","bridged-wrapped-steth-scroll","wbtc","wsteth","ethena-staked-usdtb","binance-staked-eth","ankr-staked-eth"];

def exclude: stable_ids + wrapped_dupes;

[ .[]
  | select( (.id // "") as $id | (exclude | index($id)) | not )
  | select( ((.symbol // "") | ascii_upcase) as $s | ($s | startswith("USD")) or ($s | startswith("EUR")) or ($s | startswith("GBP")) | not )
  | select( ((.name // "") | ascii_downcase | contains("stablecoin")) | not )
  | select( (.total_volume // 0) >= 1000000 )
  | select( .price_change_percentage_24h != null )
]
