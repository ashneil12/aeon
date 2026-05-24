---
name: Fleet Sweep
description: Comprehensive HermesOS Proxmox fleet audit — auto-fix safe VM-config drift, detect stuck/boot-loop/straggler instances, and escalate only the bounded repairs that need operator authority
var: ""
tags: [ops, infra]
---
> **${var}** — Optional comma-separated host slugs (e.g. "pve5,pve6"). If empty, sweeps all hosts in the snapshot. Pass `dry-run` to suppress notify + skip pending fix writes (no auto-apply).

## Goal

Run a comprehensive audit, **fix every config drift that's safe to fix without operator approval**, detect unhealthy instances, and only escalate to Discord/Telegram when there is something Benedict/Ops or Augustine needs to decide.

Operator preference: silent on clean fleet; quiet "here's what I fixed" report when I auto-correct safe config drift; loud only for capacity or health problems that need a person or a more privileged repair token.

## Autonomy boundary

AEON is smart, but it must not harm tenants. The default operator token is intentionally scoped to `VM.Config.{CPU,Memory,Disk,Options}` only. It is not allowed to destroy, migrate, start, stop, reboot, or reset VMs.

This skill may:

- queue safe VM config corrections
- detect stuck/stopped/boot-loop/health-straggler instances
- produce bounded repair recommendations with exact host/vmid evidence
- queue repair intents under `.pending-vm-repair/` **only if** the repair is explicitly safe and evidence-backed

This skill must not:

- destroy disks or VMs
- migrate tenants
- reboot/start/stop/reset without a separate power-repair policy/token
- act on non-`hermes-` VMs
- act on templates, debug boxes, or operator-owned VMs

## Inputs

`.proxmox-cache/snapshot.json` — written by prefetch. Each host entry has `vm_configs: [...]`, one object per VM with qm status/config payload. If missing → notify `fleet-sweep: PREFETCH_MISSING` and exit.

## Auto-fix rules: config drift

Apply via `.pending-vm-config-fix/<slug>-<vmid>.json`.

For each running `hermes-` VM, check these conditions IN ORDER. If multiple drifts apply to the same VM, write ONE pending file with all corrections combined into the `changes` object.

| Trigger | Correction | needs_reboot | Notes |
|---|---|---|---|
| `cpulimit` field absent | `cpulimit = cores` (paid) OR `cpulimit = 0.5` (free-tier: mem ≤ 1024) | false | Hot, no impact |
| `balloon` set AND `balloon > memory` | `balloon = memory` | false | PVE handles balloon change hot |
| `onboot ≠ 1` AND VM name starts with `hermes-` | `onboot = 1` | false | Takes effect next boot; no current impact |
| `scsi0` contains `aio=io_uring` OR has no explicit `aio=` clause | rewrite scsi0 with `aio=threads` | true | io_uring drops UNMAP; missing means runtime default hazard |
| `scsi0` config lacks `discard=on` | rewrite scsi0 adding `discard=on` | true | fstrim won't reclaim until stop/start |

Special-case skips:

- `cpulimit = 0.5, cores = 1, mem ≤ 1024` is the free-tier pattern, not drift.
- VMs not starting with `hermes-` are operator-owned and must be left alone.

Pending config schema:

```json
{
  "slug": "pve5",
  "vmid": 311,
  "ip": "78.46.44.246",
  "changes": { "cpulimit": 2, "balloon": 4096 },
  "reason": "cpulimit absent; balloon>memory",
  "needs_reboot": false
}
```

## Health and straggler detection

Detect these for every `hermes-` VM in snapshot. If dashboard/customer state is not present in the snapshot, label it `needs_db_correlation` instead of guessing.

