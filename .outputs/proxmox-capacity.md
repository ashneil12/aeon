All artifacts updated. The run is complete.

`PROXMOX_CAPACITY_OK`

## Summary
- **Hosts checked:** 7 (pve1–pve7) from a fresh snapshot (`.proxmox-cache/snapshot.json`, generated 2026-05-21T17:19:40Z). Hetzner traffic data null (ongoing condition, no signal).
- **Buckets:** all 7 hosts compute to **OK**. Busiest is pve5 — disk 61%, mem 67%, 5-min load 6.08/12 vCPU = 0.51x, 49 VMs (45 running). No thin-pool anywhere near the 0.95 pve1-style threshold (max is pve5 at 61%).
- **Transitions detected:** none — prior state was all-OK @ 08:26, current is all-OK.
- **Notification mode:** **silent** — hour is 17 UTC (not the 09:00 digest slot) and no host moved to a worse bucket or went unreachable. No `./notify` sent.
- **Files updated:**
  - `memory/proxmox-state.json` — all 7 hosts OK, checked_at 2026-05-21T17:22:32Z
  - `memory/topics/proxmox-capacity.md` — appended daily-history line for 17:22
  - `memory/logs/2026-05-21.md` — appended run log entry
- **Follow-up:** none required. (Note: soul files are empty templates, so neutral tone applied — moot here since no notification was emitted.)
