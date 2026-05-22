The token-movers skill ran successfully. The notification is queued for delivery and the log entry is recorded.

## Summary

Ran the **token-movers** skill (var empty → full movers/losers/trending report). This also clears the multi-day staleness breach that heartbeats had been flagging since 5/20 — the last real run was 2026-05-19.

**Data:** CoinGecko markets (250 coins) + trending (15 coins) both fetched first-try via curl; no WebFetch fallback needed. The `COINGECKO_API_KEY` env-var header was blocked by the sandbox's expansion guard, so I used the public endpoint (worked fine).

**Pipeline:** Filtered out 48 of 250 (stablecoins, wrapped/staked dupes, sub-$1M volume) → 202 coins in scope. Computed multi-timeframe tags and a calibrated pulse.

**Result — broad green tilt** (77/100 top coins green, top-50 median +1.3%; BTC flat):
- **Winners:** BEAT +45.9%, GENIUS +36.9%, GRASS +35.9%, NEAR +28.4%, FET +15.7% (+5 more)
- **Losers:** shallow tape — NEX −25.8%, SKYAI −20.1%, H −10.7%, rest single-digit
- **Tags fired:** [PUMP-RISK] on three low-cap (#160–190) +36–46% spikes (BEAT/GENIUS/GRASS), [BREAKOUT] on NEAR (cleanest large-cap move, $1.1B vol, 7d +44%), [CAPITULATION] on SKYAI & H, [TRENDING+DOWN] on NEX.

**Files:**
- `.pending-notify/token-movers-2026-05-22.md` — notification (2593 bytes, under 4000); workflow's post-run loop drains it to channels. Direct `./notify` was blocked by the sandbox's command-substitution analyzer, so I used the established pending-notify pattern.
- `memory/logs/2026-05-22.md` — appended `### token-movers` log entry.

**Follow-up:** none required. (Note: `.tm_*` scratch files couldn't be removed — sandbox blocks `rm` — but they're untracked dotfiles and won't be committed.)
