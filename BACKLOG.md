# Backlog & Status Ledger

## Current Status: v1.0.0 (Production Candidate)

- [x] Full event-driven telemetry (BlueZ GATT Battery Service + UPower).
- [x] Bar widget with dynamic icon (`󰍽` connected / `󰍿` sleep) and battery percent.
- [x] Interactive card (`ErgoPanel.qml`) on Omarchy theme tokens (`Color.*`, `Style.*`).
- [x] Hyprland 0.56.2 Lua integration (`hl.device({ name, sensitivity, accel_profile, natural_scroll })`).
- [x] One-shot 250ms debounced slider input.
- [x] Complete keyboard navigation (`PanelKeyCatcher`: Tab, Arrows, Enter, Escape).
- [x] 10 language localizations (`en`, `ru`, `de`, `fr`, `es`, `it`, `pt`, `zh`, `ja`, `ko`).
- [x] Automated test suite (`tests/run.sh`) with 8 verification stages.
- [x] Zero hardcoded hex colors and zero symlinks.
- [x] Upstream bug #9441 lockscreen guard.

## Planned Enhancements (Post v1.0)

- [ ] **Dual Transport Support:** Automatically detect and switch between Bluetooth BLE mode (`046d:b01d`) and Logitech Unifying Receiver USB dongle mode (`046d:406f`) when the receiver is plugged in.
- [ ] **DPI Presets:** Optional quick-selector for standard trackball DPI steps (e.g. 380 DPI, 440 DPI, 512 DPI) mapped to Hyprland sensitivity increments.
