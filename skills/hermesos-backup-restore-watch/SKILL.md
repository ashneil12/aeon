---
name: HermesOS Backup Restore Watch
description: Weekly backup/restore audit for Augustine/Benedict: GitHub, Hermes state, AEON, Proxmox cold storage plan, and restore drills. Non-destructive.
var: ""
tags: [ops, backup, disaster-recovery]
---

## Goal

Make HermesOS recoverable if a box dies or an agent workspace is lost.

This skill does not upload secrets or dump private keys. It audits backup coverage and produces a restore checklist.

## Scope

Check and report:

- AEON fork state and recent successful runs
- Hermes runbook/skill references committed or backed up
- GitHub repos with unpushed changes or missing remotes, if visible to AEON
- Proxmox snapshot/backup posture, if metrics are available
- cold-storage bucket plan gaps
- secret inventory gaps without printing secret values
- restore drill status: can a new Hermes agent be pointed at a repo and regain operating context?

## Hard security rule

Never commit or upload raw secrets, SSH private keys, `.env`, token JSON, PostHog keys, Discord tokens, Supabase service keys, wallet material, or Proxmox API token values.

## Output

1. **Backup verdict**: OK / WATCH / ACTION.
2. **What is recoverable today**.
3. **What is not recoverable**.
4. **Secret handling risks**.
5. **Recommended backup architecture**:
   - GitHub repo for non-secret operating memory/runbooks
   - encrypted secret backup separately
   - Proxmox VM backups to cold storage
   - scheduled restore drills
6. **Next exact actions**.

Notify Augustine/Benedict on ACTION or WATCH. Silent on OK.
