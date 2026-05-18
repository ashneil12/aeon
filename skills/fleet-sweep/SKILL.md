---
name: Fleet Sweep
description: Comprehensive HermesOS Proxmox fleet audit — host capacity drift, per-VM config drift, auto-fix safe items (cpulimit only), report the rest with operator runbooks
var: ""
tags: [ops, infra]
---
> **${var}** — Optional comma-separated host slugs to scope (e.g. "pve5,pve6"). If empty, sweeps all hosts in the prefetched snapshot. Pass `dry-run` to suppress notify and the auto-fix pending writes.

## Goal

One periodic sweep that touches every drift surface I care about across pve1-pve6, separates "auto-fixable safely" from "needs your eyes," and gives a single clean report. Companion to `proxmox-capacity` (which only watches host-level capacity transitions) — this one looks INSIDE each VM's config.

Auto-fix scope is intentionally narrow: **only cpulimit drift**. Everything else (aio=io_uring, missing discard, balloon mismatch, capacity overload) reports with the exact runbook command but does not act. The PVE operator token has VM.Config.CPU and nothing else; rebuilding broader auto-fix requires explicit approval.

## Inputs

`.proxmox-cache/snapshot.json` — written by `scripts/prefetch-proxmox-capacity.sh` before this skill runs. Each `hosts[slug]` entry now also contains `vm_configs: [...]` — one object per running VM with the full `qm config` payload (cpulimit, cores, memory, balloon, scsi0, boot, etc.). If snapshot is missing → notify `fleet-sweep: PREFETCH_MISSING` and exit.

`memory/proxmox-state.json` (optional) — same shape used by proxmox-capacity. Read for historical bucket comparison; do not overwrite (proxmox-capacity owns that file).

## Checks

### Host level (per host)

| Severity | Trigger | Action |
|---|---|---|
| CRITICAL | thin-pool data fill > 85% | Report. Suggest: pause placement (`UPDATE proxmox_hosts SET status='maintenance' WHERE id='<slug>'`) + migrate per `reference_proxmox_vm_migration.md` |
| CRITICAL | 5-min loadavg / vCPU > 1.3 | Report. Suggest: pause placement, investigate top consumers via `ssh root@<ip> 'top -bn1'` |
| CRITICAL | host unreachable in snapshot | Report. Suggest: `ssh root@<ip> 'uptime; systemctl status pveproxy'` |
| WATCH | thin-pool 70-85% | Report. Suggest: monitor trend, prep migration plan |
| WATCH | RAM > 80% | Report. Suggest: check for runaway VMs, pause placement if approaches 92% |
| WATCH | running VM count within 3 of `max_tenant_instances` cap | Report. Suggest: stand up new pve host per `reference_proxmox.md` standup recipe |

### VM level (per running VM, per host)

| Severity | Trigger | Auto-fix? | Runbook |
|---|---|---|---|
| WARN | `cpulimit` field absent from qm config | **AUTO-FIX** | Write `.pending-cpulimit-fix/<slug>-<vmid>.json` with target=cores (paid tier) or 0.5 (mem<=1024 free tier). Postprocess applies via API. |
| INFO | `cpulimit` ≠ `cores` (e.g. cores=4 cpulimit=2) | No | Suggest: `qm set <vmid> --cpulimit <cores>` IF user wants the tier-pattern alignment. Some tenants may have intentional throttling. |
| WARN | `scsi0` contains `aio=io_uring` | No | Per memory: `aio=io_uring` drops UNMAP on Hermes VMs — fstrim doesn't reclaim thin-pool blocks. Runbook: `qm set <vmid> --scsi0 '...,aio=threads'` + VM reboot. |
| WARN | `scsi0` missing `discard=on` | No | fstrim won't release blocks back to LVM-thin pool. Runbook: `qm set <vmid> --scsi0 '...,discard=on'` + VM stop/start (hot-apply config-only doesn't take effect until requ). |
| INFO | `balloon` set, value > `memory` | No | Misconfigured ballooning — balloon should be ≤ memory. Surface for review. |
| INFO | `onboot` ≠ 1 on tenant VM | No | VM won't restart with host. Probably intentional for staging VMs but worth surfacing. |

Special case: if ANY thin-pool exceeds 95%, surface it FIRST in the message — the pve1 incident class (2026-05-12 hit 99.99% overcommit).

## Steps

1. Read inputs. If `.proxmox-cache/snapshot.json` missing → notify PREFETCH_MISSING and exit.
2. If `${var}` looks like `dry-run`, set DRY_RUN=true and proceed (skip notify + pending fix writes at the end).
3. Iterate hosts (filtered by `${var}` if it looks like a comma-separated slug list). For each host, run host-level checks then iterate `vm_configs` for VM-level checks. Accumulate findings into structured groups (CRITICAL_HOSTS, WATCH_HOSTS, AUTO_FIX_QUEUE, MANUAL_RUNBOOK_QUEUE).
4. For each item in AUTO_FIX_QUEUE (cpulimit drift): if NOT DRY_RUN, write `.pending-cpulimit-fix/<slug>-<vmid>.json` with `{slug, vmid, ip, cpulimit, reason}`. The postprocess script applies it after this run.
5. Build the output. Skip notify entirely if no findings (truly clean fleet). Otherwise build a single message + a json-render card.
6. If NOT DRY_RUN and findings exist: call `./notify "..."` and `./notify-jsonrender fleet-sweep "..."` exactly per the pattern below.
7. Append a one-line entry to `memory/topics/fleet-sweep.md` with the summary regardless of notify mode.

## Output format

**Single notify call shape — exactly this pattern, one bash invocation, do not pipe or subshell:**

```
./notify "🔧 FLEET SWEEP — N findings (M auto-fixed, K need ops)

🔴 CRITICAL
pve5: load 12.4x vCPU — investigate
pve1: thin-pool local-lvm 87% — migrate prep needed

🟡 WATCH
pve6: RAM 84%
pve2: 47/50 VM cap

✅ AUTO-FIXED
pve3 VMID 311: cpulimit set to 2 (was unset)
pve6 VMID 622: cpulimit set to 0.5 (was unset)

🛠 MANUAL RUNBOOK
pve1 VMID 247: aio=io_uring → qm set 247 --scsi0 ...,aio=threads + reboot
pve4 VMID 412: discard=off → qm set 412 --scsi0 ...,discard=on + stop/start"
```

Then immediately:
```
./notify-jsonrender fleet-sweep "...same body..."
```

**Do NOT**:
- Write the message to /tmp first
- Use $(...) command substitution or heredocs
- Call bash to execute a notify wrapper script

If there are zero findings, print `FLEET_SWEEP_CLEAN` to stdout instead and skip both notify calls — silent on no news.

## Sandbox note

Never call the PVE API directly from inside this skill — env-var-based curl auth is blocked. The prefetch fetched everything you need (read side). The write side (cpulimit fixes) lives in `scripts/postprocess-proxmox-fix.sh`, which runs OUTSIDE the sandbox after Claude finishes. You communicate with it by writing `.pending-cpulimit-fix/*.json` files.

## Summary

End with a `## Summary` listing: hosts swept, findings by severity, auto-fix queue size, manual-runbook queue size, notify mode (sent / silent / dry-run).
