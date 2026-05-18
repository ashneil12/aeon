#!/usr/bin/env bash
# Pre-fetch Proxmox + Hetzner Robot data OUTSIDE the Claude sandbox.
#
# Called by the workflow before the proxmox-capacity skill runs.
# Reads:
#   PROXMOX_API_TOKENS  JSON: {"pve1": {"ip": "65.21.199.165", "token": "user@pve!tok=UUID"}, ...}
#   HETZNER_ROBOT_USER  Hetzner Robot username (#ws+... or your robot email)
#   HETZNER_ROBOT_PASS  Hetzner Robot password
#
# Writes .proxmox-cache/snapshot.json with the shape documented in
# skills/proxmox-capacity/SKILL.md.
#
# If PROXMOX_API_TOKENS is unset, this script no-ops cleanly (exit 0) so the
# skill can detect PREFETCH_MISSING and notify.

set -euo pipefail

SKILL="${1:-}"
VAR="${2:-}"

# Run for any skill that consumes the Proxmox snapshot.
case "$SKILL" in
  proxmox-capacity|fleet-sweep) ;;
  *) exit 0 ;;
esac

if [ -z "${PROXMOX_API_TOKENS:-}" ]; then
  echo "proxmox-capacity prefetch: PROXMOX_API_TOKENS not set, skipping" >&2
  exit 0
fi

CACHE_DIR=".proxmox-cache"
mkdir -p "$CACHE_DIR"
SNAPSHOT="$CACHE_DIR/snapshot.json"

NOW=$(date -u +%FT%TZ)
echo "{\"generated_at\":\"$NOW\",\"hosts\":{},\"hetzner\":null}" > "$SNAPSHOT"

# --- PVE per-host fetch ----------------------------------------------------
HOSTS=$(echo "$PROXMOX_API_TOKENS" | jq -r 'keys[]')

for SLUG in $HOSTS; do
  IP=$(echo "$PROXMOX_API_TOKENS" | jq -r --arg s "$SLUG" '.[$s].ip // ""')
  TOKEN=$(echo "$PROXMOX_API_TOKENS" | jq -r --arg s "$SLUG" '.[$s].token // ""')

  if [ -z "$IP" ] || [ -z "$TOKEN" ]; then
    echo "  $SLUG: missing ip or token, marking unreachable" >&2
    jq --arg s "$SLUG" --arg ip "$IP" '.hosts[$s] = {"reachable": false, "ip": $ip, "error": "no_config"}' \
      "$SNAPSHOT" > "$SNAPSHOT.tmp" && mv "$SNAPSHOT.tmp" "$SNAPSHOT"
    continue
  fi

  BASE="https://$IP:8006/api2/json"
  AUTH_HDR="Authorization: PVEAPIToken=$TOKEN"

  # Status (CPU, mem, loadavg)
  STATUS=$(curl -sk --max-time 10 -H "$AUTH_HDR" "$BASE/nodes/$SLUG/status" 2>/dev/null \
    | jq '.data // null' 2>/dev/null || echo "null")

  if [ "$STATUS" = "null" ]; then
    echo "  $SLUG: API unreachable" >&2
    jq --arg s "$SLUG" --arg ip "$IP" '.hosts[$s] = {"reachable": false, "ip": $ip, "error": "api_unreachable"}' \
      "$SNAPSHOT" > "$SNAPSHOT.tmp" && mv "$SNAPSHOT.tmp" "$SNAPSHOT"
    continue
  fi

  # Storage list (with status — includes used/avail for thin-pools)
  STORAGE=$(curl -sk --max-time 10 -H "$AUTH_HDR" "$BASE/nodes/$SLUG/storage" 2>/dev/null \
    | jq '.data // []' 2>/dev/null || echo "[]")

  # VM list (status field tells us running vs stopped)
  VMS=$(curl -sk --max-time 10 -H "$AUTH_HDR" "$BASE/nodes/$SLUG/qemu" 2>/dev/null \
    | jq '.data // []' 2>/dev/null || echo "[]")

  # Per-VM config fetch (only needed by fleet-sweep skill, but lightweight enough to always do).
  # Adds ~5-10s for a heavily-populated host. Sequential is fine; PVE API isn't rate-limited at this volume.
  VM_CONFIGS="[]"
  for VMID in $(echo "$VMS" | jq -r 'map(select(.status == "running")) | .[].vmid'); do
    CFG=$(curl -sk --max-time 5 -H "$AUTH_HDR" "$BASE/nodes/$SLUG/qemu/$VMID/config" 2>/dev/null \
      | jq --argjson vmid "$VMID" '.data // null | if . == null then null else . + {vmid: $vmid} end' 2>/dev/null)
    if [ -n "$CFG" ] && [ "$CFG" != "null" ]; then
      VM_CONFIGS=$(echo "$VM_CONFIGS" | jq --argjson c "$CFG" '. + [$c]')
    fi
  done

  HOST_ENTRY=$(jq -n \
    --arg ip "$IP" \
    --argjson status "$STATUS" \
    --argjson storage "$STORAGE" \
    --argjson vms "$VMS" \
    --argjson vm_configs "$VM_CONFIGS" \
    '{
      reachable: true,
      ip: $ip,
      status: $status,
      storage: $storage,
      vm_total: ($vms | length),
      vm_running: ($vms | map(select(.status == "running")) | length),
      vm_stopped: ($vms | map(select(.status == "stopped")) | length),
      vm_configs: $vm_configs
    }')

  jq --arg s "$SLUG" --argjson e "$HOST_ENTRY" '.hosts[$s] = $e' \
    "$SNAPSHOT" > "$SNAPSHOT.tmp" && mv "$SNAPSHOT.tmp" "$SNAPSHOT"

  echo "  $SLUG: fetched" >&2
