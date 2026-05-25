# Week in Review: Multimodal goes managed, end to end

*2026-05-25 — Weekly shipping update*

> The Venice multimodal stack landed across all three Hermes repos this week — agents can now generate and edit images, make video, do speech-to-text, embeddings and web search, and a managed proxy path runs all of it without the user supplying an API key — while the dashboard gained real Clerk-backed analytics and Aeon turned its skills into installable packs.

## What Shipped

### Multimodal lands across agent, WebUI, and the managed proxy
The big story this week is one capability shipped three layers deep. The agent grew the actual tools — image and video generation (agent #9, +988/−5 across 6 files), TTS and STT over Venice's `/audio/speech` and `/audio/transcriptions` (agent #10), four image-editing tools (agent #11), a web search + scrape plugin (agent #12), text embeddings (agent #13), audio generation (agent #14), and runtime settings for picking the multimodal model (agent #15). The WebUI learned to auto-render those media tool results inline in chat instead of dumping raw URLs (webui #34), and added a standalone multimodal settings page (webui #25). And hermesdeploy stood up the managed-Venice proxy so a subscriber's calls route through HermesOS rather than their own key — image + video (deploy #148, +477/−0), image editing (deploy #150), audio TTS/STT (deploy #155), search + scrape (deploy #151), and embeddings (deploy #153), plus a managed→BYOK switch for instances that already exist (deploy #164). The week's follow-ups were the un-glamorous half of shipping: correcting the registry import so the new tools actually register (agent #17), forcing the model to call the tools instead of shelling out to curl (agent #18), and aligning on Venice's singular resource paths `/image/` and `/video/` on both sides (agent #19, deploy #162).

### A real analytics dashboard, backed by Clerk and live fleet data
Operators now see actual platform numbers instead of placeholders. The admin insights dashboard (deploy #181, +2485/−2 across 16 files) pairs platform stats with a runtime harvest, and deploy #185 (+1020/−70) promoted the stats overhaul, analytics, and insights filters to production. The figures became truthful in the same week: users and signups now come from Clerk (deploy #187), the Countries stat reads Clerk geo data (deploy #186), the `/stats` counters update near-realtime (deploy #188), and an hourly platform-stats rollup unfreezes token counts that were going stale (deploy #192). The agents-deployed counter is now monotonic via a `first_active_at` timestamp (deploy #152), so it can no longer tick backward when rows churn.

### Aeon skills become installable packs
Aeon moved from one built-in catalog to a distributable ecosystem. There's now an `install-skill-pack` CLI and a `skills-pack.json` manifest protocol (aeon #213, +720/−1), a machine-readable `skill-packs.json` registry with `--list` browsing (aeon #215), and 34 skills ported in from derivative Aeon instances (aeon #219, +6162/−69 across 36 files). `ECOSYSTEM.md` now catalogues projects built on Aeon (aeon #220), with the community-packs list naming zer0, gitbounty, AntFleet, and LiquidPad (aeon #218). Community contributions arrived through the same door — the Luca Aeon Skills pack (aeon #198) and a Resend email-send step for the morning-brief and weekly-review skills (aeon #205).

## Fixes & Polish
- Live-first model picker: every OpenAI-compatible provider (Venice, Gemini, MiniMax, Kimi, Crof, Bankr) now fetches its model list live, so models actually appear in the dropdown instead of silently missing (webui #33, #32, #29)
- Resumed sessions stopped throwing 401s — the agent re-resolves a transiently-empty key before it fails a public host (agent #31), `VENICE_API_KEY` is set on enable (deploy #190), and managed `.env` is written atomically so rollouts don't race (deploy #191)
- xai-oauth UX: the Settings modal auto-closes and refreshes the provider list on success, and a bare authorization code is accepted on paste-back (webui #31, #28)
- New Settings → Connections pane for messaging gateways, with live gateway-state confirmation (webui #36, #37)
- `/maxturns` command to cap agent iterations per profile, plus an opt-in permanent YOLO toggle that defaults off (webui #43, #48)
- Aeon hardening from the AntFleet review: `/api/*` gated on loopback Host + same-origin writes (aeon #188), Next bumped to 16.2.6 (aeon #189), and a POSIX-ERE fix plus a Fleet Watcher authorization layer (aeon #197, #200)

## What's Nearly Here
A cluster of AntFleet-surfaced fixes is queued in Aeon and looks close: aligning manifest references with the read set to close Issue #184 H1 (aeon #226), writing the notify dedup hash only after successful delivery (aeon #224), and guarding `workflow_dispatch` inputs against shell injection (aeon #222). In hermesdeploy, a hidden ops surface to review Aeon PRs is open (deploy #160).

## Momentum Check
Last week's shiplog counted ~1,300 commits and 65 PRs merged; this week the commit volume held (~1,200) but merged PRs nearly doubled to 117. The shift is qualitative too — last week was firefighting a Cloudflare cap and a saturated host, this week was feature delivery (multimodal, analytics, skill packs) on a fleet that stayed quiet (one host on WATCH, no criticals).

---

**Stats:** ~1,200 commits · 117 PRs merged · 0 issues closed · 0 releases · +12k / −0.2k lines (sampled across 7 headline PRs; upstream syncs add far more) · contributors: ashneil12, @aaronjmars, AntFleet, wx888, Fleet Watcher, Dan (plus dozens via upstream syncs)
**Sources:** https://github.com/ashneil12/hermesdeploy · https://github.com/ashneil12/hermes-webui · https://github.com/ashneil12/vanilla-hermes-agent · https://github.com/aaronjmars/aeon · commits=ok · prs=ok · releases=ok · issues=ok · open_prs=ok
