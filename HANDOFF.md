# SCHISM Android rebuild handoff

**DO NOT TURN SCHISM BACK INTO A MENU-HEAVY DASHBOARD GAME.** The player interacts with a place and its objects. Ordinary work and small possessions should carry the emotional weight.

## Active project and preserved research

`mobile/` is the active Godot 4.7.2 portrait Android game, version 0.4.0. The rebuild branch is `rebuild/android-district-ix`. The browser v0.10 at `0ba675e` was audited before implementation; its source, migrations, assets and tests remain intact. Its former README, architecture, gameplay and handoff are in `docs/legacy/`. `docs/AUDIT.md` maps lessons to the new implementation and records the inventory snapshot.

Do not modify the separate `/home/commander/ashfall` live city, deploy the legacy `.openai` Site, reset existing citizens or reinterpret browser wallets as native saves. Native local persistence is in a separate Android application namespace.

## What you can play

Create a civic identity with a name and appearance tint. Fold the residency paper. Drink at the room sink. Walk through the hallway into a rain-soaked district. Take a bureau ticket, present your ID, and choose one of three bad jobs. Laundry has a full inspect/pocket/sort/load/treat/wash/unload/dry/fold/dispatch/pay sequence. Cleaning and freight have smaller complete physical work orders, discovery opportunities, quality and wage settlement.

Buy and consume individual food/water items. Wash with soap, sleep and save for possessions. Five legal laundry shifts with bread, free tap water and soap fund an installed kettle while leaving 1 CR. The first security jacket contains 3 CR; returning, pocketing and leaving it preserve individual custody. Later laundry yields a damaged Floor 4 training tape, playable through an acquired radio without resolving its mystery.

The status sheet shows five needs and a body portrait with grime, fatigue and bruising feedback. Wages are paid in full. Fractional 12% assessments accumulate into a manual tax account: pay at the bureau every three played days, with one day of grace. Overdue debt flags the citizen for inspection and debt-repayment labor. Historical withholding is preserved without reassessment. Twelve completed shifts earn a vacancy with a modest wage increase and key/certification. Municipal shelter is free; private and apartment deposits, rent, bounded arrears and fallback shelter work. Purchased kettle, mug, radio, blanket, shelf and refrigerator change the home.

Three caught offenses or an overdue-tax inspection trigger a playable correction hall. Scrap-sorting orders supply metal and fabric to the city and retire 1 CR of outstanding tax per order. Tax detainees must clear their debt and complete at least three orders before release; crime-only sentences retain the three-order minimum. A ration bowl, poor bunk and release window support the work. Held belongings, civic record and the exact housing billing pause survive release. This is a compact consequence foundation, not the full proposed prison ecosystem.

## Architecture and invariants

`src/simulation.gd` is a pure deterministic command reducer, with validated locations, custody, work stages, expected revisions, integer money, stored random rolls and exactly one wage settlement. `src/session.gd` is the local authority: save before committing visible state. `src/save_store.gd` writes checksum-verified JSON through a flushed temporary file, replacing the older of two save slots. Invalid newest records fall back to the previous verified generation. Unreadable pairs and future schemas are preserved and block writes. Schema v6 defaults migrate earlier fields and preserve unknown metadata.

`src/main.gd` owns bounded contextual sheets and the backpack view. `presentation.gd` maps saved state to raster art; `prop.gd` displays raster objects/scene crops, and `environment.gd` handles independent ambience. Atlas textures must stay referenced across render frames: temporary resources created only in `_draw()` can show white rectangles on Android. Authored catalogs and normalized zones are under `data/`. UI text bypasses the analogue shader. Every physical work control has a large tap alternative. Android Back closes the current sheet; sound pauses on background; no wall-clock needs/rent penalty applies while absent.

There is no deployed network service. `docs/FUTURE_MULTIPLAYER.md` defines later command validation, ownership transactions and shared aggregates. Do not accept client balances or migrate offline saves into a competitive shared economy without a separate policy.

## Assets and builds

Seventeen original generated raster assets, ten authored scenes and eighteen original synthesized audio files are committed. Prompts, hashes, versions, composition/zone metadata and synthesis source are under `mobile/art/`. Original generation is nondeterministic; checked-in outputs make builds reproducible. Do not replace the palette/camera language piecemeal. Font and engine licenses, including the official 4.7.2-stable third-party COPYRIGHT.txt, are bundled in `mobile/assets/` and included in the exports.

