#!/usr/bin/env bash
set -euo pipefail
root_dir="$(cd "$(dirname "$0")/.." && pwd)"
godot_bin="${GODOT:-godot}"
log_dir="$(mktemp -d)"
trap 'rm -rf "$log_dir"' EXIT
if [[ "$($godot_bin --version)" != 4.7.2* ]]; then
  echo 'SCHISM is pinned to Godot 4.7.2. Set GODOT to that executable.' >&2
  exit 1
fi
"$godot_bin" --headless --path "$root_dir" --editor --import --quit > "$log_dir/import.txt" 2>&1
if rg -q 'SCRIPT ERROR|ERROR:' "$log_dir/import.txt"; then cat "$log_dir/import.txt"; exit 1; fi
"$godot_bin" --headless --path "$root_dir" --script tests/run.gd > "$log_dir/rules.txt" 2>&1
cat "$log_dir/rules.txt"
"$godot_bin" --headless --path "$root_dir" --script tests/ui.gd -- --save-dir="$log_dir/ui-residency" > "$log_dir/ui.txt" 2>&1
cat "$log_dir/ui.txt"
if rg -q 'SCRIPT ERROR|ERROR:|FAIL' "$log_dir/rules.txt" "$log_dir/ui.txt"; then exit 1; fi
"$godot_bin" --headless --path "$root_dir" --script tests/balance.gd > "$log_dir/balance.txt" 2>&1
cat "$log_dir/balance.txt"
if rg -q 'SCRIPT ERROR|ERROR:|FAIL' "$log_dir/balance.txt"; then exit 1; fi
"$godot_bin" --headless --path "$root_dir" --script tests/storage.gd > "$log_dir/storage.txt" 2>&1
cat "$log_dir/storage.txt"
if rg -q 'SCRIPT ERROR|ERROR:|FAIL' "$log_dir/storage.txt"; then exit 1; fi
python3 "$root_dir/art/validate.py"
