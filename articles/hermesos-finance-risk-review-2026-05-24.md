# HermesOS Finance & Risk Review — 2026-05-24

*Anselm weekly finance/risk loop · window: 2026-05-17 → 2026-05-24 (7d) · gateway: direct (Anthropic)*
*Note: off-schedule manual run (Sunday). Regular slot is Mon 07:30 UTC.*

> **Verdict: ACTION.** Infra is healthy with comfortable RAM headroom, but two finance levers need owners this cycle: (1) 100% of model spend is on Opus — the every-4h infra-monitoring loop (proxmox-capacity + fleet-sweep) is mechanical and is driving a ~$875/mo run-rate that is largely downgradeable; (2) revenue is unmeasurable — no Stripe/Bankr telemetry is wired, so margin cannot be computed, and `cost-report` has never dispatched (missed 5/18, due 5/25).

## 1. Verdict

**ACTION** — not a fire (no capacity or solvency risk), but there are concrete, assignable moves with real dollar impact. Worst-of dimension is **compute spend trajectory + revenue blind spot**, not infra.

| Dimension | Status |
|-----------|--------|
| Infra unit economics | OK — RAM headroom good, fresh capacity just added |
| Compute spend | ACTION — 100% Opus, ~$875/mo run-rate, downgradeable |
| Revenue signals | ACTION (blocked) — no Stripe/Bankr keys → margin uncomputable |
| Regulatory/comms | OK — drafts-only posture holds; guardrail note below |

## 2. Infra unit economics (AX41 RAM binding · host density)

Fleet = **11 active hosts** (pve1–9, pve11–12; pve10 is canary/control-plane), **319 running VMs**, all `hermes-`-named (0 non-hermes). Hardware is Hetzner **AX41** class (6c/12t Ryzen, 64 GB DDR4 — confirmed by the load5/vCPU÷12 math the capacity skill uses).

- **Binding resource is RAM, not disk or CPU.** Per-tenant density is gated by the 64 GB ceiling (proxmox-capacity WATCHes mem at 80%). Current fleet-max memory is **pve4 = 57.2%** — i.e. ~37 GB of 64 GB on the busiest box, leaving ~9–10 more instances of headroom per mature host before the 80% line. **RAM is not near-binding.**
- **Host density:** mature hosts run ~36–43 running VMs each; **pve5 is densest** (48 VMs / 43 running). New nodes **pve11/pve12 are nearly empty** (1–3 VMs, disk 1–2%, mem 3–9%) — fresh capacity added this week (token-coverage commit), so the fleet just bought runway.
- **Near-capacity signals:** only one — **pve5 local-lvm thin-pool**, a slow disk creep that touched the 70% WATCH line on 5-23 then eased back to 67.3%. It is **disk, not RAM**, and is being actively managed by proxmox-capacity (transition alerts fired and recovered). Watch it, but it is not a margin event yet.
- **Unit economics (directional):** at ~€39/mo per AX41 and ~36–43 instances on a mature host, **infra cost ≈ €1/instance/mo** — RAM-bound, with room to densify the mature hosts ~25% more before the next box is required. New nodes pve11/12 mean the next capacity buy is deferred.

## 3. Compute spend (model risk)

`cost-report` is the authoritative breakdown and **it has never dispatched** (no cron-state entry; missed the 5/18 weekly slot; next due Mon 5/25 07:00 UTC). The figures below are computed directly from `memory/token-usage.csv` (57 runs in-window) at **direct Anthropic Opus rates** and are **directional**.

- **7-day model spend ≈ $204** → **~$875/mo run-rate** (daily avg ~$29).
- Composition: cache-read **~$90** (59.9 M tok) · output **~$60** (804 K tok) · cache-write **~$54** (2.86 M tok) · input **~$0.24** (cache is doing its job — input is negligible).
- **100% of runs are on `claude-opus-4-7`.** The cost is concentrated in the **high-frequency infra-monitoring loop**: `proxmox-capacity` (every 4h) + `fleet-sweep` (every 4h) together are ~30 runs/week, each re-reading a large host snapshot into cached context. These are **mechanical** skills — parse snapshot, compare against fixed thresholds, emit a digest — and are strong candidates for a Sonnet downgrade (Opin→Sonnet cuts output 5× and cache-read 5× on the direct table).
- **Venice / media spend:** no Venice/Replicate/image keys or prefetch scripts configured → **$0 / not applicable** this week. No media-generation cost risk.

**Estimated lever:** moving proxmox-capacity + fleet-sweep + heartbeat to Sonnet would cut roughly **40–60% of model spend (~$350–500/mo)** with negligible quality loss on threshold-checking work. Keep Opus on judgment skills (morning-brief, growth-desk, this review).

## 4. Revenue signals (Stripe / Bankr)

**Blocked — no revenue telemetry configured.**

- **Stripe:** no `STRIPE_*` key, no `scripts/prefetch-stripe.sh` → **no MRR / subscription / churn data**. Placeholder.
- **Bankr:** gateway is `direct`, not `bankr`; no Bankr key or prefetch → **no gateway-margin or Bankr-economics data**. Bankr remains business-model context only (per skill rules), not a live input.
- **Consequence:** with infra cost known (~€430/mo for ~11 AX41) and model cost known (~$875/mo) but **revenue unknown**, **gross margin cannot be computed.** This is the single biggest gap in the finance loop — the cost side is well-instrumented; the revenue side is dark.

## 5. Regulatory / comms risk

**Low, posture intact.**

- No financial-inducement language detected in active output. `hermesos-growth-desk` is **drafts-only — no posting without Ash approval** (confirmed in aeon.yml). `token-movers` outputs market data, not price promotion.
- **Separation holds:** platform utility (HermesOS hosting) and any token activity remain distinct; no skill is promoting a token price.
- **Guardrail note:** as revenue telemetry gets wired (Stripe/Bankr), keep pricing/tier comms strictly utility-framed — no "buy now / returns / inducement" framing — and route any externally-posted finance numbers through Ash. Bankr economics stay internal business-model context, never user-facing promo.

## 6. Actions for Ash / Augustine

1. **[Augustine] Unblock `cost-report` dispatch.** It has never run; it's the authoritative spend source this review depends on. Confirm the Mon 5/25 07:00 slot fires and the cron-state entry appears. *(Owner: Augustine — ops/scheduler.)*
2. **[Augustine] Downgrade mechanical infra skills to Sonnet** — `proxmox-capacity`, `fleet-sweep`, and `heartbeat` via per-skill `model:` in aeon.yml. Est. ~$350–500/mo saved at no judgment-quality cost. Validate one cycle of output parity before/after. *(Owner: Augustine.)*
3. **[Ash] Approve wiring revenue telemetry** — a `STRIPE_*` key + `scripts/prefetch-stripe.sh` so margin becomes computable. Until then this review can only report the cost side. *(Owner: Ash — secrets/business.)*
4. **[Augustine] Keep pve5 thin-pool on the watchlist** — slow disk creep near 70%; plan a migration/trim before it sticks above the line. RAM, not disk, remains the density binding constraint elsewhere. *(Owner: Augustine.)*

---
*Sources: token-usage.csv (ok, 57 rows) · .outputs/proxmox-capacity.md + fleet-sweep.md (ok) · aeon.yml (ok) · Stripe/Bankr/Venice (not configured) · cost-report (never dispatched — figures self-computed at direct Opus rates, directional).*
*Generated by Aeon hermesos-finance-risk-review skill.*
