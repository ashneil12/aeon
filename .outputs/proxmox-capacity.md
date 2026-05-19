PROXMOX_CAPACITY_OK

## Summary

- **Hosts checked:** 7 (pve1, pve2, pve3, pve4, pve5, pve6, pve7) from `.proxmox-cache/snapshot.json` (generated 2026-05-19T20:17:20Z).
- **Buckets:** all OK. Worst per-host signals: pve5 mem 63.7% / disk 56.8% / load 0.44× (still well under WATCH=70%/80%/0.8). No thin-pool above the 0.95 special-case threshold (max 56.8% on pve5).
- **Hetzner:** snapshot's `hetzner` block is `null` → traffic signal skipped (same as prior runs today).
- **Transitions:** none vs. prior state (all-OK at 16:44 UTC). UTC hour 20 ≠ 09 digest slot → **silent mode**, no `./notify` / `./notify-jsonrender` call.
- **Files updated:**
  - `memory/proxmox-state.json` — refreshed `checked_at` timestamps for all 7 hosts.
  - `memory/topics/proxmox-capacity.md` — appended 2026-05-19 20:20 history line.
  - `memory/logs/2026-05-19.md` — appended run entry.
- **Follow-up:** Hetzner traffic block has been null all day; prefetch script may have lost its Robot API auth. Worth checking `scripts/prefetch-proxmox-capacity.sh` and the relevant secrets, but not alert-grade (Proxmox API path is healthy).
