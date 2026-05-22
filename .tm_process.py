#!/usr/bin/env python3
import json

m = json.load(open('.tm_markets.json'))
t = json.load(open('.tm_trending.json'))

print("markets type:", type(m).__name__, "len:", len(m) if isinstance(m, list) else "N/A")
if isinstance(m, dict):
    print("markets dict keys:", list(m.keys())[:10])
print("trending type:", type(t).__name__)
if isinstance(t, dict):
    print("trending keys:", list(t.keys()))
    coins = t.get('coins', [])
    print("trending coins count:", len(coins))
