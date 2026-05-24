#!/usr/bin/env bash
# Prefetch PostHog data for posthog-session-analyzer.
# Secrets are read only inside GitHub Actions and are never printed.
set -euo pipefail
SKILL="${1:-}"
[ "$SKILL" = "posthog-session-analyzer" ] || exit 0

OUT=".posthog-cache"
mkdir -p "$OUT"

if [ -z "${POSTHOG_API_KEY:-}" ] || [ -z "${POSTHOG_PROJECT_ID:-}" ]; then
  cat > "$OUT/setup-needed.md" <<'MD'
POSTHOG_SETUP_NEEDED

Required GitHub Actions secrets:
- POSTHOG_API_KEY
- POSTHOG_PROJECT_ID

Optional:
- POSTHOG_HOST, default https://app.posthog.com

Privacy rule: use project-level/session metadata and summaries where possible. Do not expose raw user identifiers in AEON output.
MD
  exit 0
fi

HOST="${POSTHOG_HOST:-https://app.posthog.com}"
BASE="${HOST%/}/api/projects/${POSTHOG_PROJECT_ID}"
AUTH=( -H "Authorization: Bearer ${POSTHOG_API_KEY}" -H "Content-Type: application/json" )

fetch() {
  local name="$1" path="$2"
  curl -fsS --max-time 30 "${AUTH[@]}" "$BASE$path" -o "$OUT/$name" || echo "{\"error\":\"fetch_failed\",\"path\":\"$path\"}" > "$OUT/$name"
}

# Defensive endpoints. PostHog API shape can differ by plan/project; failures are cached as JSON errors for Claude to interpret.
fetch recordings.json "/session_recordings/?limit=50"
fetch events.json "/events/?limit=200"
fetch errors.json "/events/?event=%24exception&limit=100"
fetch persons_sample.json "/persons/?limit=50"
fetch funnels.json "/funnels/?limit=50"

date -u +%FT%TZ > "$OUT/generated_at.txt"
