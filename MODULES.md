# Source map & Module Architecture

Start with the row matching the component to inspect or modify. Read the listed owner and its consumer before making edits.

## UI Components & State

| Component | Role | Consumer / Check |
| --- | --- | --- |
| `BarWidget.qml` | Entry point for Omarchy Quattro bar. Hosts compact status icon, percentage text, and `KeyboardPanel` popup card. | `manifest.json`; `tests/run.sh`, `qmllint` |
| `ErgoModel.qml` | Single state owner. Native Linux `hid-logitech-hidpp` sysfs driver integration, BlueZ BLE, UPower, button mappings, and Hyprland pointer controls. | `BarWidget.qml`, `ErgoPanel.qml`; `tests/model-contract.js` |
| `ErgoPanel.qml` | Interactive popup card. Displays connection badge, battery progress bar, MAC address, button mapping controls, and pointer controls. Includes full keyboard traversal. | `BarWidget.qml`; `qmllint`, visual review |
| `I18n.js` | Internationalization dictionary and helper. Bundles 10 languages (`en`, `ru`, `de`, `fr`, `es`, `it`, `pt`, `zh`, `ja`, `ko`) with fallback. | `ErgoModel.qml`, `ErgoPanel.qml`; `tests/i18n-completeness.js` |
| `locales/` | Standardized localization catalogs in JSON format with `index.json`. | `I18n.js`; `tests/i18n-completeness.js` |

## Data Flow & Invariants

```
[Linux hid-logitech-hidpp sysfs] --> driverReader Process \
[BlueZ D-Bus GATT]               --> Quickshell.Bluetooth  --> ErgoModel.qml (Single Owner)
[UPower D-Bus HID++]             --> Quickshell.Services.UPower /    |
                                                                     | (Reactive QML bindings)
                                                                     v
                                                           [BarWidget & ErgoPanel]
                                                                     |
                                                                     | (Hyprland Lua Dispatch)
                                                                     v
                                                           [hyprctl eval 'hl.device(...) / o.bind(...)']
```

1. **Linux Driver Telemetry:** Kernel driver `hid-logitech-hidpp` exports `/sys/class/power_supply/hidpp_battery_*` with discrete `capacity_level` and `status`. Telemetry is read directly with fallback to UPower and BlueZ.
2. **Strict Uncertainty Handling:** When disconnected, battery percentage evaluates strictly to `null`. It is NEVER coerced to 0% or false.
3. **Dual Transport Support:** Automatically detects whether the trackball is connected via Bluetooth BLE (`046d:b01d`) or Logitech Unifying USB receiver (`046d:406f`).
4. **Hardware Button Mapping:** Configures 5 buttons (`mouse:275`, `mouse:276`, `mouse:274`, `mouse:278`, `mouse:279`) with action dispatching into Hyprland Lua and config persistence.
5. **Injection-Proof Execution:** Discrete `argv` execution without shell string interpolation; strict JSON stringification for Lua literals and MAC regex validation.

## Test Infrastructure

- `tests/run.sh`: Master test gate running syntax checks, manifest validation, symlink guards, color guards, model contract assertions, i18n completeness, qmllint, and lockscreen guards.
- `tests/model-contract.js`: Automated unit test for model math, null contracts, clamping, and Lua command formatting.
- `tests/i18n-completeness.js`: Verifies parity across all 10 locales.
- `tests/qml-lint.py`: Isolated `qmllint` validation with mock shell imports.
- `tests/lockscreen-guard.sh`: Verifies lockscreen detection logic against upstream bug #9441.
