# Manual work and paperwork 0.5.0 validation

Godot 4.7.2 Compatibility, package `org.schism.districtix`, version code 5, schema 6. Final exported APK SHA-256: `b6d154f73a5f22257834b711f81e3ccba74660ae56176a1bccaedd22e74fba7a`. The signer matches 0.4.0: `9977fa443d50a847973a2031409cad7978b93846e1bc9ae4eb31f35b64072c07`.

## Integrated checks

`mobile/tools/build.sh` passed headless import, 507 simulation, 773 UI, 86 storage, 218 Living City, 109 tax, 253 manual-work and 41 gesture checks: 1,987 passed, zero failed. The ordinary-life test completed five manually handled shifts, meals, soap, 4 CR manual tax and an installed kettle with 1 CR left. Asset validation passed for eighteen generated images, ten scene maps and eighteen original audio files. Android and Linux exports succeeded.

Regression coverage rejects bulk laundry commands atomically even after previous shifts, checks individual command replay, original batch time/quality and once-only settlement, schema-4 stage migration, interrupted work and unknown custody metadata. UI checks cover exclusive vacancy selection, cancellation, signature replay and clipboard bounds at three sizes. Gesture checks send actual viewport input in both emulated-mouse/native-touch orders, outside release, cancellation, focus loss and immediate normal scroll recovery.

## Android evidence

The explicitly created isolated `schism-paper-qa` AVD (`emulator-5584`) runs Android 14 x86_64 with swangle/ANGLE. No original citizen was reset and no save payload was injected. Reads of verified save envelopes supply assertions; committed evidence contains hashes, summaries and screenshots only. See [touch receipt](android-v050/touch-evidence.json) and `scripts/android-paperwork-playtest.py`.

Registration began on intermediate APK `a4030485944965f105a70c70b7cf86d7a0c4a51562c539449868d50b8d479865`. The final APK was installed over that marked citizen before completed clipboard, laundry and survival checks; that intermediate update shares schema 6. Unit migration tests establish older-stage compatibility; this update does not claim a separate native 0.4-to-0.5 upgrade flow.

Native captures inspect the clipboard at 360×640, 390×844 and 1080×2400. Checking and switching a vacancy leave authority state unchanged; process death discards the unsigned draft; signing assigns employment with one revision increment. Source art preserves the metal clip and board proportions while extending the parchment for long accessible forms. Screenshot inspection confirms readable ink, isolated garments and bounded controls.

Native garment loading, collection and a partial fold retained every saved field through background, force-stop and relaunch. The completed individual shift achieved 100% quality; the original washer animation showed RGB RMS 24.04 between captured glass frames. Wage and tax paperwork were also inspected at all three sizes without transactions. The wage paid 7 CR once and remained unchanged after relaunch. Buying and eating bread, drinking and sleeping completed the daily survival loop. A second shift offered no familiar bundle controls; all garments still needed individual loading, and its single saved load survived relaunch. Android logs contained no GDScript or parse errors.

The harness initially used the clerk instead of the vacancy notice after identification and failed OCR on dark controls at the smallest size. Correcting the route and adding inverted enlarged OCR passes fixed the harness; app state was retained throughout. Measured drag frames test parent-label displacement during real 1.8-second Android swipes, followed immediately by blank-space scrolling. These are native input measurements, not simulated reducer commands. Loading label measurements varied by 1.19/1.13 pixels (OCR rounding); collection captured zero drift in both mid-gesture frames. Collection scrolling moved a matching painted patch 204 pixels with mean RGB error 0.54; the initial label-only assertion missed this because its label was clipped. The [separate image measurement](android-v050/unload-scroll-measurement.json) preserves that evidence.

## Limits and next checks

Emulator coverage does not establish physical-phone comfort, speakers, vibration, broader GPU performance or unaided long-term pacing. Signing is a forgiving tap, not freehand handwriting. Artwork now covers key paperwork and additional home/work close-ups; every interaction does not yet have a bespoke image. Original environments, backpack and washer motion remain intact. Next: physical-phone feedback, dedicated object-state art where it adds tactile feedback, deeper repair/contact consequences and consistent appearance variations.
