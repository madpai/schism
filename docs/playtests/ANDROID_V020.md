# 0.2.0 storage and sideload preview evidence

Date: 2026-10-08. Godot 4.7.2 / Compatibility renderer. Android 14 API 34 x86_64 ANGLE emulator, the same isolated `schism-qa` AVD documented in ANDROID.md. No physical phone or audio-mix review is claimed.

## Rules and interface

405 core simulation checks, 75 new storage checks and 109 native GUI checks pass. Storage covers ownership/serial conservation, home-only access, fridge placement, action-time cooling, three-day preservation cap, power interruption, spoilage, cold-food retrieval, old-allowance migration, serial-counter recovery, camp belongings and real-file save/load. The five-shift ordinary-life balance still funds meals, soap, tax and an installed kettle with 1 CR left, without injected resources. Art/audio provenance verification passes.

The native UI completes laundry through the garment rack and tests storing/retrieving food through real contextual controls. Garment targets are 176 logical units tall; the phone flow retains all large tap alternatives. The existing minimum-target and edge-clipping checks remain.

## Existing save upgrade

The emulator still held the 0.1.0 citizen, schema 3. Installing 0.2.0 with `adb install --no-incremental -r` succeeded. After the first explicit save, comparison showed every prior field unchanged except schema 4 and each item's new `storage`/`cold_minutes` defaults. Credits, needs, identity, employment, completed shift, item IDs, records and settings were preserved. Placing soap in the locker, force-stopping and relaunching, then taking it back worked through device taps. Evidence: `android-v020/upgrade-evidence.json`, before/after upgrade and locker captures.

Both APKs verify with signing-certificate SHA-256 `9977fa443d50a847973a2031409cad7978b93846e1bc9ae4eb31f35b64072c07`. Package remains `org.schism.districtix`; version code rises from 1 to 2. This is the existing development debug signer, not production signing.

## Fresh touch loop

A fresh QA profile completes arrival, free water, bureau ticket/ID/application, all four uniforms, pocket custody, treatment and washer controls, process death with two doses loaded, wash/dry/fold/dispatch, quality 100, exactly one 7 CR payment, food/water/soap, home washing and sleep. Final wallet: 6 CR; energy 100; health 95. Status displays needs at 360×640 and 390×844 / density 160, and 1080×2400 / density 420. No script crash, Java crash or shader-link failure. ANGLE warm starts may recompile cached shaders; raw logs retain those warnings. Evidence: `android-v020/touch-evidence.json`, `touch-flow.txt`, `runtime.txt` and actual device screenshots, including the garment cart.

```sh
python3 scripts/android-playtest.py --device emulator-5584 \
  --adb /path/to/adb --output docs/playtests/android-v020
```

Requires Python 3, Pillow, adb and Tesseract. Use a fresh isolated citizen; the script never clears an existing profile. Launch waits for civic/game interface text, and capture rejects blank frames, so arrival and recovery evidence excludes the loading splash. OCR sorting ignores service-label text when selecting the physical bin; early recapture attempts exposed that test-driver ambiguity, not a simulation failure. The test author reset only the newly created QA application to run the fresh flow, after retaining the separate in-place upgrade evidence. No legacy browser or actual user saves were touched.

## Refrigerator device fixture

An explicitly seeded **isolated QA fixture** starts in the shop with 200 CR to cover the 60 CR appliance without replaying many shifts. Device taps buy the cabinet and bread, return home, install the cabinet, place bread inside it, sleep, interrupt the app, inspect stored food and eat it. Sleep banks exactly 480 minutes of actual refrigeration. This proves the device path, not earned progression or balance. `fridge-evidence.json` labels the fixture and records its object history; screenshots show the installed appliance and stored food.

Repeat this optional fixture only on an isolated emulator:

```sh
python3 scripts/android-fridge-playtest.py --device emulator-5584 \
  --adb /path/to/adb --output docs/playtests/android-v020 --allow-qa-fixture
```

The reusable fixture requires that explicit flag and restores both prior save generations in `finally`. Production gameplay contains no credit injection or debug funding action.

## Distribution

The APK verifies its signature, package, version 0.2.0, minimum API 24 and target API 36. `mobile/tools/package-sideload.py` compares the previous signer/version, checks committed source, and produces a versioned APK, provenance manifest and checksums. Public download URLs and release notes are documented in RELEASES.md. Uploaded bytes must be downloaded again and hash-verified before publication. Physical-phone performance, sound, accessibility and deeper authored content remain release gates.
