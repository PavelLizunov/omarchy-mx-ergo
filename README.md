# Logitech MX Ergo Trackball Plugin for Omarchy Quattro

> **Status: Work in progress / В разработке.** This is a development snapshot, not a stable release. The manifest currently reports `1.0.0`; that number does not indicate production readiness. See [known limitations](#known-limitations) before trying it.

A hardware plugin for Omarchy Quattro shell designed for the **Logitech MX Ergo** multi-device wireless trackball connected via Bluetooth BLE or Logitech Unifying Receiver.

## Features

- **Linux Driver Grounding:** Native integration with the Linux kernel driver `hid-logitech-hidpp` (`/sys/class/power_supply/hidpp_battery_*`).
- **Battery Reporting:** Displays hardware capacity tiers (`Full`, `Normal`, `Low`, `Critical`) using three segments, plus charging state.
- **Dual Transport Support:** Automatically identifies connection method (Bluetooth BLE vs Logitech Unifying USB Receiver).
- **Hardware Button Mapping:** Configures actions for 5 trackball buttons (`mouse:275`, `mouse:276`, `mouse:274`, `mouse:278`, `mouse:279`) with action catalog (Workspaces, Overview, Window control, Audio mute).
- **Experimental Low-Latency Mode:** Optional kernel BLE connection parameter tuning (`conn_min_interval: 6`, `conn_max_interval: 9`) and USB autosuspend settings. Actual input rate and latency have not been measured.
- **Settings Persistence:** Button mappings and pointer preferences are saved to `~/.config/omarchy/mx-ergo.json`.
- **Compact Status Indicator:** Trackball connection state, battery segments, and charging indicator in the Omarchy status bar.
- **Strict Uncertainty Handling:** Disconnected or sleeping states display explicit indicator glyphs without coercing unknown battery levels to 0%.
- **Hyprland Pointer Controls:**
  - Acceleration profile toggle: **Adaptive** vs **Flat** (Linear).
  - Sensitivity slider (`-1.0` to `+1.0`, step `0.05`) with a one-shot 250ms debounce.
  - Natural scrolling toggle.
  - Safe, per-device configuration applied directly to `logitech-mx-ergo-multi-device-trackball-`.
- **Pure Theme Integration:** 100% Omarchy theme tokens (`Color.*`, `Style.*`), automatically matching any active desktop palette.

## Architecture & Security Disclosure

- **Execution:** The plugin runs unsandboxed with the user's permissions inside the shared Omarchy shell. Button actions can execute commands and change Hyprland bindings.
- **Optional Privileges:** `scripts/low-latency.sh` uses `pkexec` when requested from the panel. It changes Bluetooth controller settings and writes `/etc/tmpfiles.d/bluetooth-low-latency.conf` and `/etc/udev/rules.d/50-bluetooth-performance.rules`. These changes affect the controller, not just this trackball.
- **Kernel Driver Telemetry:** Reads true HID++ 4.5 battery events directly from the Linux kernel power supply node (`hidpp_battery_*`). Does NOT open raw `/dev/hidraw*` device nodes, preserving driver ownership.
- **Processes:** Settings are written with Python; telemetry uses a shell reader for sysfs; pointer and button settings use `hyprctl eval`. Only use trusted custom commands and configuration values.
- **Monitoring:** Resume detection uses `dbus-monitor`. Sysfs telemetry is polled every 15 seconds while the panel is open and every 120 seconds in the background.
- **Strict Input Validation:** Hardware addresses are strictly validated against MAC address patterns before passing to Bluetooth brokers.

## Development setup

Requires Omarchy Quattro, its Quickshell Bluetooth and UPower modules, BlueZ, UPower, and the Hyprland Lua interface used by this source. Runtime helpers include Python 3, `dbus-monitor`, `hyprctl`, and `omarchy-bluetooth-device`. Some button actions additionally require `wtype`, `playerctl`, `wpctl`, Voxtype, or the author's TTS plugin. Tests require Node.js, Python 3, Qt 6 `qmllint`, and installed Omarchy shell sources.

For source inspection, clone outside the active plugins directory:

```bash
git clone https://github.com/PavelLizunov/omarchy-mx-ergo.git
cd omarchy-mx-ergo
```

The current code assumes the development folder `~/.config/omarchy/plugins/slovn.mx-ergo/`. Review the source and adapt machine-specific settings before enabling it. Files copied into the active plugin directory may be discovered or reloaded by the running shell. Never change or reload an active plugin while the screen is locked or a lock is requested.

The plugin ID is `io.github.pavellizunov.mx-ergo`. Use Omarchy's plugin controls to enable or disable it. Before removal, turn off optional low-latency mode if it was enabled; removing the plugin alone does not remove its system configuration files. Saved preferences remain in `~/.config/omarchy/mx-ergo.json`.

## Known limitations

- Text appearing over the plugin has been reported; the cause and fix are pending.
- The sysfs reader selects the first `hidpp_battery_*` entry, so multiple Logitech devices can produce incorrect telemetry.
- Bluetooth defaults, the reconnect fallback, TTS command paths, and USB controller IDs contain author-machine assumptions and need generalization.
- Unknown battery text and charging presentation need further review.
- Some model tests duplicate implementation logic instead of executing the QML model directly.
- Runtime lifecycle and compatibility across machines have not been verified for this publication. Other documentation may still describe intended behavior.

Development tasks are tracked in [BACKLOG.md](BACKLOG.md).

## Verification

```bash
./tests/run.sh
```

The suite checks the manifest, symlinks, colors, model contracts, locale completeness, QML lint, and lockscreen guard logic. Passing these checks does not verify live UI behavior. The current lint helper also expects `/tmp/opencode` to exist.

## License

MIT License. Copyright (c) 2026 Pavel Lizunov.
