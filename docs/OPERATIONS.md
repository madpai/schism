# Alpha operation and recovery

Production accepts Sites' trusted authenticated identity headers. `SCHISM_OPERATOR_EMAIL` is a Sites runtime secret configured to the Site owner. It enables private report/feedback controls, health, and backup downloads. Optional `SCHISM_MODERATOR_EMAILS` grants report access to a comma-separated list of verified identities; it grants no backup access. No visitor becomes an operator by registering first. Browser action arguments cannot grant a role.

`GET /api/health` is operator-only and checks database access, deployed version, server time, and citizen count. Unexpected API failures write structured, redacted `city_request_failed` logs with a request ID, path, status, and error type; responses carry the same ID. Message bodies, emails, identity tokens, and SQL arguments are excluded. Inspect platform runtime logs when a player reports an ID. Review health and reports during each alpha test day. Automated external alerting is not configured.

API budgets are 90 state reads and 60 actions per verified identity per minute. Operator routes allow four requests per minute. The counter uses one row per identity/kind; it does not append a row per request. `429` includes a 60-second retry header. Existing 650ms action guards, common task quotas, 15-second chat intervals and 40/hour chat limits remain. The interface waits through the action guard before enabling another mutation.

## Backup and restore

The operator's moderation section includes **Download city backup**, backed by `GET /api/backup`. Its D1 batch reads 25 allowlisted game tables in one transaction, including character JSON, shared stock, scheduled contributions, stories, requests and moderation. Export refuses any table above 10,000 rows, rather than silently omitting data. API counters and temporary action guards are excluded. Large cities require a full provider database export. Backups contain private character identities and community records: keep them out of Git and store them privately.

The restore utility accepts only this format, validates table and column names against migrated schema, inserts under a transaction, and checks SQLite integrity. It refuses an existing destination:

```sh
node --experimental-sqlite scripts/restore-city.mjs private-backup.json /private/recovery/city.sqlite
SCHISM_DATA_DIR=/private/recovery SCHISM_PORT=4174 npm run dev
```

The restored database must be named `city.sqlite` in its isolated `SCHISM_DATA_DIR` if you want to open it with the dev server. Reuse the original local session key only in an authorized private recovery drill to retain local browser identities; the key is intentionally not part of a game-data export. Production identities continue to rely on Sites.

The utility does **not** restore over production D1. Before a real hosted recovery, pause writes, preserve the current provider database, verify the export in isolation, and use the hosting provider's supported database import/recovery tools. Code rollback alone does not undo game data or a migration. Production end-to-end recovery has not been rehearsed; it remains a broad-launch gate. A pre-v0.9 local SQLite backup passed integrity checks before migration, and the isolated export/restore tests preserve stories, wages, shared stock, and moderation.

## Local operator and persistent service

The signed local identity adapter strips incoming email headers. Only the exact established QA owner in ignored `.local-data/operator.json` receives the local operator email. This file contains `{ "owner": "local-…" }`, must stay private, and is never shipped. Other browser sessions remain ordinary players. Owner names never confer authorization.

Keep `schism-local.service` active, rebuild before restarting it, and never start another listener on 4173. The same persistent city serves loopback and Tailscale. Never overwrite `.local-data/city.sqlite` or its session key to run tests. Tests and load probes use isolated databases.
