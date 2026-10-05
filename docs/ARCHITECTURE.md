# Architecture

SCHISM keeps its existing vanilla web interface, Cloudflare Worker, Sites identity, and D1 database. The generated deployment is one ESM Worker with embedded interface and five WebP assets.

## Authoritative simulation

`worker/game.js` owns state reads, action validation, resource changes, settlement, and D1 transactions. Identity comes exclusively from the trusted Sites `oai-authenticated-user-id` header. The browser cannot choose its owner, balances, timestamps, activity outcomes, or city contributions.

`worker/residency.js` owns appearance validation, registration compatibility, elapsed real residency days, civic eligibility, tax accrual, identity flags, activity reservations, and completion rewards. `worker/citylife.js` aggregates completed immutable district commitments and derives public events and their modifiers. `worker/progression.js` owns equipment, jobs, career ranks, shift quotes, and quotas. Stories and shared faction mechanics remain in their existing modules.

A citizen's JSON remains the durable record for appearance, inventory, careers, civic ledgers, and current assignment. Existing saves acquire absent fields without a reset. Read settlement persists through optimistic version checks; completing an assignment atomically saves its effects and journal entry with a transaction guard. A competing read retries the current record. This prevents duplicate rewards and lost incoming trade payments.

Every mutation batch validates the citizen version plus any shared stock, listing, or project guard, then writes all effects and deletes its guards. A failed guard rolls back the complete batch. Seller payment and seller tax accrual share the player-trade transaction and increment the seller's version.

## Shared activity and supply

Migration `0003_slippery_zaran.sql` adds `city_activity` and the market's `delivered` counter. It does not alter existing citizens or backfill data. Prior migrations and metadata remain unchanged.

`city_activity` records the citizen, completion timestamp, completion city day, and production/freight/crime/unrest/relief/patrol contributions. Rows are written in the same transaction as starting a scheduled action. Queries use the `(day, completes)` index, counting only completed rows. No scheduler or foreground player is needed to settle district output: any citizen's next read sees completed contributions.

Common food deliveries derive from cumulative completed production and freight. Market upserts credit only the difference from the recorded delivered counter, maintaining nonnegative stock and preventing repeated state reads from printing supplies. Daily metrics, supplies, projects, and faction influence use the same shared city day.

The current prototype derives event state from the current aggregate thresholds, so collective remedies can lift emergencies. It does not implement historical climate reconstruction, real-time combat, direct player security powers, or an open public account audience. The hosted audience remains owner-private until explicitly changed.

## One-time character reset

Migration `0004_fluffy_selene.sql` adds `maintenance_runs`, an audit and idempotence receipt table. The owner-authorized reset `residency-fresh-start-2026-10-05` completed in production at 16:08:47 UTC on October 5, 2026, removing one existing citizen.

`worker/reset.js` retains the tested maintenance implementation. One atomic D1 batch inserts the unique receipt, deletes player listings/posts/journals, cancels unfinished `city_activity` rows, and deletes citizens. Completed contributions and market/faction/project records remain. A failed deletion rolls back the receipt and all deletions. A repeated or concurrent call returns the existing receipt and preserves newly created characters. Fresh state reads use normal account creation and registration; neither gameplay nor schema migration invokes the reset.

The reset ran through a temporary POST route behind the confirmed owner-private Sites access boundary. That route and the reset helper were removed from the production bundle immediately afterward. There is no reset HTTP endpoint or automatic reset on future deployments.

## Interface and build

`public/residency.js` adds the train intake, composed SVG character scan, appearance editor, character sheet, activity countdowns, Revenue, Registry, security eligibility, and district conditions. `public/residency.css` extends the existing dark terminal and neon visual direction. The original art remains in `public/`, with generation provenance under `art/`.

`scripts/build.mjs` embeds modules and the interface, and copies hosting configuration and Drizzle migrations into `dist`. `scripts/validate-artifact.mjs` imports the generated ESM and requires `default.fetch`. Production publishing uses the Sites archive-backed workflow; checked source is pushed before an exact matching archive is saved and deployed.

Local development uses a Node SQLite D1 adapter and fixed QA identity. Gameplay tests inject time directly into server functions; production request handlers never accept a client timestamp. Browser checks exercise the real built Worker through the local development server.

## Verification

The current suite has 217 assertions: 197 across core survival/trading, narratives/repairs, faction effects, equipment/careers, and residency/economy, plus 20 reset checks. It includes last-stock and player-listing races, duplicate faction actions, concurrent activity-completion reads, fractional tax, seller payment during a shift, gate restrictions, clearance, detention, indigence, offline city output, and legacy saves. Reset checks cover linked-record cleanup, fresh registration, retained shared state, idempotence, concurrent requests, and transaction rollback.

Desktop/mobile browser checks verify intake, name and appearance persistence, all primary screens, profile editing, timed work, deferred pay, assignment reload, and no overflow or page errors. Native WebMCP registration is feature-detected and has not been verified in a supporting browser.
