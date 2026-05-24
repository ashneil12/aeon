🟡 FLEET SWEEP — 1 WATCH, 0 critical, config clean

pve5 thin-pool local-lvm 77.3% (WATCH band 70-85%) — up from 67.3% ~4.5h ago, +10pts. Prep migration plan; pause new placement on pve5 if it keeps climbing toward 85%.

Config clean: 332/332 running VMs compliant (cpulimit set, onboot=1, scsi0 aio=threads+discard=on, balloon≤memory). 0 drift, 0 fixes queued, 0 repair intents. 11/11 hosts reachable.
