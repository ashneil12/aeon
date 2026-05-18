`FLEET_SWEEP_CLEAN`

## Summary

- **Hosts swept:** 6 (pve1, pve2, pve3, pve4, pve5, pve6 — all reachable)
- **VMs swept:** 125 running
- **CRITICAL host findings:** 0
- **WATCH host findings:** 0 (closest: pve5 mem 77.8%, ~2pp under the 80% WATCH threshold)
- **Queued fixes:** 0 (no `.pending-vm-config-fix/*.json` written — dry-run + nothing to queue anyway)
  - Breakdown — no-cpulimit: 0, balloon>memory: 0, hermes- onboot≠1: 0, aio=io_uring: 0, scsi0 missing discard: 0
- **needs_reboot:** 0
- **Notify mode:** dry-run (would-be: silent — `FLEET_SWEEP_CLEAN` printed to stdout; no `./notify` call)
- **Files modified:** `memory/topics/fleet-sweep.md` (appended one-line history entry), `memory/logs/2026-05-18.md` (appended 11:33 run note)
- **Follow-up:** none — the lone non-conforming VM (pve5/501 "Herymey", cores=4 cpulimit=0.5) is excluded by the "non-hermes-" special-case skip and was already noted in earlier dry-run; not actionable by Aeon.
