# Proxmox Capacity — daily history

One line per run. Format: `YYYY-MM-DD HH:MM | pveN=BUCKET(worst-signal value) ...`

2026-05-17 12:23 | pve1=OK(disk 26%) pve2=OK(mem 43%) pve3=OK(disk 37%) pve4=OK(mem 56%) pve5=CRITICAL(load 13.74x, mem 81%, disk 79%) pve6=OK(mem 47%)
2026-05-17 12:31 | pve1=OK(disk 24%) pve2=OK(mem 40%) pve3=OK(disk 37%) pve4=OK(mem 56%) pve5=CRITICAL(load 7.09x, mem 78%, disk 77%) pve6=OK(disk 43%) — transition OK→CRITICAL on pve5
2026-05-17 13:52 | pve1=OK(disk 24%) pve2=OK(mem 49%) pve3=OK(disk 38%) pve4=OK(mem 66%) pve5=WATCH(load 0.83x, mem 79%, disk 58%) pve6=OK(mem 48%) — improvement CRITICAL→WATCH on pve5 (silent)
2026-05-17 17:06 | pve1=OK(mem 20%) pve2=OK(mem 46%) pve3=OK(mem 29%) pve4=OK(mem 66%) pve5=OK(mem 78%, load 0.34x, disk 58%) pve6=OK(mem 42%) — improvement WATCH→OK on pve5 (silent)
2026-05-17 20:30 | pve1=OK(disk 20%) pve2=OK(mem 15%) pve3=OK(disk 15%) pve4=OK(disk 32%) pve5=OK(mem 78%, disk 58%, load 0.37x) pve6=OK(mem 39%) — no transitions (silent)
2026-05-18 01:34 | pve1=OK(disk 20%) pve2=OK(mem 15%) pve3=OK(disk 15%) pve4=OK(disk 32%) pve5=OK(mem 75%, disk 58%, load 0.34x) pve6=OK(disk 40%) — no transitions (silent)
2026-05-18 05:54 | pve1=OK(disk 20%) pve2=OK(disk 19%) pve3=OK(disk 15%) pve4=OK(disk 30%) pve5=OK(mem 72%, disk 58%, load 0.32x) pve6=OK(disk 39%) — no transitions (silent)
