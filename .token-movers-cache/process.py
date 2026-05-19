#!/usr/bin/env python3
"""Process CoinGecko data per token-movers SKILL.md."""
import json
from pathlib import Path

CACHE = Path(__file__).parent
markets = json.loads((CACHE / "markets.json").read_text())
trending_raw = json.loads((CACHE / "trending.json").read_text())

# ---- Filter helpers ----
STABLE_IDS = {
    "tether", "usd-coin", "dai", "first-digital-usd", "ethena-usde", "usde",
    "true-usd", "tusd", "usdd", "paypal-usd", "pyusd", "fdusd", "paxg",
    "frax", "frax-share", "usdp", "gusd", "lusd", "binance-usd", "busd",
    "tether-eurt", "stasis-eurs", "tether-gold", "pax-gold",
    "ethena-staked-usde", "susde", "usds", "usd1", "global-dollar",
    "fei-usd", "magic-internet-money", "mim", "neutron-usdc-usdtero",
    "bridged-usd-coin-base", "ondo-us-dollar-yield", "usdy",
    "level-usd", "lvlusd", "openeden-tbill", "ousg",
}
STABLE_SYMBOL_PREFIXES = ("USD", "EUR", "GBP", "EURO")
STABLE_NAME_HINTS = ("stablecoin", "stable coin", "us dollar")

WRAPPED_IDS_KEEP = {
    # Of these duplicates, we keep only one canonical entry of the underlying asset.
    # We keep the unwrapped/canonical one; drop the wrapped if a non-wrapped twin exists.
}
WRAPPED_DUPE_IDS = {
    "wrapped-bitcoin", "wrapped-eeth", "wrapped-steth", "wrapped-beacon-eth",
    "weth", "binance-bitcoin", "tbtc", "wrapped-solana", "msol",
    "jupiter-staked-sol", "jito-staked-sol", "binance-staked-sol",
    "marinade-staked-sol", "rocket-pool-eth", "lido-staked-ether",
    "staked-ether", "coinbase-wrapped-staked-eth", "bitcoin-bep2",
    "bitcoin-avalanche-bridged-btc-b", "renbtc", "huobi-btc",
    "wrapped-avax", "ankreth", "frax-ether", "staked-frax-ether",
    "binance-peg-cardano", "binance-peg-dogecoin", "binance-peg-bnb",
    "wrapped-tron", "wrapped-near", "polygon-ecosystem-token",
}

def is_stable(c):
    cid = (c.get("id") or "").lower()
    sym = (c.get("symbol") or "").upper()
    name = (c.get("name") or "").lower()
    if cid in STABLE_IDS:
        return True
    if any(sym.startswith(p) for p in STABLE_SYMBOL_PREFIXES):
        return True
    if any(h in name for h in STABLE_NAME_HINTS):
        return True
    return False

def is_wrapped_dupe(c):
    return (c.get("id") or "").lower() in WRAPPED_DUPE_IDS

VOL_FLOOR = 1_000_000

filtered = []
for c in markets:
    if is_stable(c):
        continue
    if is_wrapped_dupe(c):
        continue
    vol = c.get("total_volume") or 0
    if vol < VOL_FLOOR:
        continue
    # Drop coins missing 24h change number
    if c.get("price_change_percentage_24h") is None:
        continue
    filtered.append(c)

# ---- Sort + pick lists ----
by_24h_desc = sorted(filtered, key=lambda x: x["price_change_percentage_24h"], reverse=True)
by_24h_asc = sorted(filtered, key=lambda x: x["price_change_percentage_24h"])

winners = by_24h_desc[:10]
losers = by_24h_asc[:10]

# Build a trending set keyed by id for cross-tag
trending_items_raw = trending_raw.get("coins", [])[:7]
trending = []
for t in trending_items_raw:
    item = t.get("item", {})
    tid = (item.get("id") or "").lower()
    data = item.get("data", {}) or {}
    # Price often in data.price (number) and data.price_change_percentage_24h.usd
    price = data.get("price")
    pct24 = None
    pcp = data.get("price_change_percentage_24h") or {}
    if isinstance(pcp, dict):
        pct24 = pcp.get("usd")
    trending.append({
        "id": tid,
        "name": item.get("name"),
        "symbol": (item.get("symbol") or "").upper(),
        "rank": item.get("market_cap_rank"),
        "price": price,
        "pct24": pct24,
    })

trending_ids = {t["id"] for t in trending}

