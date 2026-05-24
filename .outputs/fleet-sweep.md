🟡 FLEET SWEEP — 1 WATCH, 0 critical, 0 config fixes

🟡 WATCH
pve5 thin-pool local-lvm 71.3% (70–85% band) — easing from 77.3% earlier today but still above 70%. Prep migration plan; pause new placement on pve5 if it climbs toward 85% CRIT.

✅ Config clean: 336/336 running VMs hermes-named & fully compliant (cpulimit set, onboot=1, scsi0 aio=threads+discard=on, balloon≤memory). 11/11 hosts reachable. 0 corrections queued, 0 repair intents.
