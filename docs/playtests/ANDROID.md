# Android vertical-slice evidence

Test date: 2026-10-08. Active project: Godot 4.7.2 / Compatibility renderer / SCHISM 0.1.0. The debug APK is a sideload development build; no store release or physical-phone certification is claimed.

## Repeatable checks

```sh
GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64 mobile/tools/check.sh
GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64 mobile/tools/build.sh
adb -s emulator-5584 install --no-incremental builds/schism-android-debug.apk
python3 scripts/android-playtest.py --device emulator-5584 --adb /path/to/adb
```

Use a fresh isolated AVD. The playtest refuses an existing registered citizen and never clears data. It uses ADB touch/Back/Home, OCR to locate contextual controls, screenshots, and checksum-verified inspection of this debug application's private QA save. It does not bypass the game reducer or inject resources. Screenshot reads retry incomplete ADB PNG transfers; bin taps target the matching words rather than the midpoint between two adjacent buttons.

Headless checks: **405 simulation checks, 101 native UI checks, zero failures**. The native UI sequence includes registration, ticket/ID/application, inspecting four uniforms and their pockets, custody choices, machine preparation, wash/dry/fold/dispatch and wage settlement. It checks minimum hotspot sizes, horizontal object labels and overlays at three portrait sizes. The ordinary-life balance test runs five shifts, food, tap water, washing and sleep through valid commands: 4 CR tax paid, kettle installed, 1 CR remaining, healthy and rested. Assets: ten original generated images, nine zone maps, eighteen original synthesized audio files; hashes and prompt/zone provenance verified. Retained browser tests: **584 checks pass**.

## Device configuration and coverage

Isolated AVD `schism-qa`, Android 14 / API 34, x86_64 Google APIs, Pixel 7 profile, 1080×2400, density 420. Started with:

```sh
emulator -avd schism-qa -port 5584 -no-window -no-audio -no-snapshot -no-boot-anim -gpu swangle
```

The ANGLE SwiftShader GLES 3.1 renderer runs the scene and condition shaders. Warm restarts sometimes warn that the cached shader binary cannot load, then recompile successfully; the runtime log preserves that warning. The older `swiftshader_indirect` emulator backend failed shader linking because its fragment uniform limit is too low; this was an emulator backend failure, resolved by selecting the supported ANGLE backend. See the [upstream renderer issue](https://github.com/godotengine/godot/issues/109550). This is not evidence of physical phone performance.

The touch loop covers arrival/identity, free sink water, navigation, bureau ticket and ID, laundry employment, four uniforms, returned security-pocket credits, detergent/cycle/hatch controls, washer completion, quality 100 and exactly one 7 CR payment. It presses Home, force-stops and relaunches halfway through washer preparation, then compares **every simulation field** before/after. After food, bottled water, soap, washing and sleep, it repeats interruption and checks status at 360×640 and 390×844 with density 160, and 1080×2400 with density 420. Supplemental real-device inputs also verify screen-off/wake and persistence of the object-label setting. Android Back must close sheets without quitting; Godot's default `quit_on_go_back` is explicitly disabled ([engine property documentation](https://docs.godotengine.org/en/stable/classes/class_scenetree.html#class-scenetree-property-quit-on-go-back)).

`android/touch-evidence.json` records individual taps/assertions, display densities, the installed APK hash and final state. Fixed bottom-dock controls use known geometry when small-text OCR is ambiguous. `android/runtime.txt` records the tested Godot/Android runtime log. The screenshots are actual device captures, not visual mockups. Key frames: room, street, bureau, vacancies, laundry, found object, resumed washer, wage slip and the post-shift room/status at the tested sizes.

## Artifact and measurement limits

The official prebuilt template's APK reports minimum API 24, target/compile API 36. arm64-v8a and x86_64 are included. APK v2/v3 signature verification passes with the debug signer. No internet/network permission is requested. The APK is approximately 69.7 MiB, and the embedded Linux convenience build approximately 85.7 MiB. SHA-256 is printed by the build script, recorded for the APK in the touch evidence, and recorded for both builds in `builds.json`. The final APK hash matches the installed application. The Linux artifact also starts headlessly without script errors; its graphical desktop flow was not separately tested.

A representative post-shift emulator memory sample was about 164 MiB total PSS / 249 MiB RSS. This is an observation, not a target-phone budget or frame-rate result. No physical ARM device was used, no speaker/headphone audio mix was reviewed, no phone call was injected, and no battery/thermal/startup-performance or human retention measurement was made. Home/background plus force-stop/relaunch demonstrates process-death recovery on this emulator; save corruption/interrupted-write recovery is separately covered by real-file headless tests.

Next release gates: unaided multi-session physical-phone playtests, sound mix and accessibility review, additional GPU/device coverage, authored work/content polish, release signing and distribution. Do not describe this development build as production-ready on the strength of automated checks.
