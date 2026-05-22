🔴 PROXMOX [transitions x3] load spike across fleet
[OK->CRITICAL] pve5 — load 141.51/12 vCPU = 11.79x (5-min) ⚠ severe
  mem 89.1/135.0 GB (66%) · disk local-lvm 582.9/891.2 GB (65%) · 49 vms (44 run)
[OK->CRITICAL] pve7 — load 19.06/12 vCPU = 1.59x (5-min)
  mem 54.5/135.0 GB (40%) · disk 313.8/891.2 GB (35%) · 32 vms (31 run)
[OK->WATCH] pve3 — load 14.90/12 vCPU = 1.24x (5-min)
  mem 64.2/135.0 GB (48%) · disk 350.9/935.7 GB (38%) · 34 vms (31 run)
all three were OK at 17:25 UTC; disk/mem healthy fleet-wide — spike is CPU-only.
runbook: triage pve5 first (11.8x = runaway-process territory); pve3/pve7 mildly over. pve1/pve4/pve6 idle (<0.8x) for VM rebalance.
