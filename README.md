# Logitech MX Ergo Trackball Plugin for Omarchy Quattro

A lightweight, event-driven hardware plugin for Omarchy Quattro shell designed for the **Logitech MX Ergo** multi-device wireless trackball connected via Bluetooth BLE or Logitech Unifying Receiver.

## Features

- **Linux Driver Grounding:** Native integration with the Linux kernel driver `hid-logitech-hidpp` (`/sys/class/power_supply/hidpp_battery_*`).
- **Accurate Battery Reporting:** Displays hardware capacity tiers (`Full`, `Normal`, `Low`, `Critical`) and charging state (`Charging`), without stale GATT caching or dummy percentages.
- **Dual Transport Support:** Automatically identifies connection method (Bluetooth BLE vs Logitech Unifying USB Receiver).
- **Hardware Button Mapping:** Configures actions for 5 trackball buttons (`mouse:275`, `mouse:276`, `mouse:274`, `mouse:278`, `mouse:279`) with action catalog (Workspaces, Overview, Window control, Audio mute).
- **125 Hz Low-Latency Optimization:** Optional one-click kernel BLE connection parameter tuning (`conn_min_interval: 6`, `conn_max_interval: 9`) and USB autosuspend prevention to eliminate Bluetooth stutter.
- **Settings Persistence:** Button mappings and pointer preferences persist across reboots via `config.json`.
- **Compact Status Indicator:** Trackball connection state, transport badge, and live battery level directly in the Omarchy status bar.
- **Strict Uncertainty Handling:** Disconnected or sleeping states display explicit indicator glyphs without coercing unknown battery levels to 0%.
- **Hyprland Pointer Controls:**
  - Acceleration profile toggle: **Adaptive** vs **Flat** (Linear).
  - Sensitivity slider (`-1.0` to `+1.0`, step `0.05`) with a one-shot 250ms debounce.
  - Natural scrolling toggle.
  - Safe, per-device configuration applied directly to `logitech-mx-ergo-multi-device-trackball-`.
- **Pure Theme Integration:** 100% Omarchy theme tokens (`Color.*`, `Style.*`), automatically matching any active desktop palette.

## Architecture & Security Disclosure

- **Zero Root Privileges:** Operates strictly within user session permissions (`features.privilege: false`). No `sudo` prompts or credential harvesting in QML.
- **Transparent Polkit Delegation:** The optional 125 Hz tuning script (`scripts/low-latency.sh`) is fully auditable. Privilege elevation is handled solely through the system Polkit agent (`pkexec`) upon explicit user action.
- **Kernel Driver Telemetry:** Reads true HID++ 4.5 battery events directly from the Linux kernel power supply node (`hidpp_battery_*`). Does NOT open raw `/dev/hidraw*` device nodes, preserving driver ownership.
- **Injection-Proof Execution:** All helper processes and file persistence use discrete OS `argv` arrays (never `sh -c` string interpolation or heredocs). Keybindings and custom commands dispatched to Hyprland are strictly serialized as JSON string literals.
- **Bounded Passive Event Monitoring:** Reconnection on system wake is driven by a passive `dbus-monitor` subscription to `org.freedesktop.login1.Manager.PrepareForSleep`. It has zero polling loops, consumes 0% CPU while idle, and only fires on sleep/resume transitions.
- **Strict Input Validation:** Hardware addresses are strictly validated against MAC address patterns before passing to Bluetooth brokers.

## Verification

```bash
./tests/run.sh
```

## License

MIT License. Copyright (c) 2026 Pavel Lizunov.
