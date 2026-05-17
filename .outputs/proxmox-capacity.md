PROXMOX_CAPACITY_OK

## Summary
- **Hosts checked:** 6 (pve1–pve6); all reachable. Hetzner traffic block is null in this snapshot, so that signal was skipped.
- **Transitions detected:** pve5 WATCH→OK (improvement only — not alert-grade per spec). No worse-bucket transitions, no unreachable hosts. No thin-pool exceeds the 0.95 special-case threshold (max is pve5 local-lvm at 58.0%).
- **Notification mode:** silent (no worsening transitions; hour 17 UTC, not the 09 digest slot). No `./notify` or `./notify-jsonrender` calls made.
- **State file updated:** `memory/proxmox-state.json` overwritten with all 6 hosts at OK / `checked_at` 2026-05-17T17:06:42Z.
- **History appended:** one line added to `memory/topics/proxmox-capacity.md` for the 17:06 run.
- **Log entry:** added to `memory/logs/2026-05-17.md`.
