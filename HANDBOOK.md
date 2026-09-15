# Engineering Handbook: Logitech MX Ergo Trackball Plugin

## 1. Hardware Profile

- **Device:** Logitech MX Ergo Wireless Trackball.
- **Transports:**
  - Bluetooth Low Energy (BLE, `046D:B01D`, `usb:v046DpB01Dd0025`).
  - Logitech Unifying Receiver (USB Dongle, `046D:406F`).
- **Kernel Drivers:** `uhid` / `usbhid` -> `hid-logitech-hidpp` (`HID++ 4.5 device connected.`).
- **Power Supply Node:** `/sys/class/power_supply/hidpp_battery_*` (`POWER_SUPPLY_CAPACITY_LEVEL=Full|Normal|Low|Critical`, `POWER_SUPPLY_STATUS=Discharging|Charging`).

## 2. Telemetry Architecture (Linux Driver Grounding)

1. **Linux Kernel Driver `hid-logitech-hidpp` (`/sys/class/power_supply/hidpp_battery_*`):**
   - Directly reflects hardware HID++ 4.5 battery events.
   - `capacity_level`: `Full` (80-100%), `Normal` (20-80%), `Low` (5-20%), `Critical` (<5%).
   - `status`: `Discharging`, `Charging`, `Full`.
   - `serial_number`: device hardware address.
2. **`Quickshell.Bluetooth` & `Quickshell.Services.UPower`:**
   - Fallback signals and reactive connection lifecycle observers.
3. **Dual Transport Resolution:**
   - Automatically determines whether the connection is `ble` or `unifying`.

### Uncertainty Rules
- Disconnected: `batteryFraction = null`, `batteryPercent = null`. The bar displays `󰍿` (trackball off/disconnected) and tooltip shows "Сон / Отключен".
- Connected: Displays live battery level and icon (`󰁹` to `󰁺`, or `󰂄` when charging).
- Zero Coercion Ban: Unknown battery is never displayed as 0%.

## 3. Hyprland Pointer & Button Integration (0.56.2+)

Hyprland 0.56.2 uses a Lua configuration engine where legacy `hyprctl keyword` is superseded by `hyprctl eval`.

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
- When the user drags the sensitivity slider, a single one-shot `Timer` (`applyDebounce`, 250ms) ensures that `hyprctl eval` is called at most once every quarter-second.
- Button and pointer changes are saved to `~/.config/omarchy/mx-ergo.json` (outside the watched plugin tree) via a debounced writer (500ms).

## 4. OpenDesign & Anti-Slop Implementation

- **Design System Grounding:** Modeled after high-precision dev-tools and hardware interfaces (Teenage Engineering / Linear):
  - Strict 4px/8px rhythm (`Style.space(...)`).
  - High-contrast visual hierarchy (Title:body contrast ≥ 2.5x).
  - Clear state pills with subtle background fills.
  - Full keyboard accessibility (`PanelKeyCatcher`: Tab, Arrows, Enter, Escape).
- **Anti-Slop:**
  - Zero decorative AI buzzwords.
  - Concrete facts: exact battery state, MAC address, true hardware button notice.
  - Zero hardcoded hex colors; 100% theme tokens (`Color.*`, `Style.*`).
