# Architecture

SCHISM keeps its existing vanilla web interface, Cloudflare Worker, Sites identity, and D1 database. The generated deployment is one ESM Worker with embedded interface and 29 WebP assets, including independently cropped painted portrait layers.

## Authoritative simulation

`worker/game.js` owns state reads, action validation, resource changes, settlement, and D1 transactions. Identity comes exclusively from the trusted Sites `oai-authenticated-user-id` header. The browser cannot choose its owner, balances, timestamps, activity outcomes, or city contributions.

`worker/residency.js` owns appearance validation, registration compatibility, elapsed real residency days, civic eligibility, tax accrual, identity flags, activity reservations, and completion rewards. `worker/citylife.js` aggregates completed immutable district commitments and derives public events and their modifiers. `worker/street.js` owns the separate short-task slot, salvage materials, recipes, neural contracts, and casino limits. `worker/progression.js` owns equipment, jobs, career ranks, shift quotes, and quotas. Stories and shared faction mechanics remain in their existing modules.

`worker/life.js` owns action-triggered encounters, persistent contact/decision state, daily free bulletins, prepared crime routes, and earned career cases. `worker/orders.js` owns the supply catalog, escrow orders, partial fulfillment, refunds, and bounded municipal demand. `worker/crises.js` owns fixed emergency targets, scheduled response commitments, phases, deadline outcomes, history, and food/cold modifiers. `game.js` connects their validation and statements to the existing guarded action transaction.

A citizen's JSON remains the durable record for appearance, inventory, careers, civic ledgers, and current assignment. Existing saves acquire absent fields without a reset. Read settlement persists through optimistic version checks; completing either assignment slot atomically saves its effects and journal entry with a transaction guard. A competing read retries the current record. This prevents duplicate rewards and lost incoming trade payments.

Every mutation batch validates the citizen version plus any shared stock, listing, or project guard, then writes all effects and deletes its guards. A failed guard rolls back the complete batch. Seller payment and seller tax accrual share the player-trade transaction and increment the seller's version.

Long assignments store additive inventory/balance changes and selected completion fields. They exclude nested `district`, `finance`, `neighborhood`, and aftermath state from deferred whole-object replacement. A survey, encounter, incoming order delivery, or response made during the shift therefore survives later wage settlement. Short assignments likewise reserve costs immediately and apply additive rewards once at completion. Case state and paid route preparation are applied by `completeDistrictTask`; plans completed in an expired cycle are not revived.

## Shared activity and supply

Migration `0003_slippery_zaran.sql` adds `city_activity` and the market's `delivered` counter. It does not alter existing citizens or backfill data. Prior migrations and metadata remain unchanged.

`city_activity` records the citizen, completion timestamp, completion city day, and production/freight/crime/unrest/relief/patrol contributions. Rows are written in the same transaction as starting a scheduled action. Queries use the `(day, completes)` index, counting only completed rows. No scheduler or foreground player is needed to settle district output: any citizen's next read sees completed contributions.

Common food deliveries derive from cumulative completed production and freight. Market upserts credit only the difference from the recorded delivered counter, maintaining nonnegative stock and preventing repeated state reads from printing supplies. Daily metrics, supplies, projects, and faction influence use the same shared city day.

Existing aggregate events remain. Append-only migration `0006_wealthy_garia.sql` adds `supply_orders`, `district_crises`, and `crisis_actions`, with bounds and completion/owner/deadline indexes. Earlier migrations remain unchanged. No migration resets or replaces a citizen.

Buy orders reserve all requested credits in the buyer's guarded save. Fulfillment atomically decrements remaining order quantity and supplier inventory, pays the supplier with tax, increments the buyer's inventory through SQLite JSON paths, and increments both citizen versions. Order and recipient guards reject last-unit and cancel/fill races. Refunds use only undelivered quantity. Nested material additions preserve unrelated recipient state and later shift rewards. Municipal rows are inserted once per cycle; quantities are bounded from recent contributors and personal deliveries are one unit/one delivery per cycle. Reads never refill orders; old municipal demand closes on cycle rollover.

