# Backlog & Status Ledger

## Current Status: v1.1.0 (Production Candidate)

- [x] Full event-driven Linux driver telemetry (`hid-logitech-hidpp` sysfs `/sys/class/power_supply/hidpp_battery_*`).
- [x] Accurate battery tier calculation (`Full`, `Normal`, `Low`, `Critical`) and charging state detection.
- [x] Dual transport auto-detection: Bluetooth BLE (`046d:b01d`) and Logitech Unifying USB receiver (`046d:406f`).
- [x] Button mapping configuration for 5 hardware buttons (Back, Forward, Middle, Tilt Left, Tilt Right).
- [x] Ready action catalog (Workspaces, Window overview, Kill window, Float toggle, Mute).
- [x] Configuration persistence in `~/.config/omarchy/plugins/slovn.mx-ergo/config.json`.
- [x] Bar widget with dynamic icon (`󰍽` connected / `󰍿` sleep / `󰂄` charging) and battery percent.
- [x] Interactive card (`ErgoPanel.qml`) on Omarchy theme tokens (`Color.*`, `Style.*`).
- [x] Hyprland 0.56.2 Lua integration (`hl.device({ name, sensitivity, accel_profile, natural_scroll })` and `o.bind(...)`).
- [x] One-shot 250ms debounced slider input and 500ms debounced config writer.
- [x] Complete keyboard navigation (`PanelKeyCatcher`: Tab, Arrows, Enter, Escape).
- [x] 10 language localizations (`en`, `ru`, `de`, `fr`, `es`, `it`, `pt`, `zh`, `ja`, `ko`).
- [x] Automated test suite (`tests/run.sh`) with 8 verification stages.
- [x] Zero hardcoded hex colors and zero symlinks.
- [x] Upstream bug #9441 lockscreen guard.

## Planned Enhancements (Post v1.1)

- [ ] **DPI Presets:** Optional quick-selector for standard trackball DPI steps (e.g. 380 DPI, 440 DPI, 512 DPI) mapped to Hyprland sensitivity increments.
