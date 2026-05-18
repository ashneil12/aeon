Dry-run complete. Below is the report — notifications and pending-fix writes are suppressed per `var=dry-run`.

## What the notify call would have looked like

```
🔧 FLEET SWEEP — 1 finding (0 auto-fixed, 1 needs ops)

🔴 CRITICAL
(none)

🟡 WATCH
(none)

✅ AUTO-FIXED
(none — no cpulimit drift detected)

🛠 MANUAL RUNBOOK
pve5 VMID 501 (Herymey): cores=4 but cpulimit=0.5 — paid-shaped CPU allocation throttled to free-tier limit. If intentional throttling, ignore. Otherwise: qm set 501 --cpulimit 4
```

## Per-host capacity snapshot

| Host | Load (5m/vCPU) | Mem | Thin-pool | VMs running | Bucket |
|---|---|---|---|---|---|
| pve1 | 0.05x | 9.7% | 20% | 7 | OK |
| pve2 | 0.08x | 18.0% | 19% | 12 | OK |
| pve3 | 0.10x | 11.6% | 15% | 8 | OK |
| pve4 | 0.36x | 28.2% | 29% | 18 | OK |
| pve5 | 0.37x | 78.1% | 58% | 49 | OK (mem 1.9 pts under 80% WATCH) |
| pve6 | 0.17x | 37.2% | 40% | 31 | OK |

pve5 mem at 78.1% is the closest signal to a WATCH transition, but still under threshold. Worth eyeballing next run.

## VM-level findings (125 running VMs swept)

- **Missing cpulimit**: 0 (auto-fix queue empty)
- **`aio=io_uring`**: 0 (all running VMs use `aio=threads`)
- **Missing `discard=on`**: 0 (all running VMs have it)
- **Balloon > memory**: 0
- **`onboot=0` on tenant**: 0
- **`cpulimit ≠ cores` (excluding intentional free-tier `cores=1, cpulimit=0.5, mem<=1024` pattern)**: **1**
  - `pve5 VMID 501 Herymey` — cores=4, cpulimit=0.5, mem=1024. Surfaced as INFO (skill notes some tenants throttle intentionally).

The remaining ~91 VMs in the raw `cpulimit ≠ cores` set all match the free-tier pattern the skill itself prescribes (`cores=1, cpulimit=0.5, mem<=1024`) — that's the intended config, not drift.

## Summary

- **Hosts swept**: 6 (pve1-pve6, all reachable)
- **VMs swept**: 125 running
- **Findings by severity**: 0 CRITICAL, 0 WATCH, 0 WARN, 1 INFO
- **Auto-fix queue size**: 0 (no `.pending-cpulimit-fix/*.json` written, would have been skipped anyway under dry-run)
- **Manual runbook queue size**: 1 (`pve5 VMID 501`)
- **Notify mode**: dry-run (suppressed)
- **Files written**:
  - `memory/topics/fleet-sweep.md` (created — first run of this skill)
  - `memory/logs/2026-05-18.md` (appended fleet-sweep entry)
- **Follow-up**: confirm pve5 VMID 501 (Herymey) cpulimit is intentional. Watch pve5 mem — 78.1% is 1.9 pts under WATCH threshold.