`district_crises` stores one incident per observed city day, with a target frozen from recent completed contributors (3–12), a five-hour deadline, and an eventual immutable outcome. `crisis_actions` stores completion timestamps plus repair/diversion units. Starting work or a direct response writes its commitment in the same transaction as its reservations; any later read can count it once the timestamp passes, without the actor returning. Warning lasts one hour; unmet demand causes an active penalty; sufficient progress stabilizes it. Criminal contributions can undo stabilization. Deadline resolution stores totals using only commitments finished by the deadline and updates only unresolved rows. Reads also resolve overdue observed incidents and return five past outcomes; never-observed cycles are not fabricated. The last cycle hour applies the stored secured/failed modifier.

Offline survival still uses current weather/heating rather than reconstructing every historical phase. The game does not implement real-time combat, direct player security powers, or an open public account audience. The hosted audience remains owner-private until explicitly changed.

## One-time character reset

Migration `0004_fluffy_selene.sql` adds `maintenance_runs`, an audit and idempotence receipt table. The owner-authorized reset `residency-fresh-start-2026-10-05` completed in production at 16:08:47 UTC on October 5, 2026, removing one existing citizen.

`worker/reset.js` retains the tested maintenance implementation. One atomic D1 batch inserts the unique receipt, deletes player listings/posts/journals, cancels unfinished `city_activity` rows, and deletes citizens. Completed contributions and market/faction/project records remain. A failed deletion rolls back the receipt and all deletions. A repeated or concurrent call returns the existing receipt and preserves newly created characters. Fresh state reads use normal account creation and registration; neither gameplay nor schema migration invokes the reset.

The reset ran through a temporary POST route behind the confirmed owner-private Sites access boundary. That route and the reset helper were removed from the production bundle immediately afterward. There is no reset HTTP endpoint or automatic reset on future deployments.

## Short tasks and neural messages

`errand` is separate from the long `activity` slot. `startQuick` validates energy, materials, state gates, and the cycle quota before reserving costs and a server-owned result. Settlement applies additive rewards; it never replaces a long assignment's state. One guarded batch persists both completion receipts when their deadlines coincide. Quick district commitments use the same immutable `city_activity` table and completion-day rules as long jobs.

Append-only migration `0005_complex_kree.sql` adds indexed `neural_messages`. Posting validates a published channel, 1–320 characters, a 15-second interval, and a 40-per-hour cap. Sender identity comes from the current citizen. Messages and character changes share the guarded action transaction. All player text is escaped for HTML; chat does not execute markup or remote model prompts. The snapshot returns the most recent 100 messages across channels, and the interface shows up to 40 in the selected channel.

Chat polls only on the visible network screen and pauses while typing. Completion refreshes also pause for focused form controls. No WebSocket, push notification, or fake AI conversation is implied. The neural relay's repeatable public/hidden contracts are ordinary authoritative gameplay operations.

Encounter offers are persisted after actual completion of their discovery action. `chooseDistrict` validates the current node, published choice, readiness timestamp, detention/assignment restrictions, and item costs. A citizen version guard prevents concurrent replies from paying twice. Choices store contact memory and the last 40 decisions; replies become ready after a server timestamp. Daily bulletins and response/case quotas reset with the shared cycle, while contacts and story outcomes remain.

## Interface and build

`public/residency.js` adds the train intake, painted layered character portrait, appearance editor, character sheet, activity countdowns, Revenue, Registry, security eligibility, and district conditions. `public/residency.css` extends the existing dark terminal and neon visual direction. New city, job, event, and assignment illustrations extend the existing art in `public/`. A transparent grayscale portrait kit supplies three faces, four hairstyles, and civilian/administrative/security clothing. Runtime SVG filters tint separate skin and hair layers; Shaved omits hair. Portrait components are cropped to individual alpha-preserving WebP files so filtering cannot reveal neighboring atlas cells. Garments render behind the face/neck and again in front through a neckline-specific clip, placing the neck inside the collar instead of behind a flat jacket overlay. Body breadth transforms apply equally to both garment passes. Generation prompts/provenance remain under `art/`.

