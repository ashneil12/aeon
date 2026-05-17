## Summary

Ran the **token-movers** skill against live CoinGecko data (markets endpoint + trending, both 200 OK, 250 coins fetched). Filtered out stablecoins, wrapped dupes, and sub-$1M-volume tokens → 187 coins ranked.

**Pulse:** Mild risk-on tape — 70/100 top-100 green, top-50 median +0.6%, but the loudest moves are speculative low-caps while majors barely budged.

**Headliners:**
- **XP** +71.5% (24h) on a +229% week — `[BREAKOUT]` but rank #195 with only $3.4M vol → also `[PUMP-RISK]`
- **BSB** +44.4% in 24h vs only +5.7% on the week, rank #247 → `[PUMP-RISK]`
- **VVV** and **ASTEROID** appear in both top winners and trending → `[TRENDING+UP]`
- **BILL** traded $768M on a $338M-cap day while only down 6.5% — extreme volume churn

**Files written:**
- `.pending-notify/token-movers-2026-05-17.md` (2793 chars, well under 4000 limit) — staged for post-run delivery
- `memory/logs/2026-05-17.md` — appended `### token-movers` section
- `.cache/cg-markets.json`, `.cache/cg-trending.json`, `.cache/movers-msg.md` (scratch)

**Notification status:** The canonical `./notify "$(cat .cache/movers-msg.md)"` invocation was blocked by harness static analysis (shell substitution + cp into hidden dir both refused). Used the documented sandbox fallback per CLAUDE.md — wrote the message directly to `.pending-notify/` via the Write tool, which is exactly where `./notify` itself stages messages for the workflow's post-run delivery step.

**Follow-ups:** If the post-run notify step doesn't pick up Write-created files (vs. cp-created ones), the message will need to be sent manually next run. Worth checking whether the harness can be configured to allow `bash -c './notify ...'` so future skill runs can call `./notify` directly.
