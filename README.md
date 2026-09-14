# Logitech MX Ergo Trackball Plugin for Omarchy Quattro

A lightweight, event-driven hardware plugin for Omarchy Quattro shell designed for the **Logitech MX Ergo** multi-device wireless trackball connected via Bluetooth.

## Features

- **Compact Status Indicator:** Trackball connection state and live battery percentage directly in the Omarchy status bar.
- **Strict Uncertainty Handling:** Disconnected or sleeping states display explicit indicator glyphs without coercing unknown battery levels to 0%.
- **Event-Driven Architecture:** Uses native Quickshell C++ bindings to BlueZ GATT Battery Service (`org.bluez.Battery1`) and UPower. No polling timers, no background daemons, and zero CPU wakeups while idle.
- **Hyprland Pointer Controls:**
  - Acceleration profile toggle: **Adaptive** vs **Flat** (Linear).
  - Sensitivity slider (`-1.0` to `+1.0`, step `0.05`) with a one-shot 250ms debounce.
  - Natural scrolling toggle.
  - Safe, per-device configuration applied directly to `logitech-mx-ergo-multi-device-trackball-`.
- **Pure Theme Integration:** 100% Omarchy theme tokens (`Color.*`, `Style.*`), automatically matching any active desktop palette.

## Architecture

Following the Omarchy Plugin Observatory guidelines:
- **Pattern A (Reactive C++ Service):** Subscribes to `Quickshell.Bluetooth` and `Quickshell.Services.UPower` object models.
- **Single Owner:** `ErgoModel.qml` holds all device state and throttles Hyprland IPC updates.
- **Zero Root Privileges:** Operates strictly within user session permissions (`features.privilege: false`).

## Verification

```bash
omarchy plugin validate ~/.config/omarchy/plugins/slovn.mx-ergo/
/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell ~/.config/omarchy/plugins/slovn.mx-ergo/*.qml
```

## License

MIT License. Copyright (c) 2026 Pavel Lizunov.