`scripts/build.mjs` embeds modules and the interface, and copies hosting configuration and Drizzle migrations into `dist`. `scripts/validate-artifact.mjs` imports the generated ESM and requires `default.fetch`. Production publishing uses the Sites archive-backed workflow; checked source is pushed before an exact matching archive is saved and deployed.

`public/life.js` and `life.css` add prioritized next actions, illustrated encounters, crisis controls, case desks, order forms, and stock selection. The build imports the same published encounter/catalog/case configurations for offline seed data and embeds the new Worker modules. Overview, city, exchange, and neighbors poll every 15 seconds only while visible and without a focused input, dialog, or user-expanded details; neural chat retains its ten-second poll. Completion refresh also notices encounter readiness and the crisis deadline. Order form drafts are retained across renders. City emergencies precede an expandable illustrated area gallery on mobile.

Local development uses a Node SQLite D1 adapter, one persistent city file, and separate HMAC-signed browser sessions. The development adapter listens on loopback and an optional explicit Tailscale IP. It never enters the production Worker bundle. Local migrations apply once, and data/session keys remain under ignored `.local-data`. See `docs/LOCAL_HOSTING.md`. Gameplay tests inject time directly into server functions; production request handlers never accept a client timestamp. Browser checks exercise the real built Worker through the local development server.

## Verification

The current suite has 438 assertions: 41 core, 27 narratives, 26 factions, 31 progression, 72 residency/economy, 20 reset, 55 street/network/wardrobe, 83 district checks, and 83 living checks. It includes last-stock and player-listing races, duplicate faction actions, concurrent activity-completion reads, fractional tax, seller payment during a shift, gate restrictions, clearance, detention, indigence, offline city output, and legacy saves. Reset checks cover linked-record cleanup, fresh registration, retained shared state, idempotence, concurrent requests, and transaction rollback.

District checks add current-node/reply validation, zero-energy planning, concurrent encounter choices, route reservation/expiry, funded/partial/refunded orders, supplier and cancellation races with credit/goods conservation, tax, incoming nested materials during deferred wages, own-order visibility, municipal caps, emergency phase/deadline persistence, earned case gates and reserved costs, and a simulated 24-hour return with free shelter/relief/re-entry into work. These use isolated databases and injected server time, never shared playtest characters.

Desktop/mobile browser checks verify intake, name and appearance persistence, all primary screens, profile editing, timed work, deferred pay, assignment reload, and no overflow or page errors. Native WebMCP registration is feature-detected and has not been verified in a supporting browser.

The real-time v0.7 browser playthrough and critique are recorded in `docs/playtests/V0.7.md`; `npm run test:district-browser` creates two ordinary characters in the same city, spends normal resources, and waits 20 real minutes including an actual custodial shift and funded citizen order. The earlier `npm run test:browser` and `test:portraits` remain available. Earned-role visual previews only change client display state; they do not grant institutions or prove a week-long human progression.


## Living systems in v0.8

`worker/living.js` owns housing specifications, one-time old-bunk reform, timestamp-based capped private bills, credit-backed prepaid rent and tax reserves, fire/mending tasks, and an atomic listing-payment SQL statement. `worker/residency.js` reserves new assessed tax during normal additive earnings. Incoming listing payments update finance, tax, credits, and version together. Deferred activity completion excludes these nested state objects, so a new reserve or building membership cannot be overwritten by older wages.

`worker/contacts.js` contains twelve finite continuation templates and four recurring check-ins. Eligibility uses remembered published choices and actual state. `offerContacts` persists the template, instance, and readiness before returning it; a once-cycle marker and two-open limit bound offers. Current-node choices retain the existing citizen-version transaction and timestamp validation. Chosen branches persist on each thread independently of the last-40 journal. No external model runs the contact channel.

