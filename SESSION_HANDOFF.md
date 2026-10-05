# SCHISM session handoff — v0.7 district life

Updated October 5, 2026. The five accepted priorities are implemented. Final publication IDs are recorded in `/home/commander/SCHISM_HANDOFF.md` after native deployment confirmation. Leave the shared local city running for the owner's phone and preserve all current characters.

## Locations and workflow

- Shared local city: http://100.89.1.14:4173 with Tailscale connected; desktop loopback http://127.0.0.1:4173. Both listeners use one database.
- User service: `schism-local.service`, enabled and running in `/home/commander/ashfall`.
- Persistent data: `/home/commander/ashfall/.local-data/city.sqlite`, with private session key and QA storage-state files in that ignored directory. Preserve them.
- Hosted game: https://schism.williamschultz903.chatgpt.site; exact project `appgprj_6ac325aa83348191bf144ff590881fd4`, owner-private.
- Sites source checkout: `/home/commander/ashfall`; GitHub checkout `/home/commander/schism`, https://github.com/madpai/schism, branch `main`.
- Opening v0.7 source: `5882ab6b0656b5bacee4de09710ec2edc03a752e`. Previous deployment `appgdep_6ac3fa8a791481919158e68839f88738` succeeded October 5 at 19:29:21 UTC. Previous GitHub merge `f1ebe95ed570bff57f66de0b6496549d1af3d6e3`.

For hosted edits, open the exact existing project through the Sites source workflow before editing and retain the returned source result. Publish the checked source with its matching archive using the Sites building/hosting skills. Mint native credentials in memory and send them through hidden workflow stdin; never put tokens in files, shell arguments, or handoffs. Preserve the existing audience. Merge the Sites source into GitHub main with a normal non-force push, preserving remote changes and both histories.

This machine needs `PATH=/home/commander/.local/node-runtime/bin:$PATH`. Rebuild before restarting the service; read [local hosting](docs/LOCAL_HOSTING.md). Do not start another server on the same port. **Leave the service running after publication.**

## User direction and visual constraints

The user accepted all five priorities in [the updated assessment](docs/NEXT_STEPS.md): action-triggered encounters, useful visit pacing, player demand, phased shared emergencies, and distinct career assignments. They want harsh survival and lawful inconveniences, with tempting criminal alternatives, meaningful short actions, attractive painted art, earned visible uniforms, and the neural social space. They test mostly on mobile but want both platforms and agent playthroughs with separate ordinary characters in the **same city**. Keep publishing, README, documentation, and handoffs current.

Earlier hair-on-chest, floating head, braid, and head-behind-jacket defects are fixed. Keep individual alpha-preserving portrait crops, rear garment, face/neck, neckline-specific clipped front garment, then hair. Both garment passes share body breadth. Shaved renders no hair. Do not restore the leaking atlas, pixel portrait, or flat whole-jacket overlay. The previous release checked 135 face/build/hair/outfit combinations and all six color pairs. v0.7 retains those assets and composition.

Keep the Canon/Wound fiction, rainy neon noir art, near-black/cyan/crimson palette, terminal typography, vanilla interface, Worker, Sites identity, and D1 architecture.

## v0.7 behavior

- Four finite encounters are discovered on completion of bins, salvage, decode, or the first ordinary shift. Published choices, contacts, flags, last 40 decisions, and 60-second replies are server-owned and replay-protected. Free responses work during ordinary employment; other long assignments require attention.
- Three zero-energy bulletins once/cycle; free case review and ordinary trade/chat remain useful at low energy. A quiet route subtracts ten capture percentage points from one operation, consumed at its start and expired at cycle rollover. Paid reconnaissance costs 30s/4 energy/one trace and a short-task start.
- Task energy: bins 4, salvage 5, terminal 3, decode 4, relay 6. Recipes: warming pack 3, dressing 3, fragment 6, neural patch 5. Public/hidden contracts 5/6. Durations and payouts retained. Ten short starts/cycle, eight work hours, three ordinary crimes, and two long shop sessions still apply.
- Funded buy orders for ten supply types, 1–10 units, integer 1–50 CR/unit. Full upfront escrow, partial deliveries from owned goods, taxable supplier payment, undelivered refunds. Three open orders or eight for shops. Atomic guards cover supplier/last-unit/cancel races and recipient updates during work.
- Two bounded municipal offers per cycle, three to eight shared units each; **one one-unit delivery per citizen per cycle**. Reads never refill stock; old municipal offers close. Dressings/warming packs add relief. Citizen orders persist.
- Alternating boiler/freight emergency: one-hour warning, five-hour deadline, stabilization that diversions can undo, recorded secured/failed last-hour effect, last five outcomes. Target fixed at opening from recent completed contributors, bounded 3–12. Relevant work, patrol/relief/freight, contracts, and crime contribute at completion without the owner returning. Two fast direct responses/cycle use common short-task quota and declared supplies.
- Earned administration/security/shop/underground desks: free review, distinct 30–60s cases with lawful/illicit alternatives, one per role/cycle, off-duty response, costs reserved and pay/consequences deferred. Existing institution gates and ID rules apply; Rook contact or 3 underground XP opens underground work. No appointment shortcuts or civic XP grants.
- Long shops can consume ration, fragment, warming pack, dressing, or neural patch; actual stock reserved. Full rules and case tables are in [GAMEPLAY](docs/GAMEPLAY.md).
- Overview next actions, rent/tax savings, encounter inbox, explicit task energy remainder, prepared crime risk, illustrated cases, order forms. Mobile city incident leads; area gallery expands on demand. Overview/city/exchange poll every 15s; neural screen 10s. Refresh pauses for focused inputs, dialogs, or open details; order drafts survive renders.
- Existing 23 original WebP assets reused across new content. No new portrait generation this release.

