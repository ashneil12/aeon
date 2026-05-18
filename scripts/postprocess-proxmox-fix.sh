#!/usr/bin/env bash
# Apply pending Proxmox cpulimit fixes written by the fleet-sweep skill.
#
# Skill writes one JSON file per VM that needs a cpulimit correction:
#   .pending-cpulimit-fix/<slug>-<vmid>.json
#   { "slug": "pve1", "vmid": 209, "ip": "65.21.199.165", "cpulimit": 4,
#     "reason": "drift detected; cores=4 mem=8GB tier expects cpulimit=4" }
#
# This script runs OUTSIDE the Claude sandbox (post-Claude in the workflow),
# reads PROXMOX_API_OPERATOR_TOKENS (which is scoped strictly to VM.Config.CPU
# — verified can't write memory or delete VMs), and applies each fix via the
# PVE API.
#
# After successful apply, the pending file is removed. Failed applies are
# logged and the file is left in place so the next run can retry — but the
# skill will also notice the drift again and re-emit.
set -euo pipefail

PENDING_DIR=".pending-cpulimit-fix"
[ -d "$PENDING_DIR" ] || exit 0

shopt -s nullglob
files=("$PENDING_DIR"/*.json)
[ ${#files[@]} -eq 0 ] && exit 0

if [ -z "${PROXMOX_API_OPERATOR_TOKENS:-}" ]; then
  echo "postprocess-proxmox-fix: PROXMOX_API_OPERATOR_TOKENS not set, leaving ${#files[@]} pending file(s) in place" >&2
  exit 0
fi

APPLIED=0
FAILED=0
SUMMARY=""

for f in "${files[@]}"; do
  slug=$(jq -r '.slug // empty' "$f")
  vmid=$(jq -r '.vmid // empty' "$f")
  ip=$(jq -r '.ip // empty' "$f")
  target=$(jq -r '.cpulimit // empty' "$f")
  reason=$(jq -r '.reason // ""' "$f")

  if [ -z "$slug" ] || [ -z "$vmid" ] || [ -z "$ip" ] || [ -z "$target" ]; then
    echo "  $(basename "$f"): malformed (missing required field), skipping" >&2
    FAILED=$((FAILED+1))
    continue
  fi

  token=$(echo "$PROXMOX_API_OPERATOR_TOKENS" | jq -r --arg s "$slug" '.[$s].token // empty')
  if [ -z "$token" ]; then
    echo "  $slug VMID $vmid: no operator token for host, skipping" >&2
    FAILED=$((FAILED+1))
    continue
  fi

  echo "Applying cpulimit=$target on $slug VMID $vmid ($reason)"
  RESP=$(curl -sk --max-time 10 -X PUT \
    -H "Authorization: PVEAPIToken=$token" \
    -d "cpulimit=$target" \
    "https://$ip:8006/api2/json/nodes/$slug/qemu/$vmid/config" 2>&1) || RESP="curl-failed"

  # PVE returns {"data": null} on success, {"data": null, "message": "..."} on permission failure
  if echo "$RESP" | jq -e '.message' >/dev/null 2>&1; then
    msg=$(echo "$RESP" | jq -r '.message')
    echo "  ✗ FAILED: $msg" >&2
    FAILED=$((FAILED+1))
  else
    echo "  ✓ applied"
    rm -f "$f"
    APPLIED=$((APPLIED+1))
    SUMMARY="${SUMMARY}${slug} VMID ${vmid} → cpulimit=${target}\n"
  fi
done

echo ""
echo "postprocess-proxmox-fix: applied=$APPLIED failed=$FAILED"

# Drop a short report into .pending-notify/ so the operator sees what was auto-applied.
if [ "$APPLIED" -gt 0 ]; then
  mkdir -p .pending-notify
  TS=$(date -u +%s)
  {
    printf "🔧 PROXMOX cpulimit auto-fix\n\n"
    printf "Applied %d cpulimit correction(s) via aeon fleet-sweep:\n\n" "$APPLIED"
    printf "%b" "$SUMMARY"
    printf "\nVMs are throttled hot (no reboot). Existing tenants unaffected.\n"
  } > ".pending-notify/proxmox-fix-${TS}.md"
fi
