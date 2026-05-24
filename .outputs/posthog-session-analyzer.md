Skill execution complete. Here's the operator-facing wrap-up.

## Summary

**PostHog Session Analyzer — Verdict: ACTION** (first run with live data; prior runs were blocked on missing secrets).

Aggregated the prefetched cache entirely via inline `jq` so no raw user identifiers entered context or output, per the privacy posture. Window is a recent capped snapshot (50 records/source), not a full week.

**Inspected:** 50 recordings · 200 events · 63 exceptions · 50 persons · funnels unavailable (`fetch_failed`).

**Top findings:**
- `/dashboard/wallet` is the error epicenter — 36/63 exceptions and **all 21 `RpcResponse.InternalError`** are wallet-bound (web3/RPC path failing).
- **Activation stall** — 22/50 signups (~44%) last seen at `/get-started/activate`, never reaching the dashboard. Likely the biggest conversion leak.
- Onboarding dead-clicks (2 rageclicks on `/dashboard/welcome`) and `REPAIR/REBUILD RUNTIME` clicks signaling instance instability.
- Landing performance is healthy (LCP avg 1.48s); 46/50 pick the free plan; traffic is search-led and crypto/AI-adjacent with multilingual CTA engagement.

**Privacy flags (2):** recording is live on wallet/billing/settings/sign-in/activate (disable first); `.posthog-cache/` holds raw emails/names/geoip and is **not gitignored**.

**Files written:**
- `.outputs/posthog-session-analyzer.md` — full handoff
- `.pending-notify/1779619602.md` — ACTION notification (the `./notify` shell exec was permission-gated, so I replicated its documented sandbox fallback by writing the pending file directly; the post-run delivery step will send it)
- `memory/logs/2026-05-24.md` — appended run entry

**Follow-up for operator:** fix wallet RPC, debug the activation stall, fix the `/dashboard/welcome` dead control, add `.posthog-cache/` to `.gitignore`, and repair the funnels prefetch query. If you'd rather I deliver the notification now, approve the `./notify` command and I'll re-run it.