# ---- Tag computation ----
def tags_for(c):
    tags = []
    cid = c["id"].lower()
    sym = c["symbol"].upper()
    p24 = c.get("price_change_percentage_24h") or 0
    p7d = c.get("price_change_percentage_7d_in_currency") or 0
    rank = c.get("market_cap_rank") or 9999
    mcap = c.get("market_cap") or 0
    vol = c.get("total_volume") or 0

    in_trending = cid in trending_ids

    # TRENDING+UP / DOWN
    if in_trending and p24 > 0 and c in winners:
        tags.append("TRENDING+UP")
    elif in_trending and p24 < 0 and c in losers:
        tags.append("TRENDING+DOWN")

    # BREAKOUT
    if p24 > 15 and p7d > 25:
        tags.append("BREAKOUT")
    # FADE
    if p24 > 20 and p7d < 0:
        tags.append("FADE")
    # CAPITULATION (proxy: vol/mcap > 0.25)
    if p24 < -10 and mcap > 0 and (vol / mcap) > 0.25:
        tags.append("CAPITULATION")
    # PUMP-RISK
    if rank > 150 and p24 > 30:
        tags.append("PUMP-RISK")
    # MICROCAP
    if mcap and mcap < 50_000_000:
        tags.append("MICROCAP")
    # MAJOR
    if rank and rank <= 20:
        tags.append("MAJOR")

    # Cap at 2 tags, priority order
    priority = ["TRENDING+UP", "TRENDING+DOWN", "PUMP-RISK", "BREAKOUT",
                "CAPITULATION", "FADE", "MAJOR", "MICROCAP"]
    tags_sorted = sorted(tags, key=lambda t: priority.index(t) if t in priority else 99)
    return tags_sorted[:2]

