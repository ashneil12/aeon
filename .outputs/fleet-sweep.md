🟡 FLEET SWEEP — 0 critical, 1 watch, config clean

🟡 WATCH
pve5 thin-pool local-lvm 71.0% (70–85% band) — flat vs 71.3% last sweep, eased from today's 77.3% peak. Only host in band (next: pve1 62%). Prep migration plan; pause new placement on pve5 only if it climbs toward 85% CRIT.

✅ CONFIG CLEAN
344/344 running VMs hermes-named & fully compliant (cpulimit set, onboot=1, scsi0 aio=threads+discard=on, balloon≤memory) — 0 drift, 0 corrections queued. All 11 hosts reachable; max mem pve4=57.2%, max load5/vCPU pve9=0.26x — both well under WATCH.
