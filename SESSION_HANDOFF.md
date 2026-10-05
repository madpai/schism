# SCHISM session handoff — v0.6 portrait collar follow-up

Updated October 5, 2026. Implementation and playtesting are complete. The final publication and GitHub synchronization IDs are recorded in `/home/commander/SCHISM_HANDOFF.md` after native deployment confirmation. The shared local city stays running for the owner's phone.

## Locations and workflow

- Shared local city: http://100.89.1.14:4173 with Tailscale connected. Loopback: http://127.0.0.1:4173. Both listeners use one database.
- Local service: `schism-local.service` in the user's systemd manager; enabled and running, working directory `/home/commander/ashfall`.
- Persistent local data: `/home/commander/ashfall/.local-data/city.sqlite`. Session key and QA browser state are in that ignored directory. Preserve it during updates.
- Live Sites game: https://schism.williamschultz903.chatgpt.site.
- Exact Sites project: `appgprj_6ac325aa83348191bf144ff590881fd4`.
- Sites source checkout: `/home/commander/ashfall` (historical directory name).
- Private GitHub repository: https://github.com/madpai/schism, checkout `/home/commander/schism`, branch `main`.
- Opening source before v0.6: `a91e9264caeee0c7bef6a1795d81e0cfbac4815a`. Previous final deployment: `appgdep_6ac3cc5c38b48191be6dd182bf33489b`.
- Hosting audience remains owner-private. Do not change it without a user request.

For hosted changes, open the existing project through the Sites source-opening workflow before editing, retain that result, and publish the exact checked source through an archive-backed deployment. Use the Sites building/hosting skills. Obtain fresh credentials through native tools; keep them in session memory and hidden workflow stdin, never in source, arguments, or handoffs. Merge Sites source into GitHub `main` with an ordinary non-force push, preserving both histories and remote changes.

This machine requires `PATH=/home/commander/.local/node-runtime/bin:$PATH` for Node/npm. Read [local hosting](docs/LOCAL_HOSTING.md) before restarting the service. Rebuild before restart, preserve `.local-data`, and **leave the shared local service running** for phone testing.

## Latest user direction

The user wants a harsh asynchronous MMORPG city with more meaningful actions between long jobs, stylized illustrations for locations/jobs/events, attractive customizable painted characters, visible earned uniforms, and a neural-network-style social space. They test primarily on mobile but want desktop too. They explicitly asked for agent playthroughs, pacing/visual critique, and multiple characters testing **the same local city**. Each browser has a separate local signed session; there is no second QA world.

They reported hair misplaced on the chest, floating/disconnected heads, and misaligned braids in the first painted prototype. Individual alpha crops corrected the atlas bleed, but the next report identified the head appearing behind the jacket. Garments now render in two passes: rear garment, face/neck, clipped front collar, then hair. Civilian and uniform openings follow their own painted neckline. The 135 face/build/hair/outfit combinations, six skin/hair color pairs, mobile shaved/braided intake, and profiles at 360/390/1440px were checked. Do not restore the pixel character, leaking nested atlas, or flat whole-jacket overlay.

The user also asked for a candid assessment and improvement ideas. [Next priorities](docs/NEXT_STEPS.md) recommends action-triggered branching encounters first, then measured visit pacing, demand for player-made goods, phased shared events, and distinct institutional work. These are proposals, not implemented mechanics.

Keep the Canon/Wound setting, rainy neon noir art, near-black/cyan/crimson palette, and terminal typography. Preserve the existing vanilla HTML/CSS/JavaScript, Worker, Sites identity, and D1 architecture.

## v0.6 behavior

- Separate short-task slot `errand`: server-owned 20–75 second tasks, energy and materials reserved at start, additive rewards at completion. It can coexist with ordinary paid work. Street scavenging and gambling require off-duty time; other long assignments need full attention.
- Ten short-task starts per six-hour city cycle, including crafts, neural contracts, and casino hands. Long work retains its existing eight-hour daily permit; there is no career/residency shortcut.
- Five tasks: bins (25s/6 energy, two fabric or wire), electronics (45s/8, two wire and a circuit with a 20% chance of 2 damage), terminal cleaning (20s/5, 1 taxable CR), signal decoding (35s/7, one trace), heating relay (60s/9, one wire consumed, 2 taxable CR and one relief).
- Four recipes: warming pack, field dressing, rebuilt relay fragment, neural grounding patch. Crafted consumables improve warmth, health, or coherence; ordinary fragments retain existing trade/repair use. Workshop XP records crafts separately from career XP.
- Civic neural network: three persistent chat channels, sender names from the server, 1–320 characters, 15 seconds between messages, 40 per real hour. Polls every ten seconds while visible; polling and completion refreshes pause for focused inputs.
- Two once-per-cycle contracts, each one trace/8 energy/50s. Public freight: 2 taxable CR, 1 trust, one shared freight. Hidden Wound echo: 3 unreported CR, +4 heat, −1 alignment, one shared crime. Commitments affect the city at completion without requiring owner return.
- Null House: 20s/6 energy, stakes 1–3 CR, 45% chance of double return, expected loss 10% of stake, four hands per cycle. Stake held at start; no cancellation/reroll/debt or client-selected outcome.
- Earned administration/security uniforms are awarded and equipped on appointment/recruitment; legacy owners receive them through compatibility. They are not for sale and do not replace insulation. Equipped body gear drives the painted wardrobe.
- Three painted faces, four painted hairstyles plus Shaved, independent six skin/six hair colors, and three torso builds. Portraits use cropped generated alpha layers and runtime tint filters. Rear/front garment passes put the neck inside the collar, with hair above both.
- Seven new city scene illustrations appear in areas, job tracks, assignments, and shared events. Build embeds 23 WebP assets total, including portrait crops.
- Long-assignment panels collapse to a concise timer on other screens; Find work retains the full illustrated assignment. This keeps mobile tasks and chat within reach.

