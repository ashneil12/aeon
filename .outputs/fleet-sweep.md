`FLEET_SWEEP_CLEAN`

## Summary

- **Hosts swept:** 7 (pve1–pve7, all reachable per snapshot at 2026-05-18T21:45:24Z)
- **VMs swept:** 173 running hermes-* VMs (pve1=10, pve2=15, pve3=19, pve4=18, pve5=46, pve6=31, pve7=34)
- **CRITICAL host findings:** 0
- **WATCH host findings:** 0
- **Auto-fix corrections queued:** 0 (no `.pending-vm-config-fix/` files written)
- **needs_reboot count:** 0
- **Notify mode:** silent (printed `FLEET_SWEEP_CLEAN` to stdout, no `./notify` call)

### Why silent
Every running hermes-* VM already has explicit `cpulimit`, `onboot=1`, `scsi0` with both `aio=threads` and `discard=on`, and `balloon ≤ memory`. The earlier 16:55 load spike on pve5/pve6/pve7 has fully recovered (pve5 load5/vCPU 12.34x → 0.42x). All host capacity signals are well under WATCH thresholds (max thin-pool 55.9% on pve5, max mem 70.4% on pve5, max load 0.42x on pve5). The prior pve7 vmid 744/745/746 scsi0 `aio=threads` rewrites from 16:55 confirmed persisted.

### Files modified
- `memory/topics/fleet-sweep.md` — appended one-line history entry
- `memory/logs/2026-05-18.md` — appended `21:46 — fleet-sweep` block

### Follow-ups
None — fleet is in good shape; next run on schedule.