done

# --- Hetzner Robot fetch ---------------------------------------------------
if [ -n "${HETZNER_ROBOT_USER:-}" ] && [ -n "${HETZNER_ROBOT_PASS:-}" ]; then
  ROBOT_BASE="https://robot-ws.your-server.de"
  AUTH="$HETZNER_ROBOT_USER:$HETZNER_ROBOT_PASS"

  SERVERS=$(curl -s --max-time 10 -u "$AUTH" "$ROBOT_BASE/server" 2>/dev/null \
    | jq 'if type == "array" then map(.server) else [] end' 2>/dev/null || echo "[]")

  # Traffic for current month — Robot API uses YYYY-MM-01..YYYY-MM-31 range.
  # The /traffic endpoint requires a POST with form-encoded server IPs.
  MONTH_FROM=$(date -u +%Y-%m-01)
  MONTH_TO=$(date -u +%Y-%m-%d)
  SERVER_IPS=$(echo "$SERVERS" | jq -r 'map(.server_ip) | join(",")')

  TRAFFIC="{}"
  if [ -n "$SERVER_IPS" ] && [ "$SERVER_IPS" != "null" ]; then
    TRAFFIC_RAW=$(curl -s --max-time 10 -u "$AUTH" \
      -d "from=$MONTH_FROM" -d "to=$MONTH_TO" -d "type=month" \
      -d "ip=$SERVER_IPS" \
      "$ROBOT_BASE/traffic" 2>/dev/null || echo "{}")
    # Best-effort parse; the shape varies. Store raw for the skill to interpret.
    TRAFFIC="$TRAFFIC_RAW"
  fi

  jq --argjson s "$SERVERS" --argjson t "$TRAFFIC" \
    '.hetzner = {servers: $s, traffic_raw: $t, month_from: "'"$MONTH_FROM"'", month_to: "'"$MONTH_TO"'"}' \
    "$SNAPSHOT" > "$SNAPSHOT.tmp" && mv "$SNAPSHOT.tmp" "$SNAPSHOT"

  echo "  hetzner: fetched ${#SERVER_IPS} chars of IPs" >&2
fi

echo "proxmox-capacity prefetch: wrote $SNAPSHOT"
