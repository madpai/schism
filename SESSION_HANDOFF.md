# SCHISM session handoff

Saved 2026-10-05. The user asked to end this session and prepare for another. All requested implementation and repository work is complete; do not start additional features until the next request.

## Project and source

- Live game: https://schism.williamschultz903.chatgpt.site
- GitHub: https://github.com/madpai/schism — private, account `madpai`, default branch `main`.
- GitHub checkout: `/home/commander/schism` (`origin` points to GitHub).
- Sites checkout: `/home/commander/ashfall` (historical directory name; the product is SCHISM). Its `github` remote points to the same GitHub repository.
- Sites project ID: `appgprj_6ac325aa83348191bf144ff590881fd4`.
- Last deployed source: `1179e8a19c44e392af032fc5dcf11073de274198`.
- Last successful deployment: `appgdep_6ac34ebe3c588191a613a21bab89c4b8`.
- GitHub gameplay import/merge: `2de31352af69cde4d8c08104cf70d47b17115fdf`. Its tree matched the deployed source exactly before this documentation-only handoff commit.
- Existing GitHub initial commit was retained. Both workspaces were clean before adding this handoff.
- Hosting remains owner-private. Preserve the current audience unless the user asks to change it.
- No credentials belong in this file or the repository. GitHub CLI is authenticated locally; Sites credentials must be freshly obtained as needed.

## User intent and established direction

The game is a persistent dystopian browser MMO about ordinary people surviving an indifferent system: jobs, hunger, cold, rent, crime, trade, institutions, housing, businesses, and relationships. The player is not a chosen hero.

The chosen one-word name is **SCHISM**. The user asked for unique dark assets and a legacy DOS/terminal PC feel, then steered toward ANEURISM IV and E.Y.E. Divine Cybermancy: a weird original world organized around Order and Chaos. They rejected the earlier brown, steam-age/1930s industrial atmosphere. The latest request pushed toward Blade Runner-like rainy neon noir, stronger character immersion, equipment/loadouts, full inventory, different shifts, and careers. Keep the original Canon/Wound world and terminal typography while retaining the cold cyan, restrained crimson/magenta, near-black palette and rain-soaked urban imagery.

The user said they completed the earlier story slice quickly. Career progression and repeatable city-day quotas now provide more activity beyond the finite narrative chapters. More depth is a possible future discussion, not an unfulfilled request or authorization to begin new work immediately.

## Implemented game

- Persistent authenticated citizens start with 9 credits and 12 credits of rent debt, plus low warmth/fullness.
- Jobs, trust unlocks, food/medicine, cold exposure, rest, daily rent, eviction, private rooms, theft/smuggling, union membership/organizing, shops, property leases, and official work.
- Shared supply stock, direct player trades, citizen registry/notices, and a cooperative thermal-lattice repair. Contributions restore warmth protection for everyone.
- Asynchronous multiplayer; the interface refreshes shared state every 30 seconds. There is no real-time movement/combat world.
- Five branching personal story threads: the mirror signal, Iona, Havel, Rook, and Voss. Saved choices, NPC relationships, flags, gated follow-ups, and replay protection remain separate for each citizen.
- Shared Order/Chaos balance: the Canon at +20 lowers ration/broth prices by 1 CR and adds 10 percentage points of capture risk. The Wound at -20 raises food prices by 1 CR, subtracts 10 capture points, and raises package-run pay to 28 CR. Personal signal choices and one rite per citizen per city day affect the balance.
- Private alignment/coherence persist. Coherence is an implant-status record changed by stories, work, rites, and treatment, rather than another automatic survival damage threshold.
- Loadout with five slots: head, body, hands, feet, and neural. Three basic starting equipment items and seven purchasable upgrades. Actual bonuses affect cold, shift fatigue, hazardous-work damage, coherence loss, field pay, and capture risk.
- Full Inventory screens for equipment, consumables, and materials, with equip/remove/use/sell controls. Blackware equipment stock is shared through the existing market transaction guards.
- Four career tracks: mnemonic engineering, transit/courier, civic service, and industrial recovery. Twelve jobs total. Career XP, ranks at 12/32/64 XP, specialist unlocks, and matching active-career pay bonuses. Switching tracks preserves XP.
- Regular, overtime, and graveyard shift modes. Overtime/graveyard unlock after two completed shifts. UI quotes and server outcomes include current equipment, career, union, and district heating effects.
- Three shifts on a career path in one city day unlock an 8-CR, 1-trust quota reward, claimed once per path/day.
- Existing saves acquire story, signal, gear, and career fields without resets. Legacy shrouds remain owned/equipped. Legacy work earns two initial mnemonic XP per recorded shift; new work earns two XP per working hour. Legacy inventory keys (`bread`, `medicine`, `scrap`, `coat`) remain for compatibility.
- Shared city days last six real hours. Work/rest advance personal time; offline hunger/cold/rent are settled when citizens return.