Run `GODOT=/path/to/godot mobile/tools/check.sh`, then `mobile/tools/build.sh` with the same environment. Godot and templates are pinned to 4.7.2. Java 17 and Android SDK components must be configured in Godot editor settings. The official prebuilt template produces minimum API 24 / target API 36. No Gradle or runtime web dependency is required. The Android export includes arm64 and x86_64, requests no internet permission and disables user-data backup. Debug builds are for sideload QA, not store distribution. The Linux export is a convenience artifact.

Build artifacts live in ignored `builds/`. Never commit engine caches, release keystores, player records or secrets. For Android automated touch tests, create an isolated emulator first; the script intentionally refuses to reset an existing registered citizen. Tests use isolated `schism-qa`, `schism-living-qa` and `schism-upgrade-qa` AVDs; existing citizens are never reset.

## Evidence and remaining release gates

Simulation: 405 passing checks. Native UI: 466 passing checks, including a complete laundry sequence and minimum hotspot/horizontal-hint layout at three sizes. Storage: 75 passing checks for placement, ownership, cooling, spoilage, utility interruption, camp custody and migration. A separate ordinary-life balance test uses only valid commands and no injected money/needs. All 584 retained browser rule checks still pass. Asset provenance verification passes.

Android installation, rendering, touch, interruption and resolution evidence is maintained in `docs/playtests/ANDROID.md` and its screenshots/JSON. Read that evidence for the precise tested build and limitations. Automated pass counts prove rules and paths; they do not establish that repetition is compelling to a human.

Remaining: unaided multi-session physical-phone playtests; audible mix and vibration/accessibility review; more object-state, garment-damage and housing art; dedicated private apartment art; broader appearance/clothing art; housing utility failures; job/trust/access content beyond the first vacancy; more authored mystery media; deeper law/camp consequences; production signing and distribution. Cleaning/freight/camp are intentionally smaller than laundry. Most locations retain baked details; laundry has compatible full/empty/open/running state art and raster overlays. Expand other scenes deliberately. Device performance is measured only on the documented emulator; do not claim physical Android GPU coverage.

The new game is a substantial playable foundation and vertical slice. It still needs those polish and release gates to become the extremely strong small game described in the vision.

## 0.2.0 continuation and sideload preview

Laundry cart rows are now physical garment targets. Home storage is explicit: bag, locker or powered refrigerator, with conserved item identity and bounded earned cooling. v3 saves migrate to v4; old fridge households retain the prior food allowance once. An Android in-place upgrade preserved every original field except added schema/storage defaults, and locker retrieval worked after process death. Version code is 2 and the previous debug signing certificate is retained.

The 0.2.0 prerelease is published on GitHub Releases. An unauthenticated HTTPS download returned HTTP 200 and exactly matched the tested APK SHA-256; docs/releases/v0.2.0-publication.json records the receipt. The public APK download and reproducible package/publication steps are in docs/RELEASES.md. Device evidence for this update is in docs/playtests/ANDROID_V020.md and android-v020/. The repository contains source, prompts and evidence; APKs and signing keys stay out of Git. The sideload release is a development prerelease, with the same physical-phone and content-polish gates as before.

## 0.3.0 player-feedback continuation

Travel no longer stacks a door and repeated footstep loop: one soft 260 ms street contact or a muted interior door. Object close-ups, garments, pocket finds, food and possessions use raster art matching the existing scenes. Five built-in imagegen outputs are preserved with prompts, reference hashes, alpha/dimensions and composition notes: backpack interior, transparent 4×4 object atlas, and empty/open/running laundry frames. No source pixels are rewritten; `data/objects.json` defines native atlas regions and crops.

BAG has four actual item targets inside the illustrated compartment per page, deeper-pocket navigation and readable full-size label alternatives. It excludes home storage and installed appliances. Plain bounded Panels with wrapped button text and internal scrolling prevent bureau authorizations from expanding off-screen. Close remains visible. Uniform sorting removes the incoming pile by remaining count, hatch state selects the open frame, and a masked shader turns raster cloth inside damp glass. Reduced effects stops the motion. No new resource charges or save fields were introduced; schema remains 4.

The first native inspection exposed temporary raster-resource lifetime as white blocks despite headless checks; retained atlas/base texture references fixed it, and final device captures use the corrected APK. Do not equate headless layout passes with proof of rendered art. Survival balance and pause-safe ownership remain unchanged. Physical-speaker mix, unaided one-hand comfort and broader mobile GPU coverage still need review. `docs/playtests/ANDROID_V030.md` records measured update, bureau, bag and washer evidence.

