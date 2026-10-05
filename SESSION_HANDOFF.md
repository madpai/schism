# SCHISM session handoff — v0.5 residency update

Prepared October 5, 2026. This handoff describes the checked v0.5 source. The live Site and GitHub must be synchronized before the session is considered complete; use native Sites deployment status for the exact saved version/deployment IDs.

## Locations and established workflow

- Live game: https://schism.williamschultz903.chatgpt.site
- GitHub: https://github.com/madpai/schism — private repository, account `madpai`, default branch `main`.
- GitHub checkout: `/home/commander/schism`.
- Sites checkout: `/home/commander/ashfall` (historical directory name; the product is SCHISM).
- Existing project: `appgprj_6ac325aa83348191bf144ff590881fd4`.
- Hosting stays owner-private; current audience was read and preserved. Do not make the game public without a request.
- Prior deployed source, before this update: `1179e8a19c44e392af032fc5dcf11073de274198`.
- Prior deployment: `appgdep_6ac34ebe3c588191a613a21bab89c4b8`.
- No credentials belong in source, this file, arguments, or handoffs. Obtain fresh Sites credentials and pass them through workflow stdin.

For hosted edits, use the Sites building and hosting skills. Open this existing project with its exact ID and the bundled source-opening workflow **before editing** its Sites checkout, retaining the opening result. Publish the checked source using the archive-backed workflow and verify native terminal deployment status. Synchronize GitHub by fetching the local Sites branch, merging into GitHub `main`, and using an ordinary non-force push. Preserve both distinct repository histories and any remote changes.

## User direction

SCHISM is a persistent dystopian city RPG about ordinary people, with the asynchronous multiplayer depth of games such as Torn and Arclight City. Citizens arrive by import train into an already-running city, start neutral and broke, and choose lawful work/administration, trade, or crime. Security is a much later Order career.

The user explicitly requested taxes, identity flags that block factory access, debt repayment and time/energy spent obtaining administrative clearance, a pull toward crime/Chaos, and collective events driven by what players do. They also requested continued publication, current documentation/handoffs, and a nice GitHub README featuring original artwork.

Keep the established Canon/Wound occult setting, rainy neon noir artwork, near-black/cyan/crimson palette, and legacy terminal typography. Existing assets are suitable. Preserve the current vanilla stack and established citizens.

## Shipped source behavior

- ChatGPT sign-in owns one durable citizen. Unregistered accounts see character intake and an arriving train window rather than a generated playable character. Name, gender, six skin tones, six hair colors, five hairstyles, and three builds are validated and saved. Composed native SVG scans appear throughout the character UI. Appearance is cosmetic and editable.
- New characters have 0 credits, neutral alignment/trust, worn clothing/boots/implant, and one six-hour cycle before the first rent bill. Registration cannot be replayed. Old citizens bypass new intake and retain possessions, institutions, careers, stories, and their original `joined` date.
- One common city hour is 15 real minutes; common city days remain six real hours from the existing epoch. Displayed `daysInCity` counts complete real 24-hour days since registration. Personal actions never fast-forward time.
- Jobs, rest, crime, organizing, clinic, shops, official/security duty, event work, and registry clearance are persistent timed assignments. Energy, fees, and consumed stock are reserved. Positive pay, XP, and benefits wait for completion. Shopping, eating, rent, taxes, equipment, and direct trade remain possible during an assignment. Completion and its journal entry are atomic and exactly once under concurrent reads.
- Employment/official/security/event work is capped at eight city hours per starting shared day. Sleep once per starting day, crime three attempts/day, and shop sessions twice/day. Work quotas use completion day. Career ranks slowed to 24/80/180 XP; three-shift quota reduced from 8 CR to 3 CR.
- Hunger, cold, energy, heat, rent, and taxes settle in elapsed shared time. Working has higher exposure; private housing and insulation protect idle/sleep warmth. Passive health has a floor of 10. Four unpaid rent bills evict; arrears stop at four bills. Daily nontradeable relief restores fullness/warmth and enough health/energy to recover from being broke.
- Earned-income tax is 12%, manually paid. Whole-credit assessments carry fractional hundredths across wages, quotas, rent income, broker sales, player sales, and reported story wages. Seller tax is part of the atomic player-trade transaction. Unreported crime/Wound/story money bypasses Revenue.
- Missing a tax deadline flags the ID. Unresolved arrest also flags it. Factory jobs, emergency factory/freight work, licensed shops, administration, and security require a cleared ID. Public custodial work and communal boiler work remain debt-recovery options after detention.
- Paying tax or serving a sentence alone does not clear a hold. Registry review requires no tax debt, heat at most 20, and no active sentence; costs 2 CR, 6 energy, and 15 real minutes. With less than 2 CR, an indigence appeal costs no fee but takes 14 energy and 30 minutes. Clearance happens on completion.
- Crime grants underground XP/titles and private Chaos alignment. Arrest imposes a fine, injury, lost trust, an ID hold, and two city hours of detention after the operation. Success is untaxed and can be more lucrative than basic work.
- Shop license: 1 real residency day, 10 trust, cleared ID, 90 CR. Administration: 2 real days, 25 trust, 80 civic XP, low heat, cleared ID, 60 CR. Security: 7 real days, 30 shifts, 60 trust, 180 civic XP, Order +40, heat at most 10, cleared ID. Existing institutions are retained.
- New heated apartment: 180-CR deposit, 32-CR cycle rent, 2 real days and 20 trust, currently living in a private room.
- Collective metrics: production, freight, crime, unrest, relief, and patrols. Completed commitments influence everybody even when the starting player has not returned. Production shortfalls and neglected trains raise food prices; production failure cuts wages. Restored output and unloaded freight deliver shared stock exactly once. Criminal pressure triggers lockdowns. Organizing earns a shared wage increase. Boilers reduce cold. Security patrols counter lockdowns.
- Five existing branching stories, Order/Chaos effects, equipment/loadouts, all twelve jobs, direct player trades, noticeboard, unions, leases, and the shared thermal-lattice project remain.