## Source and persistence

`worker/life.js`, `orders.js`, and `crises.js` contain the new authoritative domains. `game.js` integrates them into settlement and guarded batches; `citylife.js` adds emergency effects after existing aggregate events. `public/life.js`/`.css` provide UI. Build embeds all modules and seed catalogs. Append-only `drizzle/0006_wealthy_garia.sql` and metadata add `supply_orders`, `district_crises`, and `crisis_actions`; earlier migrations remain unchanged. Local migration was applied to the existing city.

Deferred long-assignment sets exclude nested `district` state. This preserves reservations, encounters, bulletins, and incoming stock during later wage/crime settlement. Supply deliveries increment recipient inventory JSON atomically and both citizen versions. Emergency commitments use immutable completion timestamps; deadline totals exclude late contributions and resolve once on reads. See [architecture](docs/ARCHITECTURE.md).

New citizens remain neutral with zero credits, existing shared server day, and one six-hour rent grace. Residency days are real 24-hour days. Income tax is 12% with fractional carry, manually paid; paying debt and Registry clearance remain separate. Public custodial work/relief support recovery. Security remains seven real days plus the existing trust/XP/shifts/Order gates.

The earlier one-time owner-authorized reset is complete: `residency-fresh-start-2026-10-05`, completion `1791216527324`, one old citizen removed at 16:08:47 UTC October 5. Reset HTTP route and helper are excluded from the deployed Worker. **Do not reset again or restore old characters.** v0.7 retains all hosted/local citizens.

## Verification and limits

All **355 assertions passed**: 41 core, 27 stories, 26 factions, 31 progression, 72 residency, 20 reset, 55 street, 83 district. New checks cover encounters and stale/early/replayed/concurrent choices, exhausted planning, crime route reservation/expiry, escrow/refund/delivery races and goods/credit conservation, tax, incoming nested material during wages, municipal caps/rollover, phase/deadline outcome persistence, role gates/case settlement, and a simulated 24-hour eviction/relief/next-shift return. Build/ESM validation pass; final publication also checks whitespace.

`npm run test:district-browser` uses two ordinary Lysa/Esren citizens in the owner's shared Tailscale city. It waits through actual short actions, replies, and a fifteen-minute shift, then funds and fills an order with real wages; total observation is twenty real minutes. Evidence and numeric pacing are recorded in [V0.7](docs/playtests/V0.7.md), with private session files in ignored `.local-data/district-playtest`. The script creates citizens and leaves them in the city without grants or timestamp changes. Existing Iona Vex session stays in `.local-data/qa-browser.json`.

Desktop/mobile sweeps cover all 16 primary pages at 360/390/1440px, exchange forms, crisis controls, and illustrated career briefs, without overflow or page errors. Earned-role visual previews change client state only and perform no gameplay actions or server grants. Week-long role progression and full crisis deadlines are checked with isolated injected-time tests, not claimed as actual multi-day play. Repeated city reads cannot reconstruct historical offline weather. Four finite encounter chains and two emergency types will need content expansion. Municipal buyers and case buyers are authored demand, separate from citizen-funded trades. Native WebMCP remains unverified.

Selected evidence is committed under `docs/playtests/v0.7/`; raw scripts/screenshots are in ignored `.local-data/district-playtest` and `/tmp/schism-qa`. README keeps the original city art and updated documentation links. Review [NEXT_STEPS](docs/NEXT_STEPS.md) for the candid remaining weaknesses rather than treating these five slices as the end of content development.