The 0.3.0 prerelease is published at https://github.com/madpai/schism/releases/tag/v0.3.0-alpha. Draft APK/manifest checksum verification passed; the unauthenticated public APK returned HTTP 200 and matched the final tested artifact byte for byte. `docs/releases/v0.3.0-publication.json` records the source commit, certificate and SHA-256 receipt. Install over an existing app to retain progress.

## Native Codex development team

`.codex/config.toml` selects GPT-6.1 Sol/high for the lead and enables up to three native child agents. Seven `.codex/agents/*.toml` files pin domain-specific model/effort settings. AGENTS.md explicitly requests automatic delegation for substantial work while keeping trivial edits local, one writer per file, accepted contracts before dependent work, and lead integration/verification. Architecture and economy/persistence use Astra/high; gameplay uses Sol 6.1/medium; exploration uses Luna/medium; content uses Sol 6/medium; Android uses Sol 6.1/high; QA uses Sol 6/high.

See `docs/CODEX_AGENTS.md` for native tool-surface routing, project trust/new-session setup, ownership rules and the read-only demonstration. `python3 scripts/check-codex-agents.py --native` verifies native config loading, account model capabilities and fresh-session lead/instruction defaults; cached validation also works without starting an app-server. Live delegation evidence and limits are in `docs/CODEX_AGENTS_VALIDATION.md`. This infrastructure change does not change gameplay, save schema, assets or release artifacts; existing mobile validation requirements still apply to simulation changes.

## 0.4.0 Living City milestone

The original nine environment images, compatible washer frames, immersive backpack and survival economy are preserved. A tenth original scene, the industrial service corridor, adds a guarded gate, surveillance camera, changing propaganda screen, player-directed relay repair, restored lighting and a recovered count transmission. Street/bureau camera sweeps and passing shadows add restrained surveillance. Effects-off freezes these motions; readable labels bypass scene shaders.

Five physical encounters use authority-owned eligibility, played-day cooldowns and persistent decisions: service-gate paper inspection, hallway neighbor assistance (carry or share carried food), coworker cover after a laundry shift, a once-only service repair and its immediately available discovery. Rewards are actual item instances. Essential travel remains available until a separate overdue-tax enforcement decision. Repair restores corridor lighting, grants a persistent security favor and unlocks the relay immediately; no return-at-a-certain-hour requirement remains. No offline decay, randomly rerolled menus or exclusive character classes were added.

Laundry now loads and collects four garments individually through forgiving drag/tap targets and full-size alternatives. Folding saves each sleeve/hem step, with two folds for medical smocks and three for other garments. Once experienced, citizens can choose familiar bundle actions. Original wash animation, treatment quality, 240-minute work cost and once-only wage settlement are retained. Wages now pay gross, while tax assessments must be settled at the administrative counter.

Five civilian backgrounds supply equal starts, paper mementos and differing contextual knowledge. Existing citizens keep a neutral resident history and every possession. Portrait customization retains the three original tint options; new face/hair/clothing/accessory art remains a future milestone. Schema 6 adds city state, garment progress and manual tax accounts with safe schema-4/5 migration.

The shop defect was confirmed as silhouettes crossing source atlas cell boundaries, rather than a filtering error. The replacement original object sheet uses explicit pixel regions and a validated alpha cutoff/gutter; original atlas and provenance stay committed. New prompts and hashes are in `mobile/art/living-city-provenance.json`. Do not restore equal-grid crop assumptions.

Integrated checks: 405 simulation, 466 native UI, 75 storage, 218 Living City and 109 tax checks passed, plus the ordinary-life balance test and asset provenance/alpha validation. Godot 4.7.2 headless import and Android/Linux exports succeeded. `scripts/android-living-playtest.py` exercises actual Android interaction and records its precise evidence separately; consult `docs/playtests/ANDROID_V040.md` for completed device coverage and limitations. No physical-phone test is claimed.

Next: unaided physical-phone playtesting of tactile work and exploration pacing, followed by a polished canteen or transit scene, more player-directed opportunities and a small consistent portrait/hair/clothing art set. Ordinary gate inspections are optional paper encounters; overdue taxes trigger a street warning and enforcement if direct bureau payment is ignored. Cameras provide atmosphere rather than changing crime detection probabilities. Full patrol agents, curfews, branching personal contacts and universal activity-framework extraction remain deferred.

The 0.4.0 prerelease is published at https://github.com/madpai/schism/releases/tag/v0.4.0-alpha. The draft APK, manifest and checksum file matched the local package byte for byte. The unauthenticated public APK returned HTTP 200 and matched the tested SHA-256. `docs/releases/v0.4.0-publication.json` records the source commit, signer and download receipt. Install over the existing app to preserve your citizen.
