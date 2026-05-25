The token-movers run is complete. Notification staged for delivery and the log is written.

## Summary

Ran **token-movers** (no var → full movers/losers/trending) for 2026-05-25.

**Data:** CoinGecko markets (250 coins) + trending (15) both fetched first-try via curl (HTTP 200); no WebFetch fallback needed. Filtered 250 → 193 in scope (dropped stablecoins, sub-$1M-volume, wrapped/staked dupes).

**Market pulse:** _Quiet at the top_ — majors flat (BTC +0.3% $77.3k, ETH −0.2%, SOL −0.4%); top-50 median +0.18%, 60/100 green. A stark reversal of yesterday's sharp risk-on (94/100 green, BTC +3.3%) — today all the action is mid-cap alt rotation while last week's parabolic low-caps distribute.

**Key signals:**
- **DEXE** +20.4% [BREAKOUT] — cleanest fresh mover (#81, 7d +26%)
- **BSB** −24.5% [CAPITULATION] — completes a 3-day pump→dump arc (was 5/23's #1 winner at +42%)
- **GENIUS** −17.1% [CAPITULATION] — round-trips its 5/24 breakout
- **RAIL** −4.5% (1h −5.2%) — yesterday's +78% parabola cooling off exactly as flagged; 7d still +196%
- **XAN/Anoma** trending #687 +35% [PUMP-RISK] microcap new-listing

**Files:**
- `.pending-notify/token-movers-2026-05-25.md` (2411 chars, <4000) — neutral tone (soul empty). Direct `./notify` blocked by sandbox `$(cat)` substitution; the workflow's post-run step (aeon.yml:751-808) drains `.pending-notify/` to all configured channels.
- `memory/logs/2026-05-25.md` — appended run entry with full dedup notes vs 5/23 & 5/24.

**Follow-up:** none — delivery happens automatically in the post-run drain step.
