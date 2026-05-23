*Morning Brief — 2026-05-23*

*Focus today*
1. Root-cause cost-report (never dispatched) — why now: enabled but 0 runs since 5/18, Mon slot next
2. pve5 recurring load spikes — why now: 2nd CRITICAL load pile-up in 5d, cause unknown
3. Consolidate stale MEMORY.md — why now: dead template priorities mis-flag every heartbeat

*Since yesterday*
- pve5 hit 12x load5 (CRITICAL), pve7 1.6x, pve3 WATCH @ 20:50 UTC — all recovered to OK by 00:19 (transient process pile-up, not CPU/IO-bound)
- repo-pulse + token-movers both cleared their multi-day staleness breach (ran 5/22) — all daily skills healthy again
- fleet-sweep auto-fixed 2 new pve2 VMs (233/247: cpulimit/onboot/aio); 20:50 sweep confirms 214/214 compliant, fix queue empty
- cost-report still never-dispatched (lone open watch item since 5/18) — likely cron/config

*Running today*
- proxmox-capacity @ 12:00, then every 4h
- fleet-sweep @ 12:30, then every 4h
- token-movers @ 12:00 UTC
- repo-pulse @ 15:00 UTC
- heartbeat @ 14:00, 20:00 UTC
