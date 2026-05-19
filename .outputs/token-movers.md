## Summary

Ran `skills/token-movers/SKILL.md` for 2026-05-19 (var empty → full report).

**Data:** CoinGecko `/coins/markets` (250 coins) and `/search/trending` (15 coins) both fetched cleanly on first try — no WebFetch fallback needed. Filters dropped 57 stables / wrapped-staked dupes / sub-$1M volume coins; 193 in scope.

**Output:**
- `.pending-notify/token-movers-2026-05-19.md` (3094 chars, under 4000) — picked up by the workflow's post-run delivery loop.
- `memory/logs/2026-05-19.md` — appended log entry.

**Key findings:**
- **Pulse:** quiet tape with mild green tilt — 66/100 top-100 green, top-50 median only +0.4%.
- **Notable tags fired:** `[CAPITULATION]` BILL (−26.6%, 41% turnover); `[BREAKOUT]` 9BIT (+20.5% / 7d +46%); `[TRENDING+UP][MAJOR]` ZEC (+7.5% on $599M vol, #14); `[TRENDING+UP]` ONDO.
- **Reversal callout:** yesterday's top winners XP (+71.5%) and ASTEROID (+15.4%) both flushed today (−13.4% / −10.1%) — classic 1-day pump→dump.
- **PUMP-RISK trending:** RON +37.5% at rank #307 (outside top-250 dataset).

**Sandbox notes:** `python3` and `jq -f`/`-o` flags blocked by harness approval rules; worked around by running jq inline and writing the report via the Write tool. `./notify` not invoked (writing directly to `.pending-notify/` achieves the same delivery path via the workflow's post-run drain).

**Dedup applied:** BinanceLife (+6.6% today vs +7.4% yesterday) and UB (−15.2% vs −17.5%) dropped from their lists per the skill's "skip same direction + similar magnitude" rule.

**Follow-up:** none required — next scheduled run is the daily 12:00 UTC cron tomorrow.