This is asynchronous multiplayer, with no real-time movement/combat or direct security powers over another player's character. No public sharing or standalone password-auth system was added. Offline weather/heating settlement uses the current district modifiers rather than reconstructing every historical event.

## Files and persistence

- `worker/game.js`: authoritative actions, shared-time survival, billing, income, guarded settlement, and completion journal entries.
- `worker/residency.js`: appearance, old-save defaults, real residence age, civic requirements, tax fractions, flags, timed reservations, and completion deltas.
- `worker/citylife.js`: immutable city contributions, event causes/modifiers, and collective responses.
- `worker/progression.js`: gear, revised career thresholds, shared-condition quotes, and smaller quotas.
- `public/residency.js` / `.css`: train intake, customizable citizen scans, character sheet, countdowns, Revenue/Registry/security interfaces, city metrics and responses.
- Existing app/character UI integrates these systems. Displayed version is v0.5.
- `db/schema.ts` and append-only `drizzle/0003_slippery_zaran.sql`: new indexed city-activity table and market `delivered` counter. Older migrations and their snapshots were not changed.
- `scripts/build.mjs` embeds new modules and UI alongside existing assets; Worker entry remains `dist/server/index.js`.
- `scripts/test-harness.mjs`: explicit injected-time/legacy-fixture helper. Production accepts no caller-supplied clock.
- `README.md`: original rainy city artwork, player-facing product explanation, mechanics/timings, setup and verification.
- `docs/GAMEPLAY.md`: complete rule reference and event thresholds.
- `docs/ARCHITECTURE.md`: authority, concurrency, schema, UI/build, and prototype boundaries.

## Verification

All **197 gameplay checks passed**: 41 core, 27 narratives/repairs, 26 factions, 31 equipment/careers, 72 residency/economy. They include delayed wages/XP, exact-once completion/journaling, balance additions while trading during work, fractional tax, deadline holds, factory gates, paid and indigent clearance, arrest/sentence/clearance, daily limits, relief recovery, shared contributions without owner return, stock delivery idempotence, civic/security age gates, and legacy migration.

Build and ESM artifact validation passed. Built Worker boundary checks passed for missing identity, spoofed owner input without identity, cross-origin writes, wrong content type, invalid and oversized JSON, authenticated state, and artwork routes.

Playwright checked 1440px desktop and 390px mobile: train intake, live character choices, registration, name preservation while choosing swatches, every primary screen, no overflow, profile appearance save/reload, starting work, deferred pay, assignment reload, and no page errors.

QA script: `/tmp/schism-qa/residency-check.mjs`, using its existing `playwright-core` installation and `/opt/brave-bin/brave`. Screenshots: `/tmp/schism-arrival-{desktop,mobile}.png`, `/tmp/schism-city-{1440,390}.png`, `/tmp/schism-bureau-{1440,390}.png`, `/tmp/schism-character-sheet.png`. Do not assume the QA dev database survives a restart.

Native WebMCP remains unverified in a browser that supports it. Existing feature detection is preserved, and the shift tool now describes starting a timed assignment.

## Useful commands

This machine needs `PATH=/home/commander/.local/node-runtime/bin:$PATH` for Node/npm. Requires Node 22.20 or newer.

```sh
npm ci
npm test
npm run build
npm run validate
npm run dev
```

Local development serves 127.0.0.1:4173 with a fixed QA identity and an in-memory SQLite database. Rebuild/restart after source changes. Stop development sessions after publication. Do not expose that development identity in production.

No new image generation was needed: the existing original rainline scene is used as the README art and train-window view. Asset prompts/provenance remain in `art/`; original PNG/ZIP archives remain under `/home/commander/schism-*-assets/`.
