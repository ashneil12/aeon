#!/usr/bin/env bash
# Route an AEON notification to the right HermesOS Discord bot/channel.
# Usage: SKILL_NAME=fleet-sweep scripts/hermesos-discord-route.sh "message"
set -euo pipefail

MSG="${1:-}"
CONFIG="${HERMESOS_DISCORD_ROUTING_CONFIG:-config/hermesos-discord-routing.json}"
SKILL="${SKILL_NAME:-${AEON_SKILL_NAME:-}}"

if [ -z "$MSG" ]; then
  echo "discord-route: empty message" >&2
  exit 1
fi
if [ ! -f "$CONFIG" ]; then
  echo "discord-route: missing config $CONFIG" >&2
  exit 1
fi

ROUTE_JSON=$(jq -n --arg skill "$SKILL" --arg msg "$MSG" --slurpfile cfg "$CONFIG" '
  def lc: ascii_downcase;
  def has_any($terms): any($terms[]; . as $t | ((($skill|lc) | contains($t|lc)) or (($msg|lc) | contains($t|lc))));
  ($cfg[0]) as $c |
  if (($msg|lc) | test("approval_required: *true|approval required|ash approval|requires approval")) then
    {kind:"approval", owner:$c.approval.owner, channel_key:$c.approval.channel, role_key:($c.approval.mention_role // null), mention:true}
  elif (($msg|lc) | test("critical|sev1|incident|outage|security breach")) then
    {kind:"critical", owner:$c.critical.owner, channel_key:$c.critical.channel, role_key:null, mention:true}
  else
    (($c.routes[] | select(has_any(.match))) // $c.fallback) as $r |
    {kind:"normal", owner:$r.owner, channel_key:$r.channel, role_key:null, mention:(($msg|lc) | test("action|needs owner|blocked|failed"))}
  end
  | .channel_id = $c.channels[.channel_key]
  | .bot_id = $c.bots[.owner].id
  | .bot_env = $c.bots[.owner].env
  | .role_id = (if .role_key then $c.roles[.role_key] else null end)
')

OWNER=$(echo "$ROUTE_JSON" | jq -r '.owner')
CHANNEL_ID=$(echo "$ROUTE_JSON" | jq -r '.channel_id')
BOT_ENV=$(echo "$ROUTE_JSON" | jq -r '.bot_env')
BOT_ID=$(echo "$ROUTE_JSON" | jq -r '.bot_id')
ROLE_ID=$(echo "$ROUTE_JSON" | jq -r '.role_id // empty')
MENTION=$(echo "$ROUTE_JSON" | jq -r '.mention')
TOKEN="${!BOT_ENV:-}"

CONTENT="$MSG"
MENTION_USERS='[]'
MENTION_ROLES='[]'
if [ "$MENTION" = "true" ]; then
  if [ -n "$ROLE_ID" ]; then
    CONTENT="<@&${ROLE_ID}> ${CONTENT}"
    MENTION_ROLES=$(jq -nc --arg id "$ROLE_ID" '[$id]')
  elif [ -n "$BOT_ID" ]; then
    CONTENT="<@${BOT_ID}> ${CONTENT}"
    MENTION_USERS=$(jq -nc --arg id "$BOT_ID" '[$id]')
  fi
fi

PAYLOAD=$(jq -n \
  --arg content "$CONTENT" \
  --argjson users "$MENTION_USERS" \
  --argjson roles "$MENTION_ROLES" \
  '{content:$content, allowed_mentions:{parse:[], users:$users, roles:$roles}}')

# Prefer the department bot when it is in the guild and can post to the channel.
if [ -n "$TOKEN" ] && [ -n "$CHANNEL_ID" ]; then
  HTTP=$(curl -sS -o /tmp/discord-route-response.json -w "%{http_code}" \
    -X POST "https://discord.com/api/v10/channels/${CHANNEL_ID}/messages" \
    -H "Authorization: Bot ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" || echo 000)
  if [ "$HTTP" = "200" ]; then
    echo "discord-route: sent via ${OWNER} to ${CHANNEL_ID}"
    exit 0
  fi
  echo "discord-route: bot ${OWNER} could not send to ${CHANNEL_ID} (http=$HTTP), falling back" >&2
fi

# Fallback to existing AEON webhook, suppressing all mentions unless explicitly configured upstream.
if [ -n "${DISCORD_WEBHOOK_URL:-}" ]; then
  curl -sf -X POST "$DISCORD_WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg text "$MSG" '{content:$text, allowed_mentions:{parse:[]}}')" >/dev/null
  echo "discord-route: sent via webhook fallback"
  exit 0
fi

echo "discord-route: no usable Discord token or webhook" >&2
exit 1
