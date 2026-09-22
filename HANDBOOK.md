# Engineering Handbook: Logitech MX Ergo Trackball Plugin

## 1. Hardware Profile

- **Device:** Logitech MX Ergo Wireless Trackball.
- **Transports:**
  - Bluetooth Low Energy (BLE, `046D:B01D`, `usb:v046DpB01Dd0025`).
  - Logitech Unifying Receiver (USB Dongle, `046D:406F`).
- **Kernel Drivers:** `uhid` / `usbhid` -> `hid-logitech-hidpp` (`HID++ 4.5 device connected.`).
- **Power Supply Node:** `/sys/class/power_supply/hidpp_battery_*` (`POWER_SUPPLY_CAPACITY_LEVEL=Full|Normal|Low|Critical`, `POWER_SUPPLY_STATUS=Discharging|Charging`).

## 2. Battery telemetry

`Quickshell.Services.UPower` and `Quickshell.Bluetooth` own battery state. `PowerDevice.qml` reads HID identity metadata through a native `FileView`, then `ErgoModel.qml` selects exactly one matching battery. `Battery.js` interprets recognized UPower icons and BlueZ values as approximate categories. UPower’s numeric percentage is not used: it can be a compatibility approximation for a coarse battery level.

The installed Quickshell API has no `BatteryLevel`, serial, or hardware measurement timestamp. Metadata read time is not battery measurement time. High does not mean a verified 100%. No battery gauge is rendered. The main label shows the reported category, charging, or unknown when no category is available. A secondary hint explains that the level is approximate and an exact percentage is unavailable. The Bluetooth connection flag takes precedence over cached BLE battery presence.

See [README limitations and controller diagnostics](README.md#optional-bluetooth-latency-profile) for source precision, receiver identity, and profile semantics. Do not add raw HID readers or periodic battery polling to obtain apparent freshness.

## 3. Hyprland Pointer & Button Integration (0.56.2+)

This plugin targets the Lua interface on the tested Omarchy host (Hyprland 0.56.2). It requires `hyprctl eval`, `hl.device`, and the host's `o.bind` helper; compatibility with other Hyprland configurations is not established.

### Lua Commands
```lua
-- Sensitivity (-1.0 to 1.0)
hl.device({ name = "logitech-mx-ergo-multi-device-trackball-", sensitivity = 0.20 })

-- Acceleration Profile ("adaptive" or "flat")
hl.device({ name = "logitech-mx-ergo-multi-device-trackball-", accel_profile = "adaptive" })

-- Natural Scrolling (true or false)
hl.device({ name = "logitech-mx-ergo-multi-device-trackball-", natural_scroll = false })

-- Button Binds (Back, Forward, Middle, Tilt Left, Tilt Right)
pcall(function() hl.unbind("mouse:275") end)
o.bind("mouse:275", "MX Ergo: Next Workspace", hl.dsp.focus({ workspace = "e+1" }))

-- Tilt Left/Right bind both horizontal scroll (mouse_left/right) and discrete (mouse:278/279)
pcall(function() hl.unbind("mouse_left") end)
pcall(function() hl.unbind("mouse:278") end)
o.bind("mouse_left", "MX Ergo: Prev Workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("mouse:278", "MX Ergo: Prev Workspace", hl.dsp.focus({ workspace = "e-1" }))
```

### Rate Limiting & Throttling
- When the user drags the sensitivity slider, a single one-shot `Timer` (`applyDebounce`, 250ms) coalesces changes until the slider has been idle for 250ms. The managed application queue allows only one helper at a time.
- Button and pointer changes are saved to `~/.config/omarchy/mx-ergo.json` (outside the watched plugin tree) via a debounced writer (500ms).

## 4. Interface contract

The panel uses the host's `PanelHero`, `KeyboardPanel`, shared `Style` sizes and colors. Its width follows the ROG Cetra reference (`Style.space(380)`). Buttons, Pointer and Device are separate pages; the button editor replaces the diagram. Confirming an assignment returns to the diagram. Draft edits have no effect until explicitly applied.

The small SVG trackball icon and the larger generated illustration are separate assets. The illustration's five targets are defined in `TrackballMap.qml`. Theme changes tint the small icon and all QML controls; they do not recolor the product illustration.

Keyboard handling is exercised by production-function and offscreen diagram tests. A complete native keyboard-only and accessibility session is still an acceptance item, not a claim of full accessibility.

## 5. Persistence and recovery

`config-store.py` caps preference reads at 64 KiB, rejects invalid values and special files, and uses an atomic same-directory replacement with mode 0600. One managed writer serializes saves and retains only the latest queued value. Read/write errors appear in the panel and logs; the previous file is preserved on write failure. Retry serializes through the same writer. Startup guards also expose a helper that fails to launch. Closing the shell during the 500ms save debounce can still discard a just-made edit.

`apply-settings.py` reads at most 1 MiB of child output and kills/reaps a child on overflow, timeout or cancellation. Each invocation has a five-second deadline. The model adds a 40-second overall watchdog and at most one pending request. Successful readback verifies binding keys, global scope and descriptions, not the eventual effect of an external command.

Bluetooth resume recovery makes at most two attempts, at approximately 2 and 12 seconds after resume. Reconnect uses only a known native BlueZ device. An eight-second busy guard prevents overlapping attempts. The logind listener has at most three restart attempts spaced by two seconds. Its failure is visible; successful startup clears the warning without resetting the retry budget. Sleep stops reconnect timers and cancels the current settings helper. Resume restarts configured settings application.
