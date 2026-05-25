# PostHog Session Analysis (HermesOS)

PostHog project 368999, host hermesos.cloud. Recordings are a temporary growth/debug
tool — Ash wants a staged retirement, not permanent surveillance. Notifications must be
PII-free (no raw user ids, no quoted private input, aggregates only).

## Run log

### 2026-05-25 — Verdict: WATCH

**Data scope (small/recent — directional, not statistical):** 50 session recordings
(~09:00 UTC window), 200 events (one API page, before ~08:50 UTC), 100 exceptions
(02:57–05:24 UTC). Funnels: `fetch_failed` — no drop-off data this run.

**Top UX friction (evidence-counted):**
1. Onboarding rageclicks — 2 rageclicks, both on `/get-started` (the only rageclicks in
   the sample).
2. Model/provider setup churn — repeated "← Back to model setup" (3), "More providers…"
   (4), "Continue to Managed Credits" (4), "Custom LLM Provider" — users bouncing between
   provider selection and model/credits setup. Confusing step.
3. Low engagement — only ~18% active time (1453s active / 8235s total across 50 sessions);
   2 fully-dead sessions (≥30s, ≤5s active, 0 clicks). Many idle/abandoned.
4. Dashboard performance — LCP poor on `/dashboard/welcome` (4032ms) and instance detail
   `/dashboard/instances/:id` (3696ms); CLS 0.21 (needs-improvement) on instance detail
   (layout shift). Landing `/` is healthy (LCP ~0.8–1.2s, INP <100ms, low CLS).

**Landing page:** `/` is top entry (35/50 recordings) and performs well — friction is
just past the CTA, in get-started, not on the landing. Path: `/` → `/get-started` →
`/get-started/activate` → `/dashboard/*` (7 recordings entered directly at
`/get-started/activate`, likely email activation links). International audience (US, DE,
VN, TH, SG, MX, IT; Korean CTA "무료로 시작" observed) → copy localization may matter.

**No real app errors.** 99/100 exceptions are `runtime.sendMessage(). Tab not found.` (a
browser-extension error, not HermesOS); the 1 other is `insertBefore NotFoundError`
(classic Google-Translate-vs-React extension bug). All `handled=true`, 99 on `/`, from
just 2 distinct users → essentially extension noise, zero app signal. Recordings show
console_error_count=0 across all 50.

**Privacy risk (priority):**
- Session recording is ON across sensitive authenticated routes with an EMPTY urlBlocklist:
  observed traffic on `/dashboard/chat` (private prompts), `/dashboard/wallet`,
  `/dashboard/billing`, `/dashboard/settings`, `/dashboard/instances/:id/console`
  (could expose keys/credentials).
- `consoleLogRecordingEnabled: true` — console capture on (can leak tokens).
- PII captured plaintext: person properties + `$identify`/`$set` events carry email, name,
  precise geoip; recordings carry full email/name.
- Noise-exception capture costs money and stores PII-laden events for zero app signal.

**Actions (owner handoff — recording config lives in HermesOS frontend `posthog.init`,
not in this repo):**
1. Add urlBlocklist to stop recording: `/dashboard/chat`, `/dashboard/wallet`,
   `/dashboard/billing`, `/dashboard/settings`, `/dashboard/instances/*/console`.
2. Disable `consoleLogRecordingEnabled` (or scrub) to avoid token leaks.
3. Filter exception capture (before_send): drop `runtime.sendMessage` and Google-Translate
   `insertBefore/removeChild` extension errors → removes ~99% noise.
4. Onboarding: investigate `/get-started` model/provider/credits step (rageclicks +
   back-nav churn); clarify provider → managed-credits flow.
5. Perf: investigate `/dashboard/welcome` and instance-detail LCP (~4s) and instance-detail
   CLS (reserve layout space).
6. Staged retirement: landing is already low-risk → keep minimal/anonymous; then
   onboarding-only; then explicit opt-in/debug-only for authenticated dashboard. Blocklist
   sensitive routes NOW as step one.
7. Fix funnels prefetch (`fetch_failed`) so drop-off analysis is possible next run.

**Counts:** recordings 50 · events 200 · exceptions 100 (99 extension-noise, 1
extension-DOM, 0 real app) · friction items 4 · privacy flags 4 · actions 7.
