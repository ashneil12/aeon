# HermesOS Discord routing

AEON routes routine outputs by department channel first, bot mention second. This keeps Ash out of raw run noise while preserving escalation.

## Guild

```txt
Operator's Hub: 1441937325121867879
```

## Channels

```txt
augustine-briefs: 1508015918679195718
ops-alerts:       1508015921942233228
dev-review:       1508015925616578591
growth-desk:      1508015929295114252
finance-risk:     1508015932721860689
agent-runs:       1508015936207327282
incidents:        1508015939445198979
ash-approval:     1508015942603636766
```

## Bots

```txt
Augustine:  1475231715298639932  in guild
Anselm:     1475267561867317298  in guild, finance-risk tested
Aquinas:    1475269739168272496  in guild, dev-review tested
Benedict:   1475270170493714504  in guild, ops-alerts tested
Chrysostom: 1475557087239999599  in guild, growth-desk tested
Gabriel:    1472693001431289937  in guild, agent-runs tested
```

Note: Discord automatically creates non-mentionable managed integration roles for bots. AEON does not use those for routing. Department routing uses direct bot/user mentions with explicit `allowed_mentions`; approval routing may still mention the Ash role.

## Invite URLs

All department bots are currently in Operator's Hub. No invite action is pending. If a bot is removed later, regenerate an invite URL from its client ID with scoped view/send/history/embed/attach/react/slash/thread-send permissions.

## Routing implementation

Config:

```txt
config/hermesos-discord-routing.json
```

Script:

```txt
scripts/hermesos-discord-route.sh
```

Workflow:

```txt
.github/workflows/aeon.yml
```

AEON notification delivery now tries `scripts/hermesos-discord-route.sh` before falling back to `DISCORD_WEBHOOK_URL`.

The script:

- routes by `SKILL_NAME` and message content
- posts as the department bot when possible
- uses explicit `allowed_mentions`
- suppresses `@everyone`/implicit parsing
- falls back to the webhook if the bot is not in the guild or cannot send

## Default map

```txt
fleet/proxmox/security/backup -> Benedict -> #ops-alerts
posthog/growth/social         -> Chrysostom -> #growth-desk
finance/cost/revenue/risk     -> Anselm -> #finance-risk
upstream/code/CI/repo          -> Aquinas -> #dev-review
fallback/raw AEON              -> Gabriel -> #agent-runs
approval_required             -> Augustine/Ash role -> #ash-approval
critical/incident             -> Augustine -> #incidents
```