# ---- Market pulse ----
top100 = [c for c in filtered[:100]]
positive_count = sum(1 for c in top100 if (c.get("price_change_percentage_24h") or 0) > 0)
top50_changes = sorted([c.get("price_change_percentage_24h") or 0 for c in filtered[:50]])
median_top50 = top50_changes[len(top50_changes)//2] if top50_changes else 0

# ---- Formatting helpers ----
def fmt_price(p):
    if p is None:
        return "$?"
    if isinstance(p, str):
        try:
            p = float(p.replace(",", "").replace("$", ""))
        except Exception:
            return p
    if p < 0.0001:
        return f"${p:.8f}".rstrip("0").rstrip(".")
    if p < 0.01:
        return f"${p:.6f}"
    if p < 1:
        return f"${p:.4f}"
    if p < 100:
        return f"${p:.3g}"
    if p < 10000:
        return f"${p:,.2f}"
    return f"${p:,.0f}"

def fmt_pct(x):
    if x is None:
        return "n/a"
    sign = "+" if x > 0 else ""
    return f"{sign}{x:.1f}%"

def fmt_money(x):
    if x is None or x == 0:
        return "n/a"
    if x >= 1e12:
        return f"${x/1e12:.2f}T"
    if x >= 1e9:
        return f"${x/1e9:.2f}B"
    if x >= 1e6:
        return f"${x/1e6:.1f}M"
    if x >= 1e3:
        return f"${x/1e3:.1f}K"
    return f"${x:.0f}"

# ---- Pulse sentence ----
# Compute composition: which sectors lead. Use a heuristic on names/symbols.
sectors_winner_share = {}
for c in winners:
    nm = (c.get("name") or "").lower()
    sym = c.get("symbol", "").upper()
    # very rough buckets
    if any(k in nm for k in ("doge", "shib", "pepe", "bonk", "wif", "floki", "meme")):
        sectors_winner_share["meme"] = sectors_winner_share.get("meme", 0) + 1
    elif any(k in nm for k in ("ai", "render", "fet", "tao", "bittensor", "ocean")):
        sectors_winner_share["AI"] = sectors_winner_share.get("AI", 0) + 1
    elif sym in {"BTC", "ETH", "SOL", "BNB", "ADA", "XRP"}:
        sectors_winner_share["major"] = sectors_winner_share.get("major", 0) + 1

if positive_count >= 65:
    if median_top50 > 1:
        pulse = f"Broad risk-on — {positive_count}/100 top coins green, top-50 median {fmt_pct(median_top50)}; bid is across the board."
    else:
        pulse = f"Mostly green but shallow — {positive_count}/100 top coins green, top-50 median only {fmt_pct(median_top50)}."
elif positive_count <= 35:
    pulse = f"Risk-off — {100-positive_count}/100 top coins red, top-50 median {fmt_pct(median_top50)}; losers dominate."
else:
    # Mixed
    pulse = f"Mixed tape — {positive_count}/100 top coins green, top-50 median {fmt_pct(median_top50)}; rotation rather than direction."

# ---- Render report ----
def render_line(idx, c, with_7d=True):
    sym = (c.get("symbol") or "?").upper()
    name = c.get("name") or "?"
    price = fmt_price(c.get("current_price"))
    p24 = fmt_pct(c.get("price_change_percentage_24h"))
    p7d = fmt_pct(c.get("price_change_percentage_7d_in_currency"))
    p1h = fmt_pct(c.get("price_change_percentage_1h_in_currency"))
    vol = fmt_money(c.get("total_volume"))
    rank = c.get("market_cap_rank") or "?"
    t = tags_for(c)
    tagstr = (" [" + "][".join(t) + "]") if t else ""
    return f"{idx}. {sym} ({name}) — {price}  {p24} / 7d {p7d} / 1h {p1h}  •  {vol} / #{rank}{tagstr}"

today = "2026-05-19"
lines = []
lines.append(f"*Token Movers — {today}*")
lines.append("")
lines.append(f"_{pulse}_")
lines.append("")
lines.append("*Top Winners (24h)*")
for i, c in enumerate(winners, 1):
    lines.append(render_line(i, c))
lines.append("")
lines.append("*Top Losers (24h)*")
for i, c in enumerate(losers, 1):
    lines.append(render_line(i, c))
lines.append("")
lines.append("*Trending*")
for i, t in enumerate(trending, 1):
    sym = t["symbol"] or "?"
    name = t["name"] or "?"
    rank = t["rank"] or "?"
    price = fmt_price(t["price"])
    pct = fmt_pct(t["pct24"])
    # Tag if appears in winners/losers
    tag_bits = []
    in_win = any((w.get("id") or "").lower() == t["id"] for w in winners)
    in_los = any((l.get("id") or "").lower() == t["id"] for l in losers)
    if in_win:
        tag_bits.append("TRENDING+UP")
    if in_los:
        tag_bits.append("TRENDING+DOWN")
    tagstr = (" [" + "][".join(tag_bits) + "]") if tag_bits else ""
    lines.append(f"{i}. {name} ({sym}) — #{rank}, {price}, 24h {pct}{tagstr}")

# Notable
notables = []
all_items = []
for c in winners + losers:
    t = tags_for(c)
    sym = (c.get("symbol") or "?").upper()
    p24 = c.get("price_change_percentage_24h") or 0
    p7d = c.get("price_change_percentage_7d_in_currency") or 0
    rank = c.get("market_cap_rank") or "?"
    vol = c.get("total_volume") or 0
    mcap = c.get("market_cap") or 0
    if "TRENDING+UP" in t:
        notables.append(f"• {sym}: trending + up {fmt_pct(p24)} on {fmt_money(vol)} volume — strong signal")
    elif "TRENDING+DOWN" in t:
        notables.append(f"• {sym}: trending + down {fmt_pct(p24)} on {fmt_money(vol)} volume — capitulation signal")
    elif "BREAKOUT" in t:
        notables.append(f"• {sym}: 24h {fmt_pct(p24)} / 7d {fmt_pct(p7d)} — sustained breakout (#{rank})")
    elif "CAPITULATION" in t:
        notables.append(f"• {sym}: 24h {fmt_pct(p24)} on {fmt_money(vol)} vol vs {fmt_money(mcap)} mcap — capitulation flush")
    elif "PUMP-RISK" in t:
        notables.append(f"• {sym}: #{rank} up {fmt_pct(p24)} — PUMP-RISK, low cap-tier")

# Dedup notables, max 4
seen = set()
deduped_notables = []
for n in notables:
    if n in seen:
        continue
    seen.add(n)
    deduped_notables.append(n)
notables = deduped_notables[:4]

if notables:
    lines.append("")
    lines.append("*Notable*")
    for n in notables:
        lines.append(n)

body = "\n".join(lines)

# Write to a file for inspection
out = CACHE / "report.md"
out.write_text(body)
print(f"BYTES:{len(body)}")
print(body)

# Also print structured summary for the log
print("---LOGSUMMARY---")
print("PULSE:", pulse)
print("WINNERS:", ", ".join(f"{(c.get('symbol') or '').upper()} ({fmt_pct(c.get('price_change_percentage_24h'))})" for c in winners))
print("LOSERS:", ", ".join(f"{(c.get('symbol') or '').upper()} ({fmt_pct(c.get('price_change_percentage_24h'))})" for c in losers))
print("TRENDING:", ", ".join(t["symbol"] for t in trending))
print("NOTABLES:", " | ".join(notables) if notables else "none")
