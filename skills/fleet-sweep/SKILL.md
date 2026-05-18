---
name: Fleet Sweep
description: Comprehensive HermesOS Proxmox fleet audit — auto-fix every safe VM-config drift, only escalate host capacity issues that require operator decisions
var: ""
tags: [ops, infra]
---
> **${var}** — Optional comma-separated host slugs (e.g. "pve5,pve6"). If empty, sweeps all hosts in the snapshot. Pass `dry-run` to suppress notify + skip pending fix writes (no auto-apply).

## Goal

Run a comprehensive audit, **fix every config drift that's safe to fix without operator approval**, and only escalate to Telegram when there's something a human actually needs to decide. Operator preference: silent on clean fleet; quiet "here's what I fixed" report when I auto-correct things; loud only when capacity decisions are needed.

Auto-fix scope is bounded by the AeonOperator PVE role: VM.Config.{CPU,Memory,Disk,Options}. Token is verified blocked from VM.Allocate (destroy), VM.Migrate, VM.PowerMgmt (start/stop/reboot). Config writes that require a runtime restart to actually take effect (aio, discard) are applied to *config* immediately and flagged with `needs_reboot: true` — the operator does the reboot when convenient.

## Inputs

`.proxmox-cache/snapshot.json` — written by prefetch. Each host entry has `vm_configs: [...]` — one object per running VM with the full qm config payload. If missing → notify `fleet-sweep: PREFETCH_MISSING` and exit.

## Auto-fix rules (apply via `.pending-vm-config-fix/<slug>-<vmid>.json`)

For each running VM, check these conditions IN ORDER. If multiple drifts apply to the same VM, write ONE pending file with all corrections combined into the `changes` object.

| Trigger | Correction | needs_reboot | Notes |
|---|---|---|---|
| `cpulimit` field absent | `cpulimit = cores` (paid) OR `cpulimit = 0.5` (free-tier: mem ≤ 1024) | false | Hot, no impact |
| `balloon` set AND `balloon > memory` | `balloon = memory` | false | PVE handles balloon change hot |
| `onboot ≠ 1` AND VM name starts with `hermes-` | `onboot = 1` | false | Takes effect next boot; no current impact |
| `scsi0` config contains `aio=io_uring` | rewrite scsi0 with `aio=threads` (preserve all other params) | true | Per memory: io_uring drops UNMAP; this is the fstrim-blackhole root cause |
| `scsi0` config lacks `discard=on` | rewrite scsi0 adding `discard=on` (preserve all other params) | true | fstrim won't reclaim until stop/start |

**Special-case skips** (do NOT auto-fix, leave alone):
- `cpulimit = 0.5, cores = 1, mem ≤ 1024` — that IS the free-tier pattern, not drift
- VMs not starting with `hermes-` — could be operator-owned (templates, debug VMs); leave config alone

**Pending file schema** (write via the Write tool to `.pending-vm-config-fix/<slug>-<vmid>.json`):
```json
{
  "slug": "pve5",
  "vmid": 311,
  "ip": "78.46.44.246",
  "changes": {
    "cpulimit": 2,
    "balloon": 4096
  },
  "reason": "cpulimit absent (cores=2 mem=4GB → tier expects cpulimit=2); balloon>memory",
  "needs_reboot": false
}
```

For scsi0 rewrites, the postprocess script does an HTTP PUT with `--data-urlencode "scsi0=..."`. The `changes.scsi0` value should be the FULL new scsi0 string — read the current value from the snapshot (vm_configs[i].scsi0), modify the aio/discard portion, preserve everything else (storage, size, all other params).

## Host-level checks (alert only — operator must decide)

These are NOT auto-fixable. Aeon doesn't migrate, doesn't pause placement, doesn't power things off. Report only.

