PROXMOX_CAPACITY_OK

## Summary

- **Hosts checked:** 6 (pve1, pve2, pve3, pve4, pve5, pve6) — all reachable
- **Buckets:** all OK
  - pve1: disk 20%, mem 7%, load 0.06x
  - pve2: disk 19%, mem 15%, load 0.08x
  - pve3: disk 15%, mem 9%, load 0.04x
  - pve4: disk 30%, mem 20%, load 0.10x
  - pve5: mem 72%, disk 58%, load 0.32x (highest stress in fleet but still OK)
  - pve6: disk 39%, mem 37%, load 0.18x
- **Transitions:** none (prior state all OK)
- **Notification mode:** silent (hour=5 UTC, not 09:00 digest slot; no transitions)
- **Files updated:** `memory/proxmox-state.json`, `memory/topics/proxmox-capacity.md`, `memory/logs/2026-05-18.md`
- **Note:** Hetzner section of snapshot was `null` — traffic signal skipped (prefetch may not have Hetzner credentials configured)
