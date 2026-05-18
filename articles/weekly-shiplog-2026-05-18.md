# Week in Review: SuperGrok lands, the Cloudflare wall breaks

*2026-05-18 — Weekly shipping update*

> HermesOS rolled out the xAI Grok SuperGrok OAuth flow end-to-end across all three fork repos while simultaneously firefighting a Cloudflare 200-record cap that had been silently leaking DNS on every tenant destroy — and Aeon completed its fork-intelligence layer with four new skills.

## What Shipped

### SuperGrok OAuth ships end-to-end across the stack
The agent, the WebUI, and the dashboard all learned to speak xAI Grok's SuperGrok subscription flow this week — three repos, one feature. The agent-side foundation landed via the upstream sync to vanilla-hermes-agent v0.14.0 (#7), which is the first release to ship the `xai-oauth` provider. hermes-webui surfaced "Sign in with xAI (SuperGrok)" in the onboarding wizard (#17), then patched the same flow three more times in the same week: localized ~30 hardcoded English strings across 11 locales (#20), un-broke the Settings → Providers "Authenticate" button that was routing OAuth into a stale API-key terminal command (#21), and gave xai-oauth its own info tile on the dashboard instead of a misleading dropdown entry (#125). hermesdeploy made xai-oauth a first-class deploy-time provider tile (#120). Users with a SuperGrok subscription can now sign in via accounts.x.ai once and have HermesOS route Grok 4.3 calls through their subscription — no per-token API key needed.

### A Cloudflare cap fired, a pve5 host buckled, and the fleet got tougher for it
On 2026-05-17 the per-tenant Cloudflare A record leak filled the hermesos.cloud Free-plan 200-record cap, triggered 81,045 quota-exceeded errors on every deploy, and had to be cleaned by hand. The same day, pve5 hit 13.74× CPU saturation (load 164.89 on 12 vCPU) with 49 running tenants. The response landed across the next 36 hours. `removeInstanceDns()` was wired into the four destroy paths that were bypassing it — user-BYO host DELETE, `purge-expired` cron, `dormant-reclaim` cron, and `cold-storage` archive (#143), then collapsed into a shared `removeInstanceDnsBestEffort` helper to stop drift between six near-identical callsites (#147). An hourly backstop cron at `/api/cron/reconcile-cloudflare-dns` now prunes orphan A records that even the per-callsite fix can't reach — cross-host VM migrations don't repoint DNS, so `vzdump+qmrestore` was leaking on a different axis (#145). On the capacity side, the empirical 12-thread Ryzen 5 3600 wall on AX41-NVMe got raised from 20 to 40 tenants per host so the env-fallback path stops disagreeing with the registry ceiling (#138), and the placement loop now refuses to fall back to env-order when every registry host is deliberately drained (#131). `aio=threads` got stamped on every scsi0 disk and the template-bake (#130, #132) — Proxmox's default `aio=io_uring` silently drops UNMAP, which was why `fstrim` reported gigabytes trimmed inside the guest while the LVM thin pool reclaimed nothing.

### Aeon's fork-intelligence layer fills out
Four new fork-watching skills shipped this week, and together they answer the four questions you'd actually ask about a fork ecosystem. `fork-release-tracker` (#166) announces the first time any fork cuts a tagged GitHub release — the moment a project graduates from "interesting" to "infrastructure." `fork-first-run-alert` (#179) emits a same-day named alert the first time a fork completes a workflow run, closing the 6-day silence gap before the weekly `fork-cohort` digest picks it up. `fork-skill-gap` (#176) audits every POWER + ACTIVE fork's `skills.json` against upstream and surfaces the per-fork gap — i.e. what's in upstream that a given fork hasn't adopted yet. And `fleet-state` (#168) is the Monday synthesis layer: it consumes `fork-cohort`, `fork-release-tracker`, and `contributor-spotlight` outputs and emits one composite digest with week-over-week deltas and a 12-week rolling trend.

## Fixes & Polish
- Six-pass end-to-end review across dashboard + browser-sidecar: ~956 lines of dead code removed, 35 new tests, plus security fixes (heredoc RCE guard, SSRF blocklist, log redaction expansion) (#135)
- Cold storage Phases 2–7 — `archiveInstance` / `restoreInstance` / `verifyArchiveIntegrity` / `purgeArchive` with 23 unit tests, plus `restore-vm-cold.sh` deployed to all 6 PVE hosts (#121)
- Ghost soft-deleted rows can no longer strand users; dashboard listing now filters on `lifecycle_state`, not `status` (#142)
- Migration-drift cron stops its 444-error runaway by routing through a `SECURITY DEFINER` public RPC instead of the rejected PostgREST schema escape (#144)
- Auto-recover sweep catches the silent failure mode where `lifecycle_state='active'` rows still report running while their WebUI containers have crashed for hours (#146)
- Multi-remote `gh` calls (`-R repo`) finally wired through every dashboard route and skill that was breaking the moment an upstream remote was added (#169, #178)

## What's Nearly Here
A bake-timeout bump for slow-storage hosts is queued in hermesdeploy (#133), and the WebUI's collapsed-chat-sidebar edge toggle (#22) and provider-tile profile picker (#16) are both ready in hermes-webui.

---

**Stats:** ~1,300 commits · 65 PRs merged · 0 issues closed · 0 releases · ~+25k / −5k lines (sampled) · contributors: ashneil12, @aaronjmars, meichuanyi (plus dozens via upstream syncs)
**Sources:** https://github.com/ashneil12/hermesdeploy · https://github.com/ashneil12/hermes-webui · https://github.com/ashneil12/vanilla-hermes-agent · https://github.com/aaronjmars/aeon · commits=ok · prs=ok · releases=ok · issues=ok · open_prs=ok
