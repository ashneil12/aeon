FLEET_SWEEP_CLEAN

## Summary

- **Hosts swept:** 7 (pve1–pve7), all reachable
- **VMs swept:** 207 running (all hermes-* — zero non-hermes in snapshot)
- **CRITICAL count:** 0
- **WATCH count:** 0
- **Queued-fix count:** 0 (no `.pending-vm-config-fix/*.json` written)
- **Breakdown by drift rule:** cpulimit-missing=0, balloon>memory=0, hermes-onboot≠1=0, scsi0 aio io_uring-or-missing=0, scsi0 missing discard=on=0
- **needs_reboot count:** 0
- **Notify mode:** silent — printed `FLEET_SWEEP_CLEAN` to stdout, no `./notify` call

Worst signals (all well under thresholds): pve5 thin-pool 56.85% (CRIT=85%), pve5 load5/vCPU 0.38 (CRIT=1.3), pve5 mem 63.59% (WATCH=80%). Log appended to `memory/topics/fleet-sweep.md` and `memory/logs/2026-05-19.md`.
