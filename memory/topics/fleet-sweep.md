# Fleet Sweep — periodic VM-config + host-capacity drift audit

One line per run. Format: `YYYY-MM-DD HH:MM | hosts=N findings=N (C crit, W watch, A auto-fixed, M manual) | mode=sent|silent|dry-run | note`

2026-05-18 (dry-run) | hosts=6 vms=125 findings=1 (0 crit, 0 watch, 0 auto-fixed, 1 manual-INFO) | mode=dry-run | clean fleet — only outlier: pve5 VMID 501 (Herymey) cores=4 but cpulimit=0.5 (free-tier throttle on paid-shaped VM, possibly intentional)
2026-05-18 11:33 (dry-run) | hosts=6 vms=125 findings=0 (0 crit, 0 watch, 0 auto-fixed, 0 manual) | mode=dry-run | FLEET_SWEEP_CLEAN — no drift, no host capacity issues (max thin-pool pve5=58%, max load5/vcpu=0.41, max mem pve5=77.8%); Herymey (pve5/501) still excluded as non-hermes- VM
