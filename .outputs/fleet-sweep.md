🔧 FLEET SWEEP — 2 CRITICAL, 0 queued fixes

🔴 CRITICAL — operator action required
pve5 load 12.1x vCPU (145/12; 1-min 180=15x & RISING; cpu 42%, iowait <1% → runnable/D-state pile-up, not CPU/IO bound) — investigate: ssh root@78.46.44.246 'top -bn1'; consider pausing placement (UPDATE proxmox_hosts SET status='maintenance' WHERE id='pve5')
pve7 load 1.71x vCPU (20.5/12; 1-min 2.67x, rising) — investigate: ssh root@37.27.55.81 'top -bn1'

🟡 WATCH
pve3 load 1.28x vCPU — just under CRIT but trending DOWN (15-min was 1.71x); watch only, no action

Config CLEAN: 214/214 VMs compliant, 0 drift, 0 fixes queued. Thin-pool & RAM under all WATCH (max pve5 thin 65%, mem 66%). 7/7 hosts reachable.
