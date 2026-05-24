`.filter.jq` is now gitignored (no longer showing). The notification is queued in `.pending-notify/` (gitignored — the workflow's post-run step drains it, since direct `./notify` shell calls are sandbox-blocked). The `.notify-sent-hashes`/`notify` files were pre-existing, not from this run.

## Summary

Executed the **token-movers** skill (var: none → full movers/losers/trending report) for 2026-05-24.

**What I did**
- Fetched CoinGecko markets (250 coins, 1h/24h/7d) + trending (15) — both first-try via `curl -o` (HTTP 200). No WebFetch fallback needed.
- Filtered 250 → 212 (vol ≥ $1M) → 191 in scope (dropped stablecoins + wrapped/staked dupes) via inline jq.
- Ranked top-10 winners/losers, computed pulse over top-100 by mcap, applied signal/risk tags, and deduped against the 5/22–5/23 logs.

**Key finding — sharp risk-on reversal:** 94/100 top coins green, top-50 median **+4.2%**, every major up (BTC +3.3% $77.2k, ETH +4.6%, SOL +5.1%) — a full inversion of yesterday's risk-off. Standouts: **NEAR** clean large-cap breakout (+15% on $1.0B vol); **RAIL** +78% but low-cap/rolling-over (PUMP-RISK). Notably, **yesterday's two top winners (BEAT, BSB) are today's two biggest losers** — textbook post-pump distribution (BSB capitulation).

**Files created/modified**
- `.pending-notify/token-movers-2026-05-24.md` — notification (2849 chars, <4000); workflow drains it post-run.
- `memory/logs/2026-05-24.md` — appended token-movers log entry.
- `.markets.json` / `.trending.json` — refreshed working caches.
- `.gitignore` — added `.filter.jq` (couldn't `rm` the scratch file; sandbox blocks `rm`, so ignored it per the existing `drift_scan.jq` convention).

**Follow-up:** none required — notification delivery is handled by the GitHub Actions post-run step.
