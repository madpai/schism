# SCHISM session handoff — v0.8.1 mobile visits

Updated October 5, 2026. The owner requested all accepted priorities, a permanently free unheated starting bunkhouse, and publication/documentation/GitHub handoffs before a fresh session. v0.8 implements them. Exact final deployment and matching GitHub source IDs are recorded in `/home/commander/SCHISM_HANDOFF.md` after publication. Leave the same shared local city running; preserve all current characters.

## Locations and release workflow

- Shared phone/QA city: http://100.89.1.14:4173; Tailscale required. Desktop loopback http://127.0.0.1:4173 uses the same SQLite file.
- Enabled user service: `schism-local.service`, working directory `/home/commander/ashfall`.
- Persistent ignored data: `.local-data/city.sqlite`, signed session key, saved QA sessions, backups, raw screenshots. Never expose or commit cookies or keys.
- Hosted game: https://schism.williamschultz903.chatgpt.site, owner-private; exact Sites project `appgprj_6ac325aa83348191bf144ff590881fd4`.
- Sites source: `/home/commander/ashfall`; GitHub: `/home/commander/schism`, https://github.com/madpai/schism, main.
- Opening v0.8 source: `6cc45ed71b86b8ce4433b9b0b5a050b738a0bb6e`. Previous v0.7 deployment `appgdep_6ac408fd43688191bd16a657b0589515` succeeded 20:31 UTC; GitHub merge `64daab84c0c88ad8eae02f9a8c81d5c58fcf6ea6`.

Open the existing Site through its source workflow before editing. Publish checked source with the exact matching archive through Sites building/hosting skills. Credentials stay in memory and hidden workflow stdin. Preserve the audience. Merge Sites source into GitHub with a normal non-force push and retain both histories. This machine requires `PATH=/home/commander/.local/node-runtime/bin:$PATH`. Rebuild before restarting the service, do not start a competing listener, and leave the service running.

## User direction and portrait constraints

Keep a harsh persistent city: zero-credit neutral train arrivals inherit the actual city day; real account age is separate. Tax delinquency and arrest must inconvenience players without trapping them permanently. Lawful careers, crime, short tasks, player trade, earned uniforms, social ties, and attractive painted scenes should give each visit decisions. The user tests mainly on mobile but wants desktop too and agent characters in the same city. Publish work, README art, docs, and handoffs consistently.

The basic bunkhouse must not bill an absent citizen. Its misery is no heat and weak recovery, with voluntary street/cardboard sleep and a barrel fire. Private obligations are bounded. Do not turn these changes into a character reset.

Keep independently cropped alpha-preserving player portrait layers: rear garment, face/neck, neckline-specific clipped front garment, hair. Both garments share body breadth. Shaved has no hair layer. Never restore the leaking atlas, pixel portrait, floating neck, or whole-jacket overlay. Earlier checks covered 135 combinations and all skin/hair pairs. New contact portraits do not replace the customized player sheet.

## v0.8.1 mobile visits

The Playwright MCP is available in the current tool catalog. Reuse its persistent dedicated QA profile, signed in as ordinary Quin 676e0 in the same phone city. Housing puts rest controls before descriptive copy and folds other residences and current tax detail; owed tax/ID holds expand by default and Registry controls remain fully visible. The neighbors page puts the building channel before the shelf in both DOM and visual order, shows stocked supplies first, and folds empty rows and membership controls. Keyed disclosures survive refresh, actions, and navigation in the current tab. Their preference is deliberately not persisted across full reloads. Daily activity Details now targets housing/Registry/underground for rest/clearance/crime. No wages, housing rules, ownership, art layers, or migrations changed.

Run the function in `scripts/playtest-visits-mcp.js` through `browser_run_code_unsafe` with an absolute filename in the opened checkout. It uses visible navigation, checks 17 screens plus papers at three widths, verifies disclosures/drafts, and tests urgent-tax/detail routes with temporary client-only render copies restored before any request. See `docs/playtests/V0.8.1.md` and its credential-free numeric evidence. The older living-browser harness now opens the folded tax control and keeps its association ID available through the reload check; its full multiplayer route was not rerun for this UI patch.

## v0.8 behavior