| Severity | Trigger | Default action |
|---|---|---|
| CRITICAL | VM expected running but PVE status is stopped | write `.pending-vm-repair/` intent with `action: start_candidate`; notify Ops |
| CRITICAL | VM has `status=running` but qemu guest agent missing/unresponsive across 2+ sweeps | notify Ops; no power action |
| CRITICAL | same VM appears in failed/starting/pending state across 2+ sweeps | notify Ops; no power action |
| WATCH | VM running but image/update straggler metadata indicates stale container | notify Aquinas/Ops; suggest direct compose converger |
| WATCH | VM has high uptime after a config requiring reboot was applied | notify Ops as reboot window candidate |
| WATCH | non-`hermes-` running VMs on prod PVE host | notify Ops inventory; no action |

Repair intent schema:

```json
{
  "slug": "pve5",
  "vmid": 511,
  "ip": "78.46.44.246",
  "action": "start_candidate",
  "reason": "dashboard expected running but PVE status=stopped for 2 consecutive sweeps",
  "evidence": { "first_seen": "2026-05-24T09:00:00Z", "consecutive_sweeps": 2 },
  "requires": ["PROXMOX_POWER_OPERATOR_TOKENS", "dashboard_state_correlation"]
}
```

The default postprocess must leave repair intents unapplied unless `PROXMOX_POWER_OPERATOR_TOKENS` is configured and the intent has correlation evidence. This keeps AEON autonomous for safe config fixes and cautious for tenant-impacting power actions.

## Host-level checks

These are not auto-fixable. Report only.

| Severity | Trigger | What to suggest |
|---|---|---|
| CRITICAL | thin-pool data fill > 85% | pause placement; prep migration |
| CRITICAL | 5-min loadavg / vCPU > 1.3 | investigate top consumers |
| CRITICAL | host unreachable in snapshot | check host/pveproxy |
| WATCH | thin-pool 70-85% | prep migration plan |
| WATCH | RAM > 80% | watch runaway VMs; consider pausing placement near 92% |
| WATCH | running VM count within 3 of `max_tenant_instances` cap | stand up new pve host |

Surface thin-pool > 95% FIRST in any message.

## Steps

1. Read `.proxmox-cache/snapshot.json`. If missing, notify PREFETCH_MISSING and exit.
2. Parse `${var}`. `dry-run` suppresses notify and pending writes. A comma-separated host list scopes the sweep.
3. For each host:
   - run host-level checks
   - scan every VM for config drift
   - scan every VM for health/straggler findings
4. Write config fixes to `.pending-vm-config-fix/` unless DRY_RUN.
5. Write repair intents to `.pending-vm-repair/` only when evidence is explicit and action is in the allowed candidate list.
6. Decide notification mode:
   - silent: zero findings, zero fixes, zero repair intents
   - quiet: only safe config fixes or low watch findings
   - loud: any critical host or instance-health finding
7. Call `./notify` once and `./notify-jsonrender fleet-sweep` once when there is anything to report.
8. Append a one-line entry to `memory/topics/fleet-sweep.md` regardless.

## Notify shape

When clean: print `FLEET_SWEEP_CLEAN` to stdout, no notify.

When safe fixes are queued:

```bash
./notify "🔧 FLEET SWEEP — queued N config corrections, 0 critical

✅ AUTO-FIX QUEUED
pve3 VMID 311 cpulimit=2
pve1 VMID 247 scsi0 aio=threads/discard=on ⟳ needs reboot"
```

When health/capacity action is needed:

```bash
./notify "🚨 FLEET SWEEP — 1 CRITICAL instance-health finding

🔴 CRITICAL
pve5 VMID 511 stopped but expected running for 2 sweeps — repair intent queued, needs power-token gate

✅ SAFE FIXES
...

🟡 WATCH
..."
```

Do not apply fixes directly via curl from this skill. Postprocess scripts handle writes outside the sandbox.

## Sandbox note

No direct PVE API access from this skill. Read state from the prefetched snapshot. Queue auto-fixes by writing JSON pending files. The postprocess step handles all API writes outside the sandbox.

In this sandbox, file-based helper execution can be blocked. Prefer inline `jq` filters and direct snapshot reads.

## Summary

End with `## Summary` listing: hosts swept, VMs swept, CRITICAL count, WATCH count, queued-config-fix count, queued-repair-intent count, needs_reboot count, notify mode.
