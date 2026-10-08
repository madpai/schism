# SCHISM Android rebuild handoff

**DO NOT TURN SCHISM BACK INTO A MENU-HEAVY DASHBOARD GAME.** The player interacts with a place and its objects. Ordinary work and small possessions should carry the emotional weight.

## Active project and preserved research

`mobile/` is the active Godot 4.7.2 portrait Android game, version 0.2.0. The rebuild branch is `rebuild/android-district-ix`. The browser v0.10 at `0ba675e` was audited before implementation; its source, migrations, assets and tests remain intact. Its former README, architecture, gameplay and handoff are in `docs/legacy/`. `docs/AUDIT.md` maps lessons to the new implementation and records the inventory snapshot.

Do not modify the separate `/home/commander/ashfall` live city, deploy the legacy `.openai` Site, reset existing citizens or reinterpret browser wallets as native saves. Native local persistence is in a separate Android application namespace.

## What you can play

Create a civic identity with a name and appearance tint. Fold the residency paper. Drink at the room sink. Walk through the hallway into a rain-soaked district. Take a bureau ticket, present your ID, and choose one of three bad jobs. Laundry has a full inspect/pocket/sort/load/treat/wash/unload/dry/fold/dispatch/pay sequence. Cleaning and freight have smaller complete physical work orders, discovery opportunities, quality and wage settlement.

Buy and consume individual food/water items. Wash with soap, sleep and save for possessions. Five legal laundry shifts with bread, free tap water and soap fund an installed kettle while leaving 1 CR. The first security jacket contains 3 CR; returning, pocketing and leaving it preserve individual custody. Later laundry yields a damaged Floor 4 training tape, playable through an acquired radio without resolving its mystery.

The status sheet shows five needs and a body portrait with grime, fatigue and bruising feedback. Wages carry fractional 12% tax withholding across settlements. Twelve completed shifts earn a vacancy with a modest wage increase and key/certification. Municipal shelter is free; private and apartment deposits, rent, bounded arrears and fallback shelter work. Purchased kettle, mug, radio, blanket, shelf and refrigerator change the home.

Three caught offenses trigger a playable correction hall: three unpaid scrap-sorting orders, ration bowl, poor bunk and a release window. Held belongings, civic record and the exact housing billing pause survive release. This is a compact consequence foundation, not the full proposed prison ecosystem.

## Architecture and invariants

`src/simulation.gd` is a pure deterministic command reducer, with validated locations, custody, work stages, expected revisions, integer money, stored random rolls and exactly one wage settlement. `src/session.gd` is the local authority: save before committing visible state. `src/save_store.gd` writes checksum-verified JSON through a flushed temporary file, replacing the older of two save slots. Invalid newest records fall back to the previous verified generation. Unreadable pairs and future schemas are preserved and block writes. Schema v4 defaults migrate earlier fields and preserve unknown metadata.

`src/main.gd` owns the scene and contextual sheets; `prop.gd` and `environment.gd` draw independent interactive/animated objects. Authored catalogs and normalized zones are under `data/`. UI text bypasses the analogue shader. Every physical work control has a large tap alternative. Android Back closes the current sheet; sound pauses on background; no wall-clock needs/rent penalty applies while absent.

There is no deployed network service. `docs/FUTURE_MULTIPLAYER.md` defines later command validation, ownership transactions and shared aggregates. Do not accept client balances or migrate offline saves into a competitive shared economy without a separate policy.

## Assets and builds

Ten original generated raster assets, nine authored scenes and eighteen original synthesized audio files are committed. Prompts, hashes, versions, composition/zone metadata and synthesis source are under `mobile/art/`. Original generation is nondeterministic; checked-in outputs make builds reproducible. Do not replace the palette/camera language piecemeal. Font and engine licenses, including the official 4.7.2-stable third-party COPYRIGHT.txt, are bundled in `mobile/assets/` and included in the exports.

Run `GODOT=/path/to/godot mobile/tools/check.sh`, then `mobile/tools/build.sh` with the same environment. Godot and templates are pinned to 4.7.2. Java 17 and Android SDK components must be configured in Godot editor settings. The official prebuilt template produces minimum API 24 / target API 36. No Gradle or runtime web dependency is required. The Android export includes arm64 and x86_64, requests no internet permission and disables user-data backup. Debug builds are for sideload QA, not store distribution. The Linux export is a convenience artifact.

Build artifacts live in ignored `builds/`. Never commit engine caches, release keystores, player records or secrets. For Android automated touch tests, create an isolated emulator first; the script intentionally refuses to reset an existing registered citizen. The test author used only a newly created `schism-qa` AVD.

## Evidence and remaining release gates

Simulation: 405 passing checks. Native UI: 109 passing checks, including a complete laundry sequence and minimum hotspot/horizontal-hint layout at three sizes. Storage: 75 passing checks for placement, ownership, cooling, spoilage, utility interruption, camp custody and migration. A separate ordinary-life balance test uses only valid commands and no injected money/needs. All 584 retained browser rule checks still pass. Asset provenance verification passes.

Android installation, rendering, touch, interruption and resolution evidence is maintained in `docs/playtests/ANDROID.md` and its screenshots/JSON. Read that evidence for the precise tested build and limitations. Automated pass counts prove rules and paths; they do not establish that repetition is compelling to a human.

Remaining: unaided multi-session physical-phone playtests; audible mix and vibration/accessibility review; richer layered garment/machine animation; dedicated private apartment art; broader appearance/clothing art; housing utility failures; job/trust/access content beyond the first vacancy; more authored mystery media; deeper law/camp consequences; production signing and distribution. Cleaning/freight/camp are intentionally smaller than laundry. Backgrounds have baked details that later layered art should replace. Device performance is measured only on the documented emulator; do not claim physical Android GPU coverage.

The new game is a substantial playable foundation and vertical slice. It still needs those polish and release gates to become the extremely strong small game described in the vision.

## 0.2.0 continuation and sideload preview

Laundry cart rows are now physical garment targets. Home storage is explicit: bag, locker or powered refrigerator, with conserved item identity and bounded earned cooling. v3 saves migrate to v4; old fridge households retain the prior food allowance once. An Android in-place upgrade preserved every original field except added schema/storage defaults, and locker retrieval worked after process death. Version code is 2 and the previous debug signing certificate is retained.

The public APK download and reproducible package/publication steps are in docs/RELEASES.md. Device evidence for this update is in docs/playtests/ANDROID_V020.md and android-v020/. The repository contains source, prompts and evidence; APKs and signing keys stay out of Git. The sideload release is a development prerelease, with the same physical-phone and content-polish gates as before.