- Bunk: 0 rent, cold 1.5/hour, ninety-minute sleep adds up to 38 energy and 8 health with no warmth. Cardboard: 0 rent, cold 3, sleep 30 energy/4 health/no warmth. Private room: deposit 45 / rent 20, sleep 52 / +32 warmth; flat deposit 180 / rent 32, sleep 62 / +40. Paid gates remain.
- Four unpaid private bills cause street eviction and cap debt at 80/128. Prepay 1–8 cycles with real held credits; unused funds refundable. Returning to a free bunk is available off duty even with paid arrears, preserves them, and stops new charges. `housingVersion=1` applies the old basic-bunk waiver once, including old street evictions≤ 48; old paid evictions retain debt.
- Barrel fire: 45s / zero energy / +12 warmth at completion, once/cycle, off duty, outside the common quota. Relief remains once/cycle and consumes its aid immediately. Passive health floor 10 and idle recovery make an absent citizen recoverable.
- Optional tax reserve holds newly assessed whole-credit tax from reported income, including offline work/listings/orders. Enabling also funds affordable existing debt. Deadline uses held funds; disabling refunds without erasing debt. Any existing ID hold still requires payment plus actual Registry review. Twelve-percent fractional carry remains.
- Twelve finite contact continuations plus four recurring check-ins: remembered branches/housing/roles/aftermath select offers, one new offer/cycle, two open maximum, sixty-second free follow-up. Thread choices persist beyond the last40 journal. Recurring check-ins wait for that contact's original pending reply. Neri lesson lowers mending effort 3 → 2; Voss advocacy lowers Registry effort by 2 with normal fee/deadline/hold.
- Free associations: one membership, up to 12 residents, one founder association/citizen. Donate 1–5 actually owned supplies, cap 100/item. Withdraw one consumable/cycle across all buildings. No material withdrawals. Member chat 320 chars, 15s spacing, 40/hour; outsiders see no channel. Transfers name actors to members.
- Six actual 30s / 4-energy repair units consume 1 shared wire + 1 fabric each and common short starts. Ordinary work breaks allow them. Indoor members receive 0.75 less cold/hour for 24 real hours after sixth completion. Expiry resets active round without printing supplies. Immutable completion history and membership timestamps bound offline benefits exactly.
- Failed observed incidents carry damage into following 4 cycles. Overlap caps at 0.5 cold/hour for boilers and +1 food CR for freight. Recovery target 3–6 fixed from original target;40s / 4 energy / 1 wire or trace, 2 taxable CR / +1 trust at completion, 2 starts/citizen/cycle and common quota. Final-slot guard prevents overassignment. Completion lifts pressure early; contracts cannot finish after expiry.
- Newspaper stores immutable deadline totals/outcome and up to 4 named public repair contributors. Covert actors are not named. Future recovery does not rewrite it; unobserved historical cycles do not invent incidents.
- Ordinary completed shifts add 4 cosmetic clothing wear, cap 100. Native SVG scuffs at 25; mend 30s / 1 owned fabric / 3 energy (2 with lesson), commonquota/workbreak, removes 40 at completion. Wear never changes equipment stats or creates debt.
- Compact daily vitals/feed, ready reply portraits, three priority actions, reserve/housing page, association shelf/channel/repair page, recovery/newspaper, mobile Today/Tasks/Messages/Rest dock. Drafts survive renders; deliberate open history pauses polls, automatically open directories do not. Overview/city/market/neighbors poll 15s, neural 10s, global 30s with focus/dialog/visibility guards.
- Six new original painted assets: Neri/Esra/Voss/Rook portraits, unheated bunkhouse, barrel/cardboard rainline. Prompts and provenance in `art/living-*.json`;29 embedded WebPs total. README retains city banner and adds bunkhouse artwork.

Existing v0.7 encounters, escrow orders, limited municipal demand, case desks, phased crises, careers, earned uniforms, crime/ID rules, and security's seven-real-day gate remain. The earlier owner-authorized reset completed at 16:08:47 UTC on October 5; no reset endpoint is deployed. **Do not reset again.**

## Implementation and verification

New domains: `worker/living.js`, `contacts.js`, `tenants.js`, `aftermath.js`; integrated by `game.js`, `residency.js`, `citylife.js`, and `life.js`. Deferred activity sets exclude nested finance/neighborhood/contact/aftermath state. Incoming listing payment reserves tax atomically and increments seller version. Shared building/stock/recipient/recovery changes use guarded transaction batches.

Append-only migration `0007_naive_major_mapleleaf.sql` and metadata add 7 tables: tenant_blocks/members/messages/transfers/repairs, recovery_actions, district_news. No earlier migration edits. Existing local city migrated after a private SQLite backup in `.local-data/backups`.

Current suite: **438 assertions** (old 355 plus 83 living). New checks cover ten-day absence, legacy waiver, sleep/fire deadlines, private debt/prepay/refund races, tax reserves, shared conservation and private chat, last-item/capacity races, actual completed repairs/historical protection, deferred original/continuation offers, Registry advocacy, wear, recovery reservation race, immutable newspaper, and expiry. Build/ESM validation and whitespace checks are part of publication.

`npm run test:balance` uses normal registration/actions and isolated injected deadlines for seven-day schedules. Daily/twice-daily/each-cycle/missed-weekend memory shifts end with22/48/55/15 CR and no rent/tax debt. A much more intensive two-shift-per-cycle schedule uses the unlocked lattice job, pays 400 CR rent, and ends privately housed with 447 CR. This requires many returns and is not casual affordability evidence. Raw numeric schedules are committed under `docs/playtests/v0.8/balance.json`.

`npm run test:living-browser` uses ordinary Sera/Vale arrivals in the same Tailscale city, real scavenging, six real repairs during pending custodial shifts, shared chat, real wages, and an owned ration transfer. Private sessions live in ignored `.local-data/living-playtest`. An interrupted post-repair run can resume with `SCHISM_QA_REUSE=1 SCHISM_QA_STAGE=finish`; this never rewinds resources or deadlines. A separate fresh Quin contact run validates the corrected original→continuation→lesson path at real minute-long replies. See `docs/playtests/V0.8.md` for exact observation times, screenshots, critique, and limits.

Desktop/mobile sweeps cover all 17 pages at 360/390/1440px. Actual phone hardware remains the owner's test. Unit/simulation clocks never touch persistent QA or phone characters. Current-weather global settlement is still approximate; tenant windows are exact. Associations are a cooperation slice, twelve continuations are a small authored pool, and two emergency types need expansion. Native WebMCP remains unverified.

## Next session

Read [NEXT_STEPS](docs/NEXT_STEPS.md) and [V0.8](docs/playtests/V0.8.md). First gather real multi-day phone evidence: survival recovery, attention per visit, housing affordability, supply fill rates, and whether remaining long pages hide useful actions. Expand histories, association demand, and emergency stories from that evidence. Preserve shared local data, corrected art layering, role gates, bounded debt, and publication discipline.
