#!/usr/bin/env bash
set -euo pipefail
root_dir="$(cd "$(dirname "$0")/.." && pwd)"
godot_bin="${GODOT:-godot}"
build_dir="${SCHISM_BUILD_DIR:-$root_dir/../builds}"
mkdir -p "$build_dir"
"$root_dir/tools/check.sh"
for platform in Android Linux; do
  artifact="$build_dir/schism-android-debug.apk"
  [[ "$platform" == Linux ]] && artifact="$build_dir/schism-linux.x86_64"
  build_log="$(mktemp)"
  "$godot_bin" --headless --path "$root_dir" --export-debug "$platform" "$artifact" > "$build_log" 2>&1
  if rg -q 'ERROR:' "$build_log" || [[ ! -s "$artifact" ]]; then cat "$build_log"; rm "$build_log"; exit 1; fi
  rm "$build_log"
  sha256sum "$artifact"
done
