# Backlog & Status Ledger

## Current Status: Work in progress / В разработке

Public development snapshot. Manifest version: `1.0.0`. Stable release readiness is not established.

## Before a stable release

- [ ] Diagnose and fix reported text appearing over the plugin.
- [ ] Match sysfs telemetry to the configured MX Ergo instead of the first Logitech battery node.
- [ ] Remove author-machine assumptions from device defaults, reconnect fallback, TTS paths, and low-latency tuning.
- [ ] Verify unknown battery and charging states in the live panel.
- [ ] Test the actual model logic and complete runtime lifecycle checks.
- [ ] Reconcile handbook and module documentation with current behavior.

## Implemented

- [x] Linux driver telemetry through periodic sysfs reads (`hid-logitech-hidpp`, `/sys/class/power_supply/hidpp_battery_*`).
- [x] Accurate battery tier calculation (`Full`, `Normal`, `Low`, `Critical`) and charging state detection.
- [x] Dual transport auto-detection: Bluetooth BLE (`046d:b01d`) and Logitech Unifying USB receiver (`046d:406f`).
- [x] Button mapping configuration for 5 hardware buttons (Back, Forward, Middle, Tilt Left, Tilt Right).
- [x] Ready action catalog (Workspaces, Window overview, Kill window, Float toggle, Mute).
- [x] Configuration persistence in `~/.config/omarchy/mx-ergo.json`.
- [x] Bar widget with connection icon, charging indicator, and three battery segments.
- [x] Interactive card (`ErgoPanel.qml`) on Omarchy theme tokens (`Color.*`, `Style.*`).
- [x] Hyprland 0.56.2 Lua integration (`hl.device({ name, sensitivity, accel_profile, natural_scroll })` and `o.bind(...)`).
- [x] One-shot 250ms debounced slider input and 500ms debounced config writer.
- [x] Complete keyboard navigation (`PanelKeyCatcher`: Tab, Arrows, Enter, Escape).
- [x] 10 language localizations (`en`, `ru`, `de`, `fr`, `es`, `it`, `pt`, `zh`, `ja`, `ko`).
- [x] Automated test suite (`tests/run.sh`) with 8 verification stages.
- [x] Zero hardcoded hex colors and zero symlinks.
- [x] Upstream bug #9441 lockscreen guard.

## Planned Enhancements

- [ ] **DPI Presets:** Optional quick-selector for standard trackball DPI steps (e.g. 380 DPI, 440 DPI, 512 DPI) mapped to Hyprland sensitivity increments.
