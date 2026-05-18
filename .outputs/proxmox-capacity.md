🔴 PROXMOX [OK→CRITICAL] pve5 + pve6 + pve7 — fleet-wide load spike

pve5: load 148.69 / 12 vCPU = 12.39x (5-min avg) — was 0.32x at 05:54
  mem: 97.2/135.0 GB (72.0%)
  disk: local-lvm 531.3/891.2 GB (59.6%)
  vms: 50 (47 running)

pve6: load 34.42 / 12 vCPU = 2.87x (5-min avg) — was OK (no prior load number)
  mem: 51.9/135.0 GB (38.4%)
  disk: local-lvm 372.4/891.2 GB (41.8%)
  vms: 36 (31 running)

pve7: load 37.72 / 12 vCPU = 3.14x (5-min avg) — UNKNOWN→CRITICAL (new host)
  mem: 66.4/135.0 GB (49.2%)
  disk: local-lvm 306.7/891.2 GB (34.4%)
  vms: 36 (34 running)

all OK: pve1 (load 0.57x, disk 26%) · pve2 (0.48x, 21%) · pve3 (0.07x, 15%) · pve4 (0.25x, 27%)

runbook: 3 hosts CRITICAL on load only — mem/disk fine on all. Suspect shared trigger (cron storm, mass migration, backup job hitting multiple hosts at once). pve5 has been flapping since 2026-05-17 (OK→CRITICAL→WATCH→OK→CRITICAL). Investigate load source on pve5 first, then check whether pve6/pve7 share the same workload pattern. pve1/pve3/pve4 have headroom if rebalance needed.
