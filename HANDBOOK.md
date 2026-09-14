# Engineering Handbook: Logitech MX Ergo Trackball Plugin

## 1. Hardware Profile

- **Device:** Logitech MX Ergo Wireless Trackball.
- **Transport:** Bluetooth Low Energy (BLE).
- **Bluetooth ID:** `046D:B01D` (`usb:v046DpB01Dd0025`), BD_ADDR `C2:B5:BB:BB:64:FF`.
- **Kernel Drivers:** `uhid` -> `hid-logitech-hidpp` (`HID++ 4.5 device connected.`).
- **Power Supply Node:** `/sys/class/power_supply/hidpp_battery_8` (`POWER_SUPPLY_CAPACITY_LEVEL=Full`).

## 2. Telemetry Architecture (Pattern A)

Rather than spawning periodic CLI commands (`upower -i` or `bluetoothctl info`), the plugin integrates with Quickshell's native C++ D-Bus models:

1. **`Quickshell.Bluetooth`:**
   - Observes BlueZ `org.bluez.Device1` and `org.bluez.Battery1`.
   - `batteryAvailable: bool`
   - `battery: double` (0.0 to 1.0).
   - `connected: bool`.
2. **`Quickshell.Services.UPower`:**
   - Observes `/org/freedesktop/UPower/devices/battery_hidpp_battery_8`.
   - `percentage: double` (0.0 to 1.0).
   - `isPresent: bool`.

### Uncertainty Rules
- Disconnected: `batteryFraction = null`, `batteryPercent = null`. The bar displays `󰍿` (trackball off/disconnected) and tooltip shows "Сон / Отключен".
- Connected: Displays live battery level and icon (`󰁹` to `󰁺`).
- Zero Coercion Ban: Unknown battery is never displayed as 0%.

## 3. Hyprland Pointer Integration (0.56.2+)

Hyprland 0.56.2 uses a Lua configuration engine where legacy `hyprctl keyword` is superseded by `hyprctl eval`.

### Lua Commands
```lua
-- Sensitivity (-1.0 to 1.0)
hl.device({ name = "logitech-mx-ergo-multi-device-trackball-", sensitivity = 0.20 })

-- Acceleration Profile ("adaptive" or "flat")
hl.device({ name = "logitech-mx-ergo-multi-device-trackball-", accel_profile = "adaptive" })

-- Natural Scrolling (true or false)
hl.device({ name = "logitech-mx-ergo-multi-device-trackball-", natural_scroll = false })
```

### Rate Limiting & Throttling
- When the user drags the sensitivity slider, a single one-shot `Timer` (`applyDebounce`, 250ms) ensures that `hyprctl eval` is called at most once every quarter-second, preventing compositor IPC congestion.

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
