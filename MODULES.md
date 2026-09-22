# Source map & Module Architecture

Start with the row matching the component to inspect or modify. Read the listed owner and its consumer before making edits.

## UI Components & State

| Component | Role | Consumer / Check |
| --- | --- | --- |
| `BarWidget.qml` | Entry point for Omarchy Quattro bar. Hosts compact connection/charging icons and `KeyboardPanel` popup card. | `manifest.json`; `tests/run.sh`, `qmllint` |
| `ErgoModel.qml` | Single state owner. Native BlueZ BLE/UPower telemetry, HID identity matching, button mappings, and Hyprland pointer controls. | `BarWidget.qml`, `ErgoPanel.qml`; `tests/model-contract.js` |
| `ErgoPanel.qml` | Popup presentation and navigation: Buttons / Pointer / Device pages, replacement button editor, explicit shortcut/command drafts and automatic return to the diagram after an explicit choice. Uses PanelHero, 380-unit width and shared tokens. Tab navigation includes the header, language picker, errors, pages and editor, and keeps focused controls in view. | `BarWidget.qml`; `qmllint`, visual review |
| `TrackballMap.qml` | Device-independent diagram: centered illustration, balanced callouts, five physical hotspots and selection signal. Does not write settings. Uses `assets/trackball-map.png`. | `ErgoPanel.qml`; `tests/ui/tst_trackball.qml`, visual review |
| `I18n.js` | Internationalization dictionary and helper. Bundles 10 languages (`en`, `ru`, `de`, `fr`, `es`, `it`, `pt`, `zh`, `ja`, `ko`) with fallback. | `ErgoModel.qml`, `ErgoPanel.qml`; `tests/i18n-completeness.js` |
| `system/omarchy-mx-ergo-bluetooth` | Optional root-owned profile helper. Fixed operations, physical adapter identity, baseline journal, atomic configuration and pending recovery. | `scripts/bluetooth-client.py`; `tests/bluetooth-profile.py` |
| `scripts/config-store.py` | Bounded preference validation and atomic writes, called by managed reader/writer processes. | `ErgoModel.qml`; `tests/config-store.py` |
| `scripts/apply-settings.py` | Single request application and bounded Hyprland readback/retry. | `ErgoModel.qml`; `tests/test_apply_settings.py`, `tests/hyprland-reload.js` |
| `scripts/bluetooth-client.py` | Unprivileged trust check and fixed argv dispatcher. Missing helper never triggers installation or elevated plugin code. | `ErgoModel.qml`, compatibility `scripts/low-latency.sh`; profile/model tests |
| `locales/` | Standardized localization catalogs in JSON format with `index.json`. | `I18n.js`; `tests/i18n-completeness.js` |

## Data Flow & Invariants

- `Quickshell.Bluetooth` owns Bluetooth connection and battery reports; `Quickshell.Services.UPower` owns kernel battery state.
- `PowerDevice.qml` reads HID identity metadata only, using native `FileView`. Exactly one identity must match before UPower data is used.
- `Battery.js` maps recognized reports to approximate categories shown in the main label; a secondary hint distinguishes them from an exact charge measurement. Numeric UPower percentages are not used.
- `ErgoModel.qml` owns these bindings, controller profile operations, and the existing Hyprland controls. `ErgoPanel.qml` and `BarWidget.qml` render the model.
- `scripts/low-latency.sh --status <adapter>` checks actual controller settings without authorization. `--enable`, `--disable` and explicit `--remove-legacy` dispatch to the separately installed root-owned helper through Polkit. Restoration uses the saved physical identity even if the adapter number changes. See README for persistence and limitations.

## Test Infrastructure

- `tests/run.sh`: Master test gate running syntax checks, manifest validation, symlink guards, color guards, model contract assertions, i18n completeness, qmllint, and lockscreen guards.
- `tests/model-contract.js`: I18n and production QML shortcut, Lua and reconnect functions.
- `tests/panel-navigation.js`: Production page/editor transitions, draft isolation, keyboard traversal and invalid selections.
- `tests/ui/tst_trackball.qml`: Actual QtQuick callout/hotspot interaction, balanced geometry, translations and connector alignment.
- `tests/battery.js`: Production battery functions and QML identity/connection bindings, including unknown/disconnect/conflicting reports.
- `tests/bluetooth-profile.py`: Actual controller helper in isolated sysfs/etc fixtures, including errors and partial application.
- `tests/sleep-lifecycle.js`: Production suspend cancellation, resume gates and finite listener retries.
- `tests/config-model.js`: Serialized save queue, startup handling and failure/retry states.
- `tests/i18n-completeness.js`: Verifies parity across all 10 locales.
- `tests/qml-lint.py`: Isolated `qmllint` validation with copied installed shell imports; known host dynamic-type warnings are filtered; unknown members on concrete QML types fail.
- `tests/lockscreen-guard.sh`: Verifies lockscreen detection logic against upstream bug #9441.