Append-only migration `0007_naive_major_mapleleaf.sql` creates `tenant_blocks`, `tenant_members`, `tenant_messages`, `tenant_transfers`, `tenant_repairs`, `recovery_actions`, and `district_news`, with owner/completion/message indexes and progress/transfer bounds. No earlier migration changes, character resets, or schedule jobs are introduced.

`worker/tenants.js` validates membership, capacity, owned stock, withdrawal quota, chat, and repairs. Shared changes guard both the citizen and building version. Member inserts claim capacity once; shelf transactions conserve goods. Assigned repair rows are immutable; lazy resolution starts protection from the latest of six actual completion timestamps. Expiry resets the active round without deleting its historical rows. Offline settlement splits survival exposure at completed protection-window boundaries, clipped to membership time. History retains the last ten completed rounds, exceeding the seven-day offline survival cap. Directory snapshots exclude private member chat.

`worker/aftermath.js` reads resolved incidents, inserts each newspaper row once, and offers fixed bounded recovery contracts. Public contribution attribution excludes covert diversion rows. Recovery reservations use a count guard in the same personal action batch; pressure uses only completed units. Past boiler/freight penalties are capped by type, expire after four following cycles, and disappear early after shared completion. Existing newspaper entries avoid repeated crew queries and are not rewritten after recovery.

`public/home.js`/`.css` provide the compact daily feed, housing/reserve controls, association shelf/channel/repair page, newspaper and recovery board, portraits for contacts, and cosmetic mending. Native SVG overlays show worn clothing while preserving the existing layered portrait. Four original painted contact portraits plus bunkhouse/barrel-fire scenes have generation prompts, hashes, dimensions, and provenance under `art/living-*`. All 29 assets are embedded by the build. Player drafts persist during renders; focused forms and deliberately expanded history pause refreshes, while the default directory does not.

The 83 new living assertions cover ten-day free absences, old-bunk reform versus paid arrears, real sleep/fire deadlines, capped private bills and prepaid/refund settlement races, tax reserves/incoming wages, shared goods/chat privacy, last-ration and last-member races, six actual repair completions, historical protection windows, choice-dependent contact continuation, Registry advocacy, mending, recovery final-slot races, immutable newspaper history, and expiry. `npm run test:balance` advances ordinary registered accounts through isolated seven-day schedules without fixtures. `npm run test:living-browser` uses ordinary characters and real deadlines in the same shared Tailscale city; see `docs/playtests/V0.8.md` for measured evidence and its limits.

## v0.9 alpha boundaries

`worker/neighborhood.js` owns the finite stair story, short-task transitions, shift decision, achieved milestones, and completed repair news. Its state lives under the existing citizen district JSON; immutable `stair_events` make the newspaper reflect the actual task deadline even while a citizen is away. Story tasks share the authoritative short-task slot and quota. Work choices alter deferred deltas rather than replacing deadlines or awarding early wages.

`tenant_requests` uses guarded block versions and remaining quantities. Fulfillment deducts owned inventory and updates shelf, request and transfer record in the same guarded citizen batch. Joining/leaving cannot manufacture request stock. `community_reports`, `community_hidden` and `community_mutes` provide private reports and audited resolutions. All three message feeds exclude hidden records. Tenant reports verify current membership.

`worker/community.js` derives roles only from trusted identity headers and configured runtime email lists. `worker/index.js` applies bounded minute budgets in `request_windows`, operator-only health/export routes, origin/body checks, and redacted failure IDs. The backup reads 25 allowlisted game tables through one D1 batch, excludes temporary guards/counters, and refuses truncation. Restore is restricted to a new isolated SQLite file; live hosted recovery requires provider tooling. Append-only migration 0008 adds the six new tables.

`public/alpha.js` renders the flagship story, optional shift choice, milestones, member requests and private feedback/moderation. The dialog keeps `#dialog-content` intact so report forms do not break later work/repair confirmation. Task/city/story sections and folded member requests reduce mobile scroll; keyed disclosures and unsent drafts remain client-local. No new artwork or portrait composition changes are involved.
