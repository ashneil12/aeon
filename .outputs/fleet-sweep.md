🔧 FLEET SWEEP — 4 drift VMs identified, AUTO-FIX BLOCKED by infra gap (0 host issues)

⚠ AUTO-FIX BLOCKED — snapshot lacks host IPs (.pending-vm-config-fix schema requires .ip; prefetch-proxmox-capacity.sh has it but drops it). Fix: add IP to host entry in prefetch. Skipping queue write this run to avoid garbage pending files.

🟢 DRIFT IDENTIFIED (would queue once infra fixed)
pve7 VMID 727 cpulimit=2 + onboot=1 (was unset, was 0)
pve7 VMID 744 cpulimit=2 + onboot=1 (was unset, was 0)
pve7 VMID 745 cpulimit=2 + onboot=1 (was unset, was 0)
pve7 VMID 746 cpulimit=2 + onboot=1 (was unset, was 0)
All hot-fixes, needs_reboot=0. All share name UUID 2e132799…

🟢 CAPACITY CLEAN — 7 hosts swept, 157 running VMs. Worst signals: pve5 mem 78% (WATCH@80, ~2pp under), pve5 thin-pool 58%, pve4 load5/vCPU 0.47 (CRIT@1.3). All hosts reachable on PVE 9.1.14.
