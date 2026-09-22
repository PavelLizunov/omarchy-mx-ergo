#!/usr/bin/env bash

set -euo pipefail

plugin_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== 1. Validating manifest.json syntax ==="
python3 -m json.tool "$plugin_dir/manifest.json" >/dev/null

echo "=== 2. Running omarchy plugin validate ==="
omarchy plugin validate "$plugin_dir"

echo "=== 3. Checking for symlinks (must be zero) ==="
symlinks="$(find "$plugin_dir" -type l)"
if [[ -n "$symlinks" ]]; then
  echo "FAIL: Symlinks found in plugin tree:" >&2
  echo "$symlinks" >&2
  exit 1
fi
echo "Zero symlinks verified."

echo "=== 4. Checking for hardcoded hex colors ==="
python3 -B - "$plugin_dir" <<'PY'
import pathlib, re, sys
root = pathlib.Path(sys.argv[1])
for path in [*root.glob('*.qml'), *root.glob('assets/*.svg')]:
    for match in re.finditer(r'#[0-9a-fA-F]{3,8}\b', path.read_text()):
        if path.suffix == '.svg' and match[0].lower() in ('#fff', '#ffffff'):
            continue
        raise SystemExit(f'FAIL: Hard-coded display color in {path.name}: {match[0]}')
print("Zero hardcoded hex colors verified.")
PY

echo "=== 5. Running Model contract tests ==="
node "$plugin_dir/tests/model-contract.js"
node "$plugin_dir/tests/panel-scroll.js"
node "$plugin_dir/tests/panel-navigation.js"
node "$plugin_dir/tests/battery.js"
node "$plugin_dir/tests/bluetooth-model.js"
python3 -B "$plugin_dir/tests/bluetooth-profile.py"
node "$plugin_dir/tests/hyprland-reload.js"
python3 -B "$plugin_dir/tests/test_apply_settings.py"
python3 -B "$plugin_dir/tests/config-store.py"
node "$plugin_dir/tests/config-model.js"
node "$plugin_dir/tests/sleep-lifecycle.js"

echo "=== 6. Running Localization completeness tests ==="
node "$plugin_dir/tests/i18n-completeness.js"

echo "=== 7. Running QML Lint ==="
python3 -B "$plugin_dir/tests/qml-lint.py"

echo "=== 8. Running trackball interaction tests ==="
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input "$plugin_dir/tests/ui"

echo "=== 9. Running Lockscreen guard tests ==="
bash "$plugin_dir/tests/lockscreen-guard.sh"

echo "=================================================="
echo "ALL MX ERGO PLUGIN CHECKS PASSED SUCCESSFULLY."
echo "=================================================="
