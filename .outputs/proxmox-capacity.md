PROXMOX_CAPACITY_OK

## Summary
- **Hosts checked:** 7 (pve1–pve7) from `.proxmox-cache/snapshot.json` (generated 2026-05-19T16:41:32Z); all reachable.
- **Bucket computation:** all hosts → `OK`. Largest signals — pve5 mem 65.0% / disk 57.1% / load 0.34×; pve3/pve4 mem ~44%; everything else far below WATCH thresholds. `.hetzner` is null in the snapshot, so the traffic signal was skipped per skill rules.
- **Transitions:** none vs. prior state (all-OK at 13:42 UTC). No pve1>0.95 thin-pool red flag.
- **Notification mode:** silent (no transitions, hour=16 UTC ≠ 09 digest slot). No `./notify` call.
- **Files updated:** `memory/proxmox-state.json` (timestamps bumped to 16:44Z); appended one-line history entry to `memory/topics/proxmox-capacity.md`; appended run log to `memory/logs/2026-05-19.md`.
- **Follow-up:** Hetzner traffic data has been null for two consecutive runs — worth flagging to the prefetch script owner if it persists.
