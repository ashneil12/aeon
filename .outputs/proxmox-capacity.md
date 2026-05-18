PROXMOX_CAPACITY_OK

## Summary

- **Hosts checked:** 7 (pve1–pve7), all reachable.
- **Buckets:** all 7 hosts → OK. Worst signals: pve5 mem 70.7%, pve5 disk 56.9%, pve5 load 0.53x/vCPU — all well under WATCH thresholds. No thin-pool near the 0.95 special-case alarm (pve5 highest at 56.9%).
- **Transitions:** 3 improvements (pve5, pve6, pve7 all CRITICAL→OK) — the 16:54 load spike has cleared. Improvements are not alert-grade per skill rules.
- **Notification mode:** silent (no deterioration, hour=20 UTC ≠ 09:00 digest slot). No `./notify` or `./notify-jsonrender` call.
- **Files updated:** `memory/proxmox-state.json` (all 7 → OK @ 20:23:00Z); appended history line to `memory/topics/proxmox-capacity.md`; appended run log to `memory/logs/2026-05-18.md`.
- **Caveat:** snapshot's `hetzner` section is null, so the traffic signal was skipped (consistent with earlier runs today). No follow-up needed unless the Hetzner Robot prefetch is expected to populate it.
