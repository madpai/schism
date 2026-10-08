# 0.3.0 objects, layout and work-state evidence

2026-10-08. Godot 4.7.2 / Compatibility. Android 14 API 34 x86_64 emulator, ANGLE SwiftShader, isolated `schism-qa` at port 5584. Physical-speaker mix, unaided ergonomics and broader Android GPU coverage are not claimed.

## Automated checks

405 core rule checks, 75 storage checks and 272 native UI checks pass. The ordinary five-shift balance still funds meals, soap, taxes and an installed kettle with 1 CR left, without injected resources. Fifteen generated rasters, nine authored scenes and eighteen original audio files pass prompt, reference, asset hash, dimension, atlas-region and zone checks. Android and embedded Linux exports succeed.

New UI coverage verifies actual laundry controls, visible cart count and hatch/running state, an open door during drying/folding, viewport-bounded bureau/registration/settings/status sheets, wrapped action widths, an always-visible close target, real backpack item inspection, four-item compartments and deeper-pocket paging at three logical sizes. The seven-item pagination case is a UI placement fixture; it is not an earned-inventory or balance claim.

## In-place update

The actual 0.2.0 APK was installed with its retained citizen before installing 0.3.0 over it. Every simulation field compared equal: schema, identity, needs, credits, employment, history, item metadata, settings and legal state. A retained item rendered inside the backpack; force-stop/relaunch retained every field. Evidence: `android-v030/upgrade-evidence.json`, before/after upgrade and retained/resumed backpack captures. Same package/signing key, version code 3; schema remains 4.

Only the isolated emulator's QA save generations were backed up and restored. Fresh-flow resets apply to this QA app, after preserving upgrade evidence. No actual user, legacy browser or live server data was touched.

## Native touch and rendering

The `--presentation` flow creates a fresh citizen, takes water, visits the bureau, reads all three job papers at 360×640, 390×844 and 1080×2400, signs laundry, inspects and sorts four uniforms, returns the found credits, loads/treats the washer, interrupts the app with both doses saved, completes wash/dry/fold/dispatch and receives one 7 CR wage. It then buys bread, taps its actual image inside the backpack to inspect its serial record, eats/drinks, buys soap, returns home, washes and sleeps. Final wallet is 6 CR; energy 100; health 95. Status/scene recovery is checked at the same three sizes.

Actual scene captures show a partly emptied incoming cart, empty cart, open hatch, raster inspection and two successive running frames. The recorded RGB RMS difference within the washer glass region confirms rendered motion; `touch-evidence.json` records its measured value and rectangle. Animation does not settle another work transaction. No native script crash, Java crash or GLES program-link failure is present in `runtime.txt`.

Early native inspection exposed a raster-resource lifetime issue: `_draw()`-local atlas resources produced white rectangles despite headless success. Retaining the base/atlas resources fixed it. The final captures and release APK use retained resources. The test driver now allows a renderer settling interval between taps; this avoids selecting stale button positions while new textured sheets appear. Do not replace native raster inspection with headless-only assertions.

```sh
python3 scripts/android-playtest.py --device emulator-5584 \
  --adb /path/to/adb --output docs/playtests/android-v030 --presentation
```

Requires Python 3, Pillow, Tesseract and an explicitly selected isolated emulator. The runner itself never resets a registered profile. Its original default flow and `--verify-resume` path remain available.

## Travel audio

`audio-evidence.json` compares the deterministic PCM source and configured runtime gain. The repeated 1.2-second footsteps were replaced by a single 0.26-second filtered contact at -27 dB; interior doors use -23 dB and work controls -12 dB. One cue plays per travel transition. Waveform and gain measurements prove reduction, not a physical-phone listening preference.

## Provenance and distribution

Five new built-in imagegen outputs are preserved unchanged: `backpack-v1.png`, `objects-v1.png`, `laundry-empty-v2.png`, `laundry-open-v2.png` and `laundry-running-v2.png`. Prompts and style/edit references are hashed in `mobile/art/provenance.json`. `mobile/data/objects.json` defines sixteen transparent atlas cells, original-scene crops, the backpack compartment and washer geometry. Runtime crops leave source pixels untouched.

The versioned sideload package includes an APK, exact source manifest and checksums. Draft downloads and the unauthenticated published HTTPS download must match the tested local artifact. `docs/RELEASES.md` documents installation and signing compatibility; publication receipts live in `docs/releases/`.
