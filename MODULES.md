# Source map & Module Architecture

Start with the row matching the component to inspect or modify. Read the listed owner and its consumer before making edits.

## UI Components & State

| Component | Role | Consumer / Check |
| --- | --- | --- |
| `BarWidget.qml` | Entry point for Omarchy Quattro bar. Hosts compact status icon, percentage text, and `KeyboardPanel` popup card. | `manifest.json`; `tests/run.sh`, `qmllint` |
| `ErgoModel.qml` | Single state owner. Reactive bindings to `Quickshell.Bluetooth` and `Quickshell.Services.UPower`. Throttles and executes Hyprland 0.56.2 Lua commands via discrete `Process` argv. | `BarWidget.qml`, `ErgoPanel.qml`; `tests/model-contract.js` |
| `ErgoPanel.qml` | Interactive popup card. Displays connection badge, battery progress bar, MAC address, hardware notes, and pointer controls. Includes full keyboard traversal. | `BarWidget.qml`; `qmllint`, visual review |
| `I18n.js` | Internationalization dictionary and helper. Bundles 10 languages (`en`, `ru`, `de`, `fr`, `es`, `it`, `pt`, `zh`, `ja`, `ko`) with fallback. | `ErgoModel.qml`, `ErgoPanel.qml`; `tests/i18n-completeness.js` |
| `locales/` | Standardized localization catalogs in JSON format with `index.json`. | `I18n.js`; `tests/i18n-completeness.js` |

## Data Flow & Invariants

```
[BlueZ D-Bus GATT]   --> Quickshell.Bluetooth       \
                                                     --> ErgoModel.qml (Single Owner)
[UPower D-Bus HID++] --> Quickshell.Services.UPower /          |
                                                               | (Reactive QML bindings)
                                                               v
                                                      [BarWidget & ErgoPanel]
                                                               |
                                                               | (Debounced 250ms User Input)
                                                               v
                                                      [hyprctl eval 'hl.device(...)']
```

1. **Reactive, Zero-Polling Telemetry:** BlueZ GATT Battery Service (`org.bluez.Battery1`) and UPower (`battery_hidpp_8`) emit D-Bus property changes directly into Quickshell C++ models. Zero timer polling in the background.
2. **Strict Uncertainty Handling:** When disconnected, battery percentage evaluates strictly to `null`. It is NEVER coerced to 0% or false.
3. **Hyprland Device Targeting:** Commands target `logitech-mx-ergo-multi-device-trackball-` specifically using `hl.device({ ... })` in Hyprland 0.56.2.

## Test Infrastructure

- `tests/run.sh`: Master test gate running syntax checks, manifest validation, symlink guards, color guards, model contract assertions, i18n completeness, qmllint, and lockscreen guards.
- `tests/model-contract.js`: Automated unit test for model math, null contracts, clamping, and Lua command formatting.
- `tests/i18n-completeness.js`: Verifies parity across all 10 locales.
- `tests/qml-lint.py`: Isolated `qmllint` validation with mock shell imports.
- `tests/lockscreen-guard.sh`: Verifies lockscreen detection logic against upstream bug #9441.
