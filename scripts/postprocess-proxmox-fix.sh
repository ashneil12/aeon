#!/usr/bin/env bash
# Apply pending Proxmox VM config corrections written by the fleet-sweep skill.
#
# Pending file shape (.pending-vm-config-fix/<slug>-<vmid>.json):
#   {
#     "slug": "pve1",
#     "vmid": 209,
#     "ip": "65.21.199.165",
#     "changes": {
#       "cpulimit": "4",
#       "balloon": "1024",
#       "onboot": "1",
#       "scsi0": "local-lvm:vm-209-disk-0,aio=threads,discard=on,size=30G"
#     },
#     "reason": "..."
#     "needs_reboot": false        # informational only
#   }
#
# This script runs OUTSIDE the Claude sandbox with PROXMOX_API_OPERATOR_TOKENS.
# The operator role is scoped to VM.Config.{CPU,Memory,Disk,Options} only —
# verified blocked from VM.Allocate (destroy), VM.Migrate, VM.PowerMgmt (boot).
#
# Successful applies remove the pending file. Failed applies log + leave the
# file so the next run retries OR the operator can inspect.
set -euo pipefail

PENDING_DIR=".pending-vm-config-fix"
[ -d "$PENDING_DIR" ] || exit 0

shopt -s nullglob
files=("$PENDING_DIR"/*.json)
[ ${#files[@]} -eq 0 ] && exit 0

if [ -z "${PROXMOX_API_OPERATOR_TOKENS:-}" ]; then
  echo "postprocess-proxmox-fix: PROXMOX_API_OPERATOR_TOKENS not set, leaving ${#files[@]} pending file(s)" >&2
  exit 0
fi

APPLIED=0
FAILED=0
NEEDS_REBOOT=0
SUMMARY_APPLIED=""
SUMMARY_REBOOT_PENDING=""

for f in "${files[@]}"; do
  slug=$(jq -r '.slug // empty' "$f")
  vmid=$(jq -r '.vmid // empty' "$f")
  ip=$(jq -r '.ip // empty' "$f")
  reason=$(jq -r '.reason // ""' "$f")
  needs_reboot=$(jq -r '.needs_reboot // false' "$f")
  changes_json=$(jq -c '.changes // {}' "$f")

  if [ -z "$slug" ] || [ -z "$vmid" ] || [ -z "$ip" ] || [ "$changes_json" = "{}" ]; then
    echo "  $(basename "$f"): malformed (missing slug/vmid/ip/changes), skipping" >&2
    FAILED=$((FAILED+1))
    continue
  fi

  token=$(echo "$PROXMOX_API_OPERATOR_TOKENS" | jq -r --arg s "$slug" '.[$s].token // empty')
  if [ -z "$token" ]; then
    echo "  $slug VMID $vmid: no operator token for host, skipping" >&2
    FAILED=$((FAILED+1))
    continue
  fi

  # Build curl --data-urlencode args from changes object.
  # Each (key, value) pair becomes --data-urlencode "key=value".
  curl_args=()
  while IFS=$'\t' read -r key value; do
    curl_args+=("--data-urlencode" "$key=$value")
  done < <(echo "$changes_json" | jq -r 'to_entries[] | [.key, (.value | tostring)] | @tsv')

  changes_preview=$(echo "$changes_json" | jq -r 'to_entries | map("\(.key)=\(.value)") | join(", ")')
  echo "Applying on $slug VMID $vmid: $changes_preview ($reason)"

  RESP=$(curl -sk --max-time 10 -X PUT \
    -H "Authorization: PVEAPIToken=$token" \
    "${curl_args[@]}" \
    "https://$ip:8006/api2/json/nodes/$slug/qemu/$vmid/config" 2>&1) || RESP="curl-failed"

  if echo "$RESP" | jq -e '.message' >/dev/null 2>&1; then
    msg=$(echo "$RESP" | jq -r '.message')
    echo "  ✗ FAILED: $msg" >&2
    FAILED=$((FAILED+1))
  else
    echo "  ✓ applied"
    rm -f "$f"
    APPLIED=$((APPLIED+1))
    line="${slug} VMID ${vmid}: ${changes_preview}  (${reason})"
    SUMMARY_APPLIED="${SUMMARY_APPLIED}${line}\n"
    if [ "$needs_reboot" = "true" ]; then
      NEEDS_REBOOT=$((NEEDS_REBOOT+1))
      SUMMARY_REBOOT_PENDING="${SUMMARY_REBOOT_PENDING}${slug} VMID ${vmid}\n"
    fi
  fi
done

echo ""
echo "postprocess-proxmox-fix: applied=$APPLIED failed=$FAILED needs_reboot=$NEEDS_REBOOT"

# Queue a notification of what got auto-applied so the operator has visibility.
if [ "$APPLIED" -gt 0 ]; then
  mkdir -p .pending-notify
  TS=$(date -u +%s)
  {
    printf "🔧 PROXMOX auto-fix applied — %d correction(s)\n\n" "$APPLIED"
    printf "%b" "$SUMMARY_APPLIED"
    if [ "$NEEDS_REBOOT" -gt 0 ]; then
      printf "\n⚠ Pending reboot (config applied, runtime still old) on %d VM(s):\n" "$NEEDS_REBOOT"
      printf "%b" "$SUMMARY_REBOOT_PENDING"
      printf "Reboot when convenient: qm reboot <vmid>\n"
    fi
  } > ".pending-notify/proxmox-fix-${TS}.md"
fi
