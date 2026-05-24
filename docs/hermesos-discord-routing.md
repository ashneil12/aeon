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
Augustine:  1475231715298639932  in guild, role 1508116223651741828 assigned
Anselm:     1475267561867317298  in guild, role 1508116229406068948 assigned, finance-risk tested
Aquinas:    1475269739168272496  in guild, role 1508116226696548476 assigned, dev-review tested
Benedict:   1475270170493714504  token stored, role 1508116232895856852 created, invite needed
Chrysostom: 1475557087239999599  token stored, role 1508116235731075172 created, invite needed
Gabriel:    1472693001431289937  token stored, role 1508116238583337084 created, invite needed
```

## Invite URLs

Use these if a bot is not yet in Operator's Hub. Permissions are scoped for view/send/history/embed/attach/react/slash/thread-send, not admin.

```txt
Benedict:
https://discord.com/oauth2/authorize?client_id=1475270170493714504&permissions=277025508416&scope=bot+applications.commands&guild_id=1441937325121867879&disable_guild_select=true

Chrysostom:
https://discord.com/oauth2/authorize?client_id=1475557087239999599&permissions=277025508416&scope=bot+applications.commands&guild_id=1441937325121867879&disable_guild_select=true

Gabriel:
https://discord.com/oauth2/authorize?client_id=1472693001431289937&permissions=277025508416&scope=bot+applications.commands&guild_id=1441937325121867879&disable_guild_select=true
```

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
