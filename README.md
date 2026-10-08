# SCHISM — District IX

A native, portrait-first Android point-and-click life simulation. You arrive with 4 CR, a municipal room, and no job. Visit the labor bureau, inspect and wash uniforms, buy something to eat, return home, and save for a kettle. You are an ordinary citizen. The city feels wrong.

**DO NOT TURN SCHISM BACK INTO A MENU-HEAVY DASHBOARD GAME.** The room, street and workplace are the game. The bed, sink, pocket, hatch and service window are its controls.

The active game is [`mobile/`](mobile/), built with **Godot 4.7.2, GDScript and the Compatibility renderer**. It works offline and saves each accepted interaction. The original browser/server prototype remains intact as research, with its previous documentation in [`docs/legacy/`](docs/legacy/). The native build does not connect to or modify that city's citizens.

## Play

Open `mobile/project.godot` in Godot 4.7.2 and run. On Android, install the debug APK produced below. The package is `org.schism.districtix`. This is a playable development slice, not a production store release.

Tap objects in the current scene. Follow doors through the hallway to the street. At the bureau, take a ticket and present your ID. All three jobs are playable; laundry has the most developed interaction sequence. CIVIC ID opens your body/needs/employment record. BAG contains individual possessions. Settings include sound, reduced effects and object hints.

Nine illustrated locations, five needs, local identity, three jobs, taxes, petty theft and evidence, playable labor-camp orders, earned vacancies, rent and room possessions are implemented. Damaged media remains unexplained. No multiplayer service or monetization is required.

## Check and build

Install Godot **4.7.2** and its matching official export templates. Android export needs Java 17 and the Android SDK configured in Godot's editor settings. The prebuilt template currently produces an APK with minimum API 24 and target API 36. Use the SDK components required by that pinned template; do not set Gradle-only SDK overrides on the prebuilt export.

```sh
GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64 mobile/tools/check.sh
GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64 mobile/tools/build.sh
```

The check runs the headless simulation and native UI tests, verifies original asset hashes and checks scene zones. The build creates `builds/schism-android-debug.apk` and `builds/schism-linux.x86_64`, then prints their SHA-256 hashes. Build outputs and keystores are ignored by Git. Store signing is a separate release step; never commit a keystore.

For Android touch, interrupted-work and resolution testing on a **fresh, isolated emulator**:

```sh
adb -s emulator-5584 install --no-incremental builds/schism-android-debug.apk
python3 scripts/android-playtest.py --device emulator-5584 --adb /path/to/adb
```

The playtest uses `tesseract` and real Android taps. It refuses to reset an existing citizen. Use the emulator's `swangle` GPU backend if its obsolete SwiftShader GLES backend fails Godot's uniform limits. See [`docs/playtests/ANDROID.md`](docs/playtests/ANDROID.md) for measured evidence and limits.

## Design and handoff

Start with [`docs/VISION.md`](docs/VISION.md), [`docs/GAMEPLAY.md`](docs/GAMEPLAY.md), [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), [`docs/AUDIT.md`](docs/AUDIT.md), and [`HANDOFF.md`](HANDOFF.md). The [roadmap](docs/ROADMAP.md) distinguishes implemented foundations from the remaining polish and release gates.

The pure command reducer separates simulation from scenes, local save storage and future authority. Saves contain a versioned payload, checksum and two recoverable generations. Time advances through actions, shifts and sleep; the game does not punish absence. Original generated visual prompts, final assets, hotspot maps and provenance live in `mobile/art/`; original audio synthesis is checked in. Bundled font and engine attribution is in [`mobile/assets/ATTRIBUTION.md`](mobile/assets/ATTRIBUTION.md).

For the retained browser prototype's setup, Cloudflare hosting and test commands, use [`docs/legacy/README_BROWSER.md`](docs/legacy/README_BROWSER.md). Do not deploy the legacy worker or reset a live database as part of native development.