## Architecture and files

The app is vanilla HTML/CSS/JavaScript bundled into a Cloudflare Worker ESM module. Preserve its stack; no framework migration is needed.

- `worker/index.js`: HTML, embedded WebP routes, `/api/state`, `/api/action`; production identity comes only from trusted Sites headers.
- `worker/game.js`: server-owned simulation/actions and D1 transactions.
- `worker/stories.js`: personal narratives and choice validation.
- `worker/forces.js`: shared Order/Chaos effects.
- `worker/progression.js`: gear catalog, effects, career ranks, shift quotes, and quotas.
- `public/app.js`: core UI/navigation/actions; `public/character.js`: loadout/inventory/career interfaces.
- `public/style.css`, `terminal.css`, `occult.css`, `noir.css`: established styling layers.
- `public/index.html`: shell/font imports/favicon; displayed build is v0.4.
- `scripts/build.mjs`: embeds HTML/JS/CSS and five WebP images into `dist/server/index.js`; copies hosting config and migrations. `scripts/build.sh` delegates to this builder.
- `db/schema.ts`, `drizzle/`: schema and three generated migrations (citizens/market/trades/etc., shared projects, shared forces). Gear/careers live in existing citizen JSON and required no additional migration.
- `scripts/local-db.mjs`: Node SQLite D1 adapter for meaningful concurrency/action tests.
- `scripts/dev.mjs`: local-only fixed QA identity and in-memory SQLite on 127.0.0.1:4173. Build first; restart after source changes. Local data resets on restart; production D1 is durable.
- `.openai/hosting.json`: existing project ID and logical `DB` D1 binding; preserve it.

## Verification completed

All **118** gameplay checks passed: 34 base gameplay, 27 stories/shared repair, 26 Order/Chaos, and 31 equipment/career checks. They cover costs, persistence, legacy migration, replay protection, daily limits, concurrent stock/trades/repairs/rites, gear effects, shift quotes, specialist requirements, career switching, and quota rewards.

Build and artifact validation passed. Playwright checks passed at desktop 1440px and mobile 390px: all screens fit, no browser errors, gear buy/equip/reload, inventory filters, career switching, visible shift confirmation, quota claim, and existing story/force screens. The overview quick shift button is visible in the first viewport on desktop/mobile and completes a saved regular shift.

The installed QA browser lacks native WebMCP; the feature-detected browser tools remain unverified in a supporting browser. This is documented in README.

Useful local commands (Node 22.20 or newer):

```sh
npm ci
npm test
npm run build
npm run validate
npm run dev
```

This machine's Node/npm require `PATH=/home/commander/.local/node-runtime/bin:$PATH`. GitHub checkout dependencies can be installed normally when needed.

Prior Playwright scripts are outside the repo under `/tmp/schism-qa/`; its `playwright-core` module and `/opt/brave-bin/brave` were used. `character-check.mjs` runs the recent full UI flow; `quick-shift.mjs` checks the first-viewport action. Start a fresh local server/database for these scripts. Screenshots are `/tmp/schism-noir-{overview,loadout,careers,loadout-mobile}.png`. All local development servers were stopped after publishing. All asset agents are finished.

## Artwork

Five deployed assets: `public/city.webp`, `factory.webp`, `market.webp`, `city-noir.webp`, and `citizen.webp`. The first three form the original occult city/foundry/exchange. The last two add rainy noir streets and a worker identity scan. The portrait is a fixed original archetype; gear labels and effects update, but there is no dynamic wardrobe rendering or character-appearance customization.

Exact image-generation prompts and provenance are committed at `art/occult-provenance.json` and `art/noir-provenance.json`. Built-in imagegen was used. Original PNGs and downloadable packs are retained outside the source checkout:

- `/home/commander/schism-occult-assets/` and `schism-occult-art.zip`.
- `/home/commander/schism-noir-assets/` and `schism-noir-art.zip`.
- Older superseded DOS art is in `/home/commander/schism-dos-assets/`.

## Continuing safely

Read this file and README first. No game task is pending. Get the next user request before implementing additional work.

For playable Site edits, apply the Sites building/hosting skills. Open the existing Site with its exact project ID and the bundled source-opening workflow before editing `/home/commander/ashfall`; retain the opening result. Preserve production saves and the current private audience. Generate migrations only for actual schema changes. Reuse completed checks unless new changes require them. Publish the exact checked source using the supported archive-backed workflow and native deployment status.

After a new Site source commit is published, synchronize the GitHub checkout by fetching the local Sites branch, merging it into GitHub `main`, then using an ordinary non-force push. Preserve remote changes and inspect conflicts. GitHub and Sites histories are intentionally distinct, with GitHub containing its original initial commit and merge imports. Do not replace GitHub history or expose Sites credentials.

This handoff itself is documentation-only and does not require another game deployment.