## Preserved v0.5 rules and the completed reset

New citizens arrive by train into the current server day, neutral with zero credits. One city hour is 15 real minutes; a shared cycle is six real hours. Days in the city count complete real 24-hour days since registration. Timed pay, XP, and completion journals are guarded and exactly once. Hunger, warmth, rent, taxes, and city events continue offline.

Earned-income tax is 12%, manually paid with fractional carry. Overdue tax/arrest holds block factory/institution access. Payment and Registry clearance are separate; fee review and indigence appeal remain. Crime, cooperative repairs, collective production/freight/unrest/relief/patrol effects, twelve jobs, equipment/careers, housing, trade, and five personal stories remain. Shops, administration, and security retain one/two/seven-day residency gates and their training/trust requirements. Complete rules are in `docs/GAMEPLAY.md`.

The owner explicitly requested a one-time fresh start after the earlier easier economy. Live receipt `residency-fresh-start-2026-10-05`, `completed=1791216527324`, `citizens=1`, confirms reset at 16:08:47 UTC on October 5, 2026. Old personal records/pending contributions were removed; shared clock, market, factions/projects, and completed history continued. Temporary reset route was removed and maintenance code excluded from the Worker. **Do not reset again or restore old characters.** v0.6 preserves all new local and hosted citizens.

## Source and schema

- `worker/street.js`: short tasks, salvage, crafting, neural contracts, casino, eligibility and delayed settlement.
- `worker/game.js`: integrates both activity slots, concurrent/combined completion journals, chat writes, and immutable quick contributions.
- `worker/progression.js`: earned uniform catalog, compatibility, and short-task job blocking.
- `public/street.js` / `.css`: short activities, workbench, materials, supplies, neural channels/contracts, casino, area gallery, art integration, compact assignment display.
- `public/residency.js`: generated portrait layers, independent tinting, neckline-specific front/rear garment composition, five styles, countdown/focused-input behavior.
- `db/schema.ts`, append-only `drizzle/0005_complex_kree.sql`, and new metadata: indexed `neural_messages`. No prior migration changed.
- `scripts/dev.mjs`, `scripts/local-db.mjs`: shared persistent local city, per-browser signed sessions, loopback/Tailscale listeners, once-only local migrations. These stay outside the production bundle.
- `scripts/test-street.mjs`: 55 rule assertions. `scripts/playtest-browser.mjs`: optional real-time shared-city mobile/desktop playthrough; `playwright-core` is a pinned dev dependency.
- `scripts/playtest-portraits.mjs`: bounded visual gallery and mobile/desktop intake/profile check using an existing private browser session; `npm run test:portraits`. No gameplay POSTs or uniform grants.
- `README.md`, `docs/GAMEPLAY.md`, `docs/ARCHITECTURE.md`, `docs/LOCAL_HOSTING.md`, and `docs/playtests/V0.6.md`: current rules, local operation, verification, and candid critique.
- `art/street-prompts.json` / `street-provenance.json`: built-in imagegen prompts, paths, alpha crops, conversion, and hashes. Original new PNGs remain at `/home/commander/schism-street-assets/` and default generated-images paths.

## Verification and known limits

All **272 assertions passed**: 41 core, 27 narratives, 26 factions, 31 equipment/careers, 72 residency/economy, 20 reset, and 55 street/network/wardrobe checks. Build, ESM validation, and diff whitespace checks passed.

Actual browser playthroughs used ordinary Iona/Cato/Null Tester characters in the shared Tailscale city. Real scavenging, crafting during a paid shift, decoding, public freight contract, chat across two sessions, and a losing casino hand were checked. Saved appearance, assignments, data, and signed sessions survived reload/restart. All 16 screens fit 360px, 390px, and 1440px with no page errors. A focused mobile chat draft survived a real short-task deadline; automatic completion refreshed after blur. Final portrait and uniform visuals were inspected.

Selected screenshots and critique are committed under `docs/playtests/`. Raw QA scripts/images remain in `/tmp/schism-qa`; Iona Vex browser state remains in ignored `.local-data/qa-browser.json`. These citizens remain available as ordinary city residents; no test grants were applied to their server records.

The collar follow-up changes browser composition and documentation only. Build/ESM validation, diff whitespace, and the bounded portrait browser review passed after that change. Existing gameplay rules are unchanged; the 272-rule suite above records the v0.6 gameplay release, rather than a new run for this cosmetic patch. Selected collar evidence and the follow-up critique are in `docs/playtests/V0.6.md`; all raw follow-up screenshots are in `/tmp/schism-portrait-review` on this machine.

Energy can run out before the ten-task quota, by design. The played five-task route left about six energy; UI advises keeping energy for wages. Further tuning should use the owner's phone sessions and multi-day food/warmth histories. Short contracts currently repeat once each per cycle. Chat is polling with a recent-message window, without private messaging or notifications. Native WebMCP remains unverified. Long deadlines and week-long institutional gates were checked with injected time; a week-long human career was not played.
