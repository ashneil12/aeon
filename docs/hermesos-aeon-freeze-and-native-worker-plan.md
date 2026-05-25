# HermesOS AEON Freeze and Native Worker Plan

## Decision

AEON remains supported, but it is no longer the default HermesOS autonomy path.

Default path:

```txt
Hermes profiles plus cron plus script probes plus Kanban workers
```

Optional out-of-band path:

```txt
AEON GitHub Actions fork, manual dispatch, or user-enabled schedules
```

## Why

AEON has been useful, but it creates a second operating surface:

- separate GitHub Actions scheduler
- separate Claude or Anthropic OAuth burn
- separate secrets store
- separate Discord routing layer
- extra inspector and debug surface
- outputs that still need Hermes or Augustine to turn them into action

For HermesOS itself, this duplicates what Hermes already has: profiles, cron, gateway, tools, skills, memory, and Kanban.

## Freeze posture

This fork keeps all AEON skills and docs intact. Users can still manually run or re-enable AEON.

Changes:

- Disable scheduled AEON skills in `aeon.yml`.
- Change default model to `claude-sonnet-4-6` instead of Opus.
- Stop the 5-minute `messages.yml` scheduled polling loop.
- Keep `workflow_dispatch` so manual runs still work.

## Native worker replacement

Implement an AEON-inspired Hermes worker template:

```txt
input: schedule, event, or manual instruction
prefetch: optional deterministic script
worker: Hermes profile or Kanban task
state: local files, SQLite, or Kanban comments
output: action receipt with owner, status, evidence, and gate
```

Core primitives:

- script-only cron for deterministic probes
- Hermes cron for reasoning summaries
- Kanban for actual work and completion proof
- department profile gateways for interactive wake-up
- skills and runbooks for reusable policy

## Migration map

| AEON class | Hermes-native default |
|---|---|
| fleet-sweep | script-only fleet probes plus Benedict Kanban task on transition |
| proxmox-capacity | script-only capacity watcher, quiet on clean |
| posthog-session-analyzer | PostHog prefetch script plus Chrysostom/Aquinas Kanban tasks |
| growth desk | Chrysostom scheduled Hermes cron or Kanban task |
| finance risk | Anselm weekly Hermes cron with no secret dumps |
| repo pulse/code health | Aquinas code-health cron |
| heartbeat | gateway/process watchdogs |

## User-facing product stance

HermesOS default: native Hermes autonomous workers.

Advanced option: connect an AEON fork for users who want GitHub-hosted, out-of-band autonomous workflows.