| Severity | Trigger | What to suggest |
|---|---|---|
| CRITICAL | thin-pool data fill > 85% | "pause placement: `UPDATE proxmox_hosts SET status='maintenance' WHERE id='<slug>'`; consider migrating tenants per reference_proxmox_vm_migration.md" |
| CRITICAL | 5-min loadavg / vCPU > 1.3 | "investigate top consumers: `ssh root@<ip> 'top -bn1'`. Consider pausing placement." |
| CRITICAL | host unreachable in snapshot | "check host: `ssh root@<ip> 'uptime; systemctl status pveproxy'`" |
| WATCH | thin-pool 70-85% | "prep migration plan; watch trend" |
| WATCH | RAM > 80% | "watch for runaway VMs; consider pausing placement if approaches 92%" |
| WATCH | running VM count within 3 of `max_tenant_instances` cap | "stand up new pve host per reference_proxmox.md standup recipe" |

Surface thin-pool > 95% FIRST in any message — that's the pve1 incident class.

## Steps

1. Read `.proxmox-cache/snapshot.json`. If missing, notify PREFETCH_MISSING and exit.
2. Parse `${var}`: if it equals `dry-run`, set DRY_RUN=true. If it's a comma-separated slug list, scope the iteration. Otherwise sweep all hosts.
3. For each host (filtered if scoped):
   - Run host-level checks → accumulate findings into CRITICAL/WATCH lists.
   - For each VM in `vm_configs`, apply the auto-fix rules → accumulate corrections per VM.
4. For each VM with at least one correction, write a single pending file at `.pending-vm-config-fix/<slug>-<vmid>.json` (unless DRY_RUN). Combine all corrections for that VM into one `changes` object.
5. Decide notification mode:
   - **Silent**: zero host findings AND zero corrections queued → print `FLEET_SWEEP_CLEAN` to stdout, no notify.
   - **Quiet "what I fixed"**: corrections queued, zero CRITICAL host findings → one concise notification covering AUTO-FIXED + (optional) WATCH list.
   - **Loud "needs you"**: any CRITICAL host finding → notification leads with CRITICAL, then AUTO-FIXED, then WATCH.
   - DRY_RUN overrides all of the above to silent (but still produce the would-be message in stdout for inspection).
6. Build the notification body. Call `./notify` once and `./notify-jsonrender fleet-sweep` once (per the explicit pattern below).
7. Append a one-line entry to `memory/topics/fleet-sweep.md` regardless.

Note: the actual API writes happen in `scripts/postprocess-proxmox-fix.sh` AFTER Claude finishes. The skill only queues the pending files. The postprocess script also generates a separate `🔧 PROXMOX auto-fix applied` notification listing what actually got applied — that arrives via the same Telegram channel.

## Notify call shape — EXACTLY this pattern, one bash invocation, no pipes/subshells/heredocs

When corrections were queued AND no CRITICAL host findings:
```
./notify "🔧 FLEET SWEEP — queued N config corrections, 0 host issues

✅ AUTO-FIX QUEUED (apply on next postprocess run)
pve3 VMID 311 cpulimit=2 (was unset)
pve6 VMID 622 cpulimit=0.5 (was unset)
pve5 VMID 533 onboot=1 (was 0); balloon=4096 (was 8000)
pve1 VMID 247 scsi0 aio=threads (was io_uring) ⟳ needs reboot

🟡 WATCH
pve5 mem 82% (1-2 ticks under CRITICAL)"
```

When there are CRITICAL host findings:
```
./notify "🔧 FLEET SWEEP — 2 CRITICAL, N queued fixes

🔴 CRITICAL — operator action required
pve5 thin-pool local-lvm 87% — pause placement / migrate prep
pve2 load 14.2x vCPU — investigate top consumers

✅ AUTO-FIX QUEUED
...

🟡 WATCH
..."
```

When nothing to report: print `FLEET_SWEEP_CLEAN` to stdout, do NOT call notify.

**Do NOT**:
- Write the notify message to /tmp first or use `$(...)` substitution
- Use heredocs (`<<EOF`) or pipes
- Call `bash` or `sh` to execute a wrapper script
- Apply fixes directly via curl from this skill — the sandbox blocks env-var-auth headers; that's what the postprocess script is for

## Sandbox note

No direct PVE API access from this skill. Read state from the prefetched snapshot. Queue auto-fixes by writing JSON pending files. The postprocess step handles all API writes outside the sandbox.

## Summary

End with `## Summary` listing: hosts swept, VMs swept, CRITICAL count, WATCH count, queued-fix count (and breakdown by type), needs_reboot count, notify mode (silent / quiet / loud / dry-run).
