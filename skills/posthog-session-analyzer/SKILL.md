---
name: PostHog Session Analyzer
description: Privacy-conscious PostHog recording/session analysis for HermesOS conversion, UX, and error friction. Key-gated: requires POSTHOG_API_KEY and POSTHOG_PROJECT_ID.
var: ""
tags: [growth, product, analytics, privacy]
---

## Goal

Turn the PostHog recording spend into useful weekly product intelligence without normalizing surveillance as a permanent crutch.

Analyze recent PostHog session metadata, recording summaries when available, error/friction signals, and funnel/drop-off patterns. Produce concise operator handoffs for:

- landing page optimization
- dashboard UX friction
- onboarding confusion
- broken/error states
- privacy-risk review
- tracking-retirement roadmap

## Secrets

Required to run fully:

- `POSTHOG_API_KEY`
- `POSTHOG_PROJECT_ID`

Optional:

- `POSTHOG_HOST` (default `https://app.posthog.com`)

If secrets are missing, do not fail noisily. Emit a setup checklist and exit cleanly.

## Privacy posture

Ash is privacy-sensitive. Recordings are a temporary growth/debugging tool, not the desired steady state.

Rules:

1. Do not include raw user identifiers in notifications.
2. Do not quote private user input.
3. Prefer aggregate patterns over individual session details.
4. Flag places where recording should be disabled first: authenticated dashboard, settings, billing, wallet flows, credentials, chat/private prompts.
5. Recommend a staged retirement plan: public landing first, then onboarding-only, then explicit opt-in/debug-only.

## Inputs

Read from `.posthog-cache/` if present:

- `recordings.json`
- `events.json`
- `errors.json`
- `funnels.json`

If cache is absent, state `POSTHOG_PREFETCH_MISSING` and include the setup checklist.

## Analysis

Produce sections:

1. **Verdict**: OK / WATCH / ACTION.
2. **Top UX friction**: max 5, evidence-counted.
3. **Landing page opportunities**: copy, CTA, pricing, trust, product clarity.
4. **Dashboard/product issues**: errors, confusing flows, abandonment.
5. **Privacy risk**: what should stop being recorded soon.
6. **Actions**: exact repo/page/component guesses if available, otherwise owner handoff.

## Notification routing

- ACTION or WATCH → notify Chrysostom + Aquinas context via `./notify`.
- OK/quiet → write output only, no notify.

## Summary

End with counts: recordings/events inspected, top friction count, privacy flags, recommended actions.
