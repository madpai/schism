# Living City 0.4.0 validation

Godot 4.7.2, Compatibility renderer; Android package `org.schism.districtix`, version code 4, schema 6. The tested debug APK has SHA-256 `b8ae7a7b60a8b184a5816ae938f681c0c347ecab56d3a6c7c140044a6ba599d6`. Original scenes and washer frames are preserved. The same tested sideload package is published as `v0.4.0-alpha`; `docs/releases/v0.4.0-publication.json` records download verification.

## Integrated checks

`mobile/tools/build.sh` completed headless import, 405 simulation checks, 466 UI checks, 75 storage checks, 218 Living City checks and 109 tax checks: 1,273 passed, none failed. The ordinary-life balance test completes five shifts with food, soap, manual payment of 4 CR tax and an installed kettle, leaving 1 CR without injected resources. Asset validation checks 17 images, ten scene maps and eighteen original audio files, provenance hashes, exact object regions, connected silhouettes and transparent gutters. Android and Linux exports succeeded.

The independent native QA specialist reviewed settlement, migration, billing chronology, debt allocation, camp work, replay rejection, clothing commands and saved RNG. Review exposed an unreachable overdue payment route and missing authoritative records being defaulted. Both were corrected: direct street-to-bureau travel remains available after a warning, and incomplete schema-6 tax/city/detention records enter recovery instead of erasing debt or progress.

## Native interaction evidence

Tests use explicitly created isolated Android emulators, real touch/OCR input and reads of verified private save envelopes. No citizen was reset or save payload injected. Resume markers identify only each runner’s isolated citizen. Only hashes, summaries, phase checkpoints and screenshots are retained. The emulator uses `swangle`/ANGLE because its obsolete SwiftShader GLES backend exceeded Godot shader uniform limits. No physical phone testing is claimed.

The Living City runner's first phases used intermediate APKs while validating individual loading, unloading and folds, interruption at each partial stage, backgrounds, neighbor/coworker choices, repairs, shop art, backpack consumption and the home survival loop. The saved citizen then continued on the tax build. A final UI-only change moved familiar bundle controls above the clothing surface; subsequent detention and upgrade evidence uses that final APK. Evidence distinguishes resumed phases and prior failures; earlier captures must not be presented as captures of the final tax build. Final native results are recorded in the linked JSON receipts.

During native testing, three defects were fixed: JSON-restored float minutes in encounter queries, long subtitles pushing the bottom dock outside the viewport, and a clothing control swallowing scrolling from blank areas. The runner also corrected OCR searches and authored food names; these harness failures did not mutate saves or require resets. Familiar bundle controls were moved above the clothing surface after the repeat-work test exposed a buried shortcut. Android screenshots were inspected for garment isolation, item fragments, bounded controls, bureau text and the service scene.

- [Living City touch receipt](android-v040/touch-evidence.json): tactile and familiar laundry, washer frame difference, 360×640 / 390×844 / 1080×2400 layouts, persistence, food/home loop and physical gate inspection.
- [Tax touch receipt](android-tax-v040/touch-evidence.json): full gross pay, manual office payment, played-time invoice/grace, street warning, ignored payment, city-supply detention and release.
- [Repeat-work receipt](android-repeat-v040/touch-evidence.json): final APK shortcut placement, all garments loaded/collected, quality-100 settlement and process-death recovery.
- [Upgrade receipt](android-upgrade-v040/upgrade-evidence.json): in-place 0.3 schema-4 upgrade with a partial work order and owned food preserved.

## Scope and limitations

One polished service corridor adds repair-driven exploration, restored lighting, a persistent security favor and an immediately available recording. Five encounters have saved prerequisites, choices and cooldowns. Backgrounds have equal starts, paper mementos and contextual knowledge; expanded face/hair/clothing artwork remains deferred. Cameras, propaganda and patrol shadows are atmospheric; repair favor shortens a voluntary paper inspection rather than granting immunity from tax or crime. Camp supply production is local saved state, ready for later shared-city integration; there is no multiplayer service.

Folding uses simple raster region changes and forgiving taps; common actions remain accessible through large alternatives and familiar bundle work. Native tests establish rendering, commands and recovery on the documented emulator. They do not establish unaided phone comfort, sound mix, physical GPU performance or long-term pacing. Next milestone: unaided physical-phone feedback, deeper repair/contact consequences, a canteen or transit scene, and consistent portrait/clothing variations.

Reproduce on fresh isolated emulators with `scripts/android-living-playtest.py --extended`, then `scripts/android-tax-playtest.py --citizen-evidence <living evidence>`. Its `--repeat-only` mode tests familiar controls on the same marked experienced citizen in a new evidence directory. Run `scripts/android-upgrade-playtest.py` on a separate fresh emulator with the previous and current APKs. All runners accept explicit `--device`, `--adb` and `--output`; no reset command is used.
