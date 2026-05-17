---
name: Proxmox Capacity
description: Per-host capacity drift detection across the Hermes Proxmox fleet — silent unless a host transitions between buckets, with one daily digest at 09:00 UTC
var: ""
tags: [ops, infra]
---
> **${var}** — Optional comma-separated host slugs to scope (e.g. "pve1,pve5"). If empty, checks all hosts present in the prefetched snapshot.

## Goal

Detect per-host capacity drift across the Hermes Proxmox fleet (pve1-pve6, Hetzner bare-metal) before a host fills its thin-pool. Single high-signal output — silent on no change, transition-on-deterioration, plus one scheduled daily digest. Source data is pre-fetched (sandbox blocks env-var-auth in curl); do not curl from this skill.

## Inputs

1. `.proxmox-cache/snapshot.json` — written by `scripts/prefetch-proxmox-capacity.sh` before this skill runs. Shape:
   ```json
   {
     "generated_at": "2026-05-17T12:00:00Z",
     "hosts": {
       "pve1": {
         "reachable": true,
         "status": { "cpu": 0.45, "memory": {"total": ..., "used": ...}, "loadavg": [...], "rootfs": {...} },
         "storage": [{"storage": "local-lvm", "type": "lvmthin", "total": ..., "used": ..., "avail": ...}, ...],
         "vm_total": 34, "vm_running": 30, "vm_stopped": 4
       },
       ...
     },
     "hetzner": {
       "servers": [{"server_ip": "...", "server_name": "pve1", "status": "ready", "cancelled": false, "paid_until": "..."}, ...],
       "traffic": {"pve1": {"in_tb": 1.2, "out_tb": 8.4, "limit_tb": 20}, ...}
     }
   }
   ```
   If this file is missing or empty, notify `proxmox-capacity: PREFETCH_MISSING — scripts/prefetch-proxmox-capacity.sh did not run` and exit.

2. `memory/proxmox-state.json` — last-known bucket per host. Created on first run. Shape:
   ```json
   { "pve1": {"bucket": "OK", "checked_at": "..."}, ... }
   ```
   Treat missing entries as `bucket: "UNKNOWN"`.

3. `${TODAY}` (env), `${var}` (host-scope filter), and the current UTC hour (from `date -u +%-H`).

## Bucket rules

For each reachable host, compute the worst signal across:

| Signal | OK | WATCH | CRITICAL |
|---|---|---|---|
| Largest thin-pool `used/total` | < 0.70 | 0.70–0.85 | > 0.85 |
| Memory `used/total` | < 0.80 | 0.80–0.92 | > 0.92 |
| 5-min loadavg ÷ vCPU count | < 0.8 | 0.8–1.3 | > 1.3 |
| Hetzner traffic `(in+out)/limit_tb` for current month | < 0.60 | 0.60–0.85 | > 0.85 |

Host bucket = worst of the four. Unreachable host = bucket `UNREACHABLE`.

Special-case the pve1-style scenario explicitly: if any thin-pool `used/total > 0.95`, surface it FIRST in any output, with the absolute number ("pve1 local-lvm: 362/379 GB, 95.5%"). This is the failure mode that nearly took the fleet down on 2026-05-12.

## Steps

1. Read inputs. If `.proxmox-cache/snapshot.json` is missing → notify PREFETCH_MISSING and exit.
2. For each host in the snapshot (filtered by `${var}` if set):
   - Compute current bucket per the rules above.
   - Compare to `memory/proxmox-state.json` previous bucket.
   - Mark transitions: `OK→WATCH`, `WATCH→CRITICAL`, `OK→CRITICAL`, anything → `UNREACHABLE`.
   - Improvements (`CRITICAL→WATCH`, etc.) are noted but not alert-grade — just included in daily digest.
3. Decide notification mode:
   - **Transition detected** (any host moved to a worse bucket OR became unreachable): build a transition alert (top section: which host, which signal, current value, prior value).
   - **It's the daily digest slot** (`HOUR == 9` UTC): build a full snapshot — one line per host with bucket + worst-signal value.
   - **Neither**: silent. Write only the state file + log.
4. Always:
   - Overwrite `memory/proxmox-state.json` with new buckets + timestamps.
   - Append a one-line entry to `memory/topics/proxmox-capacity.md` with the daily history (format: `YYYY-MM-DD HH:MM | pve1=OK(disk 65%) pve2=WATCH(mem 84%) ...`).
5. If notifying: call `./notify` and `./notify-jsonrender` as **single bash invocations**, with the message as a single double-quoted argument. Multi-line content inside double quotes is fine.

   **Required notify call shape — exactly this pattern**:
   ```
   ./notify "🔴 PROXMOX [WATCH→CRITICAL] pve5
   load: 164.89 / 12 vCPU = 13.74x (5-min avg)
   mem: 109.4/135.0 GB (81.0%)
   disk: local-lvm 700.8/891.2 GB (78.6%)
   vms: 52 (49 running)
   runbook: investigate pve5 load source; pve6 has headroom for rebalance"
   ```
   Then immediately:
   ```
   ./notify-jsonrender proxmox-capacity "🔴 PROXMOX [WATCH→CRITICAL] pve5
   ...same body..."
   ```

   **Do NOT**:
   - Write the message to a file first and `cat` it into notify
   - Use `$(...)` command substitution to build the argument
   - Use heredocs (`<<EOF`), pipes, or subshells
   - Call `bash`, `sh`, or any wrapper script to execute notify
   - Stage scripts in `/tmp/` for later execution

   Just call `./notify "...full message text..."` directly. The notify script handles channel fan-out, dedup, and post-run delivery.

## Output format

**Transition alert** (concise, Telegram-friendly):
```
🔴 PROXMOX [WATCH→CRITICAL] pve1
disk: local-lvm 362.4/379.0 GB (95.6%) — was 88.2%
mem: 52.1/64.0 GB (81.4%)
vms: 34 (30 running)
runbook: investigate before pool fills; rebalance to pve5/pve6 has headroom
```

**Daily digest** (one card, all 6 hosts):
```
📊 PROXMOX 09:00 UTC — fleet snapshot
🟢 OK         pve3 — disk 41% · mem 60% · 44 vms (44 run)
🟢 OK         pve4 — disk 38% · mem 55% · 15 vms (15 run)
🟢 OK         pve5 — disk 12% · mem 8% · 0 vms
🟢 OK         pve6 — disk 12% · mem 8% · 0 vms
🟡 WATCH      pve2 — mem 84% · disk 68% · 36 vms
🟡 WATCH      pve1 — disk 88% · mem 81% · 34 vms ⚠ near critical
hetzner traffic (month): pve1 9.6/20 TB, pve3 14.1/20 TB
```

**Silent log** (only `memory/proxmox-state.json` updated, no notify): print `PROXMOX_CAPACITY_OK` to stdout for the workflow capture.

## Sandbox note

Do not call the PVE API or Hetzner Robot API directly from this skill — env-var-based curl auth fails in the GH Actions sandbox. All HTTP fetching lives in `scripts/prefetch-proxmox-capacity.sh`, which runs OUTSIDE the sandbox before Claude starts. If `.proxmox-cache/snapshot.json` is stale or missing, the prefetch script failed or is unconfigured — do not retry; notify the operator with the error class.

## Summary

End with a `## Summary` line listing: hosts checked, transitions detected, notification mode (transition/digest/silent), state file updated.
