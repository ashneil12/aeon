🔧 FLEET SWEEP — 3 CRITICAL, 3 queued fixes

🔴 CRITICAL — operator action required
pve5 load5 148.06 / 12 vCPU = 12.3x — investigate top consumers: ssh root@78.46.44.246 'top -bn1'. Consider pausing placement.
pve6 load5 33.67 / 12 vCPU = 2.8x — investigate top consumers: ssh root@46.4.68.151 'top -bn1'.
pve7 load5 37.58 / 12 vCPU = 3.1x — investigate top consumers: ssh root@37.27.55.81 'top -bn1'.

✅ AUTO-FIX QUEUED (apply on next postprocess run)
pve7 VMID 744 scsi0 aio=threads (was missing — defaulted io_uring) ⟳ needs reboot
pve7 VMID 745 scsi0 aio=threads (was missing — defaulted io_uring) ⟳ needs reboot
pve7 VMID 746 scsi0 aio=threads (was missing — defaulted io_uring) ⟳ needs reboot
