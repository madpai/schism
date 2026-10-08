# Android sideload distribution

SCHISM development APKs are hosted as versioned prereleases in [GitHub Releases](https://github.com/madpai/schism/releases). This repository is public; no account is needed to download a published APK. This serves the Android package and is independent of the legacy browser city and its hosting.

## 0.2.0 preview

[Download SCHISM 0.2.0 APK](https://github.com/madpai/schism/releases/download/v0.2.0-alpha/schism-0.2.0.apk)

[Release notes and checksums](https://github.com/madpai/schism/releases/tag/v0.2.0-alpha)

Download on Android, open the APK, and allow installation from that browser if Android asks. This is a development preview using the existing debug signer. Android 7.0 / API 24 or later, arm64 or x86_64. It is not a Play Store release. If updating 0.1.0, install over it: **do not uninstall to update**, because uninstalling deletes your local citizen. The package stays `org.schism.districtix`, version code increases to 2, and the signing certificate stays the same. Saves migrate from schema 3 to 4 without resetting progress.

This update gives the locker and refrigerator actual contents, separates carried items from home storage, and replaces the laundry cart's uniform list with large garment targets. Only food physically stored in a powered refrigerator earns extra preservation time. Existing food from a 0.1.0 household with a refrigerator keeps its prior allowance once during migration. No offline survival decay was added.

## Reproduce a package

Build and test, commit the tested source/evidence, then package the APK:

```sh
GODOT=/path/to/godot mobile/tools/build.sh
python3 mobile/tools/package-sideload.py --sdk /path/to/android/sdk \
  --previous builds/previous/schism-0.1.0.apk
```

`--previous` is optional for a first distribution and required in our update verification. The packaging tool checks a clean source tree, compiled package/version, APK signature and update compatibility, then writes a versioned APK, `manifest.json` and `SHA256SUMS` into ignored `builds/sideload/`. It refuses to replace a packaged version with different bytes. Preserve signing keys outside Git; never distribute them.

For a new version, update the project/preset version and increment Android version code. Keep application identity and signing key stable. Publish a new tag; never silently replace an old version's APK.

## Publish and verify

Create a draft prerelease from the exact tested commit, upload the three package files, download them back and verify the checksums before making the release public. Use `--target` explicitly: this rebuild currently lives on `rebuild/android-district-ix`, not the old browser main branch.

```sh
gh release create v0.2.0-alpha --repo madpai/schism --draft --prerelease \
  --target COMMIT_SHA --title 'SCHISM 0.2.0 — District IX preview' \
  --notes-file docs/releases/v0.2.0-alpha.md \
  builds/sideload/schism-0.2.0.apk builds/sideload/manifest.json builds/sideload/SHA256SUMS
gh release download v0.2.0-alpha --repo madpai/schism --dir /tmp/schism-release-verify
gh release edit v0.2.0-alpha --repo madpai/schism --draft=false --prerelease
```

Verify SHA256SUMS in the download directory before the edit. After publication, download the HTTPS APK without authentication and compare its hash to the tested local artifact. Record measured device coverage in `docs/playtests`; keep physical-phone sound, ergonomics and broader GPU coverage as release gates.
