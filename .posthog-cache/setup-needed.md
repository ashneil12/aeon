POSTHOG_SETUP_NEEDED

Required GitHub Actions secrets:
- POSTHOG_API_KEY
- POSTHOG_PROJECT_ID

Optional:
- POSTHOG_HOST, default https://app.posthog.com

Privacy rule: use project-level/session metadata and summaries where possible. Do not expose raw user identifiers in AEON output.
