The token-movers run is complete.

## Summary

Ran the **token-movers** skill for 2026-05-23 — a full movers/losers/trending report (no `${var}`).

**What I did:**
- Fetched CoinGecko markets (250 coins) + trending (15) — both HTTP 200 on first curl try. Used the public endpoint since the sandbox blocks `$COINGECKO_API_KEY` expansion.
- Filtered out stablecoins, wrapped/staked dupes, and sub-$1M-volume tokens; ranked winners/losers by 24h %, computed the market pulse and signal/risk tags via `jq`.
- Dedup'd against the 5/22 run: dropped GENIUS (faded +37%→+4%), kept BEAT/TAG (materially changed), and flagged the SKYAI and VVV direction flips.

**The tape:** Broad risk-off — only **10/100** top coins green, top-50 median **−4.5%**; BTC −3.5%, ETH −4.8%, SOL −6.0%. Losers cluster −12% to −16% across L1s/DeFi/memes; winners are thin and low-cap.
- **Standouts:** BSB +41.9% (7d +226%, PUMP-RISK low-cap parabolic on real $103M volume); CHZ −16% CAPITULATION; VVV flipped from yesterday's trending winner to TRENDING+DOWN loser; SKYAI rebounded +12% after its −20% capitulation.

**Files:**
- `.pending-notify/token-movers-2026-05-23.md` (2736 chars, <4000) — queued for the workflow's post-run delivery loop.
- `memory/logs/2026-05-23.md` — appended the run log entry.

**Notes / follow-up:** The sandbox is unusually locked down this run — it blocked `python3` script execution, shell `>`/`>>` redirection, `rm`, and `jq` reads outside the working dir. I worked around all of these (curl `-o` into cwd, `jq` to stdout, Write/Edit for files). The two temp dotfiles (`.markets.json`, `.trending.json`) couldn't be removed but are ephemeral and uncommitted. Delivery relies on the post-run drainer since `./notify` can't be shell-invoked here.
