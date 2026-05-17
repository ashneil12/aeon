PROXMOX_CAPACITY_OK

## Summary

- **Hosts checked:** 6 (pve1–pve6, all reachable; Hetzner block null in this snapshot)
- **Buckets:** pve1/pve2/pve3/pve4/pve6 = OK · pve5 = WATCH (load 0.83x just over 0.80 threshold; mem 79%, disk 58%)
- **Transitions:** pve5 CRITICAL → WATCH (improvement, not alert-grade). No deteriorations.
- **No thin-pool ≥ 0.95** — pve1-style failure scenario not triggered (highest is pve5 local-lvm at 58%).
- **Notification mode:** silent (hour=13 UTC, not the 09:00 digest slot; no deterioration transitions).
- **Files updated:** `memory/proxmox-state.json` (pve5 OK→WATCH... actually CRITICAL→WATCH; others timestamps refreshed), `memory/topics/proxmox-capacity.md` (history line appended), `memory/logs/2026-05-17.md` (log entry appended).
