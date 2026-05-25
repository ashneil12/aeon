🟡 FLEET SWEEP — 0 critical, 1 watch, config clean

🟡 WATCH
pve5 thin-pool local-lvm 71.0% (70-85% band) — flat vs prior sweep (71.0%), eased from 77.3% peak 05-24 14:03. Prep migration plan; pause new placement on pve5 only if it re-climbs toward 85% CRIT.

✅ CONFIG CLEAN
362/362 running VMs hermes-named & fully compliant (cpulimit, onboot=1, scsi0 aio=threads+discard=on, balloon≤mem) — 0 drift, 0 corrections queued. All 11 hosts reachable; all other thin-pools <62%, mem <58%, load5/vCPU <0.22x.
