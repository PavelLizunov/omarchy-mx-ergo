import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import "I18n.js" as I18n

// Single state owner for Logitech MX Ergo trackball.
// Directly integrated with Linux kernel hid-logitech-hidpp driver (/sys/class/power_supply),
// BlueZ Bluetooth GATT, UPower, and Hyprland pointer/button controls.
QtObject {
  id: root

  property string targetAddress: ""
  property string hyprDeviceName: "logitech-mx-ergo-multi-device-trackball-"
  property string language: "system"
  readonly property string effectiveLanguage: I18n.resolveLanguage(language, Qt.locale().name)

  signal localeRequested(string code)

  function setLocale(code) {
    if (["system", "en", "ru", "de", "fr", "es", "it", "pt", "zh", "ja", "ko"].indexOf(code) < 0) return
    root.language = code
    root.localeRequested(code)
  }

  // User adjustable pointer settings
  property real sensitivity: 0.0
  property string accelProfile: "adaptive"
  property bool naturalScroll: false

  // Panel active state for dual-cadence polling
  property bool panelOpen: false
  onPanelOpenChanged: {
    if (root.panelOpen) {
      root.refreshDriver()
      root.checkLowLatency()
    }
  }

  // Low-latency mode status (125 Hz / 7.5ms - 11.25ms BLE intervals)
  property bool lowLatencyEnabled: false

  // Auto-reconnect on system wake / recovery
  property bool autoReconnect: true
  property bool isConnecting: false

  // User configurable button actions
  property string buttonBack: "default"
  property string buttonForward: "default"
  property string buttonMiddle: "default"
  property string buttonTiltLeft: "default"
  property string buttonTiltRight: "default"

  // User custom shortcut key combinations (e.g. "CTRL + SHIFT + T")
  property string buttonCustomShortcutBack: ""
  property string buttonCustomShortcutForward: ""
  property string buttonCustomShortcutMiddle: ""
  property string buttonCustomShortcutTiltLeft: ""
  property string buttonCustomShortcutTiltRight: ""

  // User custom shell commands (e.g. "alacritty", "omarchy-menu toggle")
  property string buttonCustomCmdBack: ""
  property string buttonCustomCmdForward: ""
  property string buttonCustomCmdMiddle: ""
  property string buttonCustomCmdTiltLeft: ""
  property string buttonCustomCmdTiltRight: ""

  // Linux kernel hid-logitech-hidpp sysfs telemetry
  property bool driverFound: false
  property string driverCapacityLevel: ""
  property string driverStatus: ""
  property bool driverOnline: false
  property string driverSerial: ""
  property string driverModel: ""

  // Reactive devices from native C++ services
  readonly property var btDevicesList: Bluetooth.devices ? Bluetooth.devices.values : []
  readonly property var upDevicesList: UPower.devices ? UPower.devices.values : []

  // Matched Bluetooth device
  readonly property var btDevice: {
    var list = btDevicesList
    var target = root.targetAddress.toUpperCase().replace(/:/g, "")
    for (var i = 0; i < list.length; i++) {
      var d = list[i]
      if (!d) continue
      var addr = String(d.address || "").toUpperCase().replace(/:/g, "")
      var name = String(d.name || d.deviceName || "")
      if ((target !== "" && addr === target) || (target === "" && name.indexOf("MX Ergo") !== -1)) {
        return d
      }
    }
    return null
  }

  // Matched UPower device (hidpp_battery)
  readonly property var upDevice: {
    var list = upDevicesList
    for (var i = 0; i < list.length; i++) {
      var d = list[i]
      if (!d) continue
      var path = String(d.nativePath || "")
      var model = String(d.model || "")
      if (path.indexOf("hidpp_battery") !== -1 && model.indexOf("MX Ergo") !== -1) {
        return d
      }
    }
    return null
  }

  // Transport detection: Bluetooth BLE vs Logitech Unifying Dongle
  readonly property string transport: {
    if (btDevice && btDevice.connected) return "ble"
    if (driverFound && driverOnline) return "unifying"
    if (upDevice && upDevice.isPresent) return "unifying"
    return ""
  }

  readonly property bool connected: transport !== ""
  readonly property bool deviceFound: btDevice !== null || driverFound || (upDevice && upDevice.isPresent)
  readonly property bool isCharging: driverStatus.toLowerCase() === "charging" || (upDevice && upDevice.state === 1)

  onConnectedChanged: {
    if (root.connected) {
      root.isConnecting = false
      connectingResetTimer.stop()
    }
  }

  function reconnectDevice() {
    if (root.connected || root.isConnecting) return

    var target = root.macAddress
    if (!target || target === "046D:B01D") target = "C2:B5:BB:BB:64:FF"
    // Strict operand validation: must match valid 6-octet MAC address pattern
    if (!/^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/.test(target)) return

    root.isConnecting = true
    connectingResetTimer.restart()

    if (root.btDevice) {
      root.btDevice.connect()
    }
    Quickshell.execDetached(["omarchy-bluetooth-device", "connect", target])
  }

  function setAutoReconnect(enabled) {
    var b = !!enabled
    if (root.autoReconnect !== b) {
      root.autoReconnect = b
      saveDebounce.restart()
    }
  }

  // Low latency checker & applier (delegates privilege elevation to Polkit via pkexec)
  function checkLowLatency() {
    if (!lowLatencyCheck.running) {
      lowLatencyCheck.running = true
    }
  }

  function applyLowLatency() {
    var scriptPath = Quickshell.env("HOME") + "/.config/omarchy/plugins/slovn.mx-ergo/scripts/low-latency.sh"
    Quickshell.execDetached(["pkexec", scriptPath, "--enable"])
    lowLatencyRecheckTimer.restart()
  }

  function revertLowLatency() {
    var scriptPath = Quickshell.env("HOME") + "/.config/omarchy/plugins/slovn.mx-ergo/scripts/low-latency.sh"
    Quickshell.execDetached(["pkexec", scriptPath, "--disable"])
    lowLatencyRecheckTimer.restart()
  }

  property Timer lowLatencyRecheckTimer: Timer {
    interval: 3000
    repeat: false
    onTriggered: root.checkLowLatency()
  }

  property Process lowLatencyCheck: Process {
    id: lowLatencyCheck
    command: ["test", "-f", "/etc/tmpfiles.d/bluetooth-low-latency.conf"]
    onExited: function(exitCode) {
      root.lowLatencyEnabled = (exitCode === 0)
    }
  }

  property Timer connectingResetTimer: Timer {
    interval: 8000
    repeat: false
    onTriggered: { root.isConnecting = false }
  }

  // MAC / hardware address
  readonly property string macAddress: {
    if (driverSerial !== "") return driverSerial.toUpperCase()
    if (btDevice && btDevice.address) return String(btDevice.address).toUpperCase()
    if (root.targetAddress !== "") return root.targetAddress.toUpperCase()
    return "046D:B01D"
  }

  // Battery Tier derived directly from hid-logitech-hidpp driver
  readonly property string batteryTier: {
    if (!root.connected) return ""

    var cap = root.driverCapacityLevel.toLowerCase()
    if (cap === "full") return "full"
    if (cap === "normal" || cap === "high") return "normal"
    if (cap === "low") return "low"
    if (cap === "critical") return "critical"

    // Fallback: UPower iconName when sysfs is delayed
    if (upDevice && upDevice.isPresent && upDevice.iconName) {
      var icon = upDevice.iconName.toLowerCase()
      if (icon.indexOf("full") !== -1) return "full"
      if (icon.indexOf("good") !== -1) return "normal"
      if (icon.indexOf("low") !== -1) return "low"
      if (icon.indexOf("caution") !== -1 || icon.indexOf("empty") !== -1) return "critical"
    }

    // Fallback: UPower / BlueZ numeric percentage
    var raw = -1
    if (upDevice && upDevice.isPresent && typeof upDevice.percentage === "number" && upDevice.percentage >= 0) {
      raw = upDevice.percentage * 100
    } else if (btDevice && btDevice.batteryAvailable && typeof btDevice.battery === "number" && btDevice.battery >= 0) {
      raw = btDevice.battery * 100
    }

    if (raw < 0) return ""
    if (raw >= 80) return "full"
    if (raw >= 30) return "normal"
    if (raw >= 10) return "low"
    return "critical"
  }

  // Discrete 3-segment battery meter (hardware reality: Full 3/3, Normal 2/3, Low 1/3, Critical 0/3)
  readonly property var batterySegments: {
    if (!root.connected || root.batteryTier === "") return null
    if (root.batteryTier === "full") return 3
    if (root.batteryTier === "normal") return 2
    if (root.batteryTier === "low") return 1
    return 0
  }

  // Visual battery fraction for progress meter (0.0 to 1.0)
  readonly property var batteryFraction: {
    if (!root.connected || root.batterySegments === null) return null
    return root.batterySegments / 3.0
  }

  // Concise segment text (e.g. "3/3", "2/3", "1/3", or "Заряжается")
  readonly property string batteryLevelText: {
    if (!root.connected) return I18n.t("disconnected", root.effectiveLanguage)
    if (root.isCharging) return I18n.t("battery_charging", root.effectiveLanguage) + " (3/3)"
    if (root.batterySegments === 0) return "! 0/3"
    return root.batterySegments + "/3"
  }

  // Short dots badge for bar (e.g. "●●●", "●●○", "●○○", "○○○")
  readonly property string barBatteryText: {
    if (!root.connected || root.batterySegments === null) return ""
    if (root.isCharging) return "󰂄"
    if (root.batterySegments === 3) return "●●●"
    if (root.batterySegments === 2) return "●●○"
    if (root.batterySegments === 1) return "●○○"
    return "○○○"
  }

  // Battery icon based on state
  readonly property string batteryIcon: {
    if (!root.connected || root.batteryTier === "") return "󰂑"
    if (root.isCharging) return "󰂄"
    if (root.batteryTier === "full") return "󰁹"
    if (root.batteryTier === "normal") return "󰁾"
    if (root.batteryTier === "low") return "󰁻"
    return "󰂃"
  }

  // Device icon (trackball)
  readonly property string deviceIcon: root.connected ? "󰍽" : "󰍿"

  readonly property string transportText: {
    if (root.transport === "ble") return I18n.t("transport_ble", root.effectiveLanguage)
    if (root.transport === "unifying") return I18n.t("transport_unifying", root.effectiveLanguage)
    return I18n.t("disconnected", root.effectiveLanguage)
  }

  function t(key) {
    return I18n.t(key, root.effectiveLanguage)
  }

  // Pointer setting updaters
  function setSensitivity(val) {
    var clamped = Math.max(-1.0, Math.min(1.0, Number(val)))
    if (Math.abs(root.sensitivity - clamped) > 0.01) {
      root.sensitivity = clamped
      applyDebounce.restart()
      saveDebounce.restart()
    }
  }

  function setAccelProfile(profile) {
    var p = (profile === "flat" || profile === "adaptive") ? profile : "adaptive"
    if (root.accelProfile !== p) {
      root.accelProfile = p
      applyAccelProfile()
      saveDebounce.restart()
    }
  }

  function setNaturalScroll(enabled) {
    var b = !!enabled
    if (root.naturalScroll !== b) {
      root.naturalScroll = b
      applyNaturalScroll()
      saveDebounce.restart()
    }
  }

  // Button mapping actions catalog
  readonly property var availableActions: [
    "default",
    "workspace_next",
    "workspace_prev",
    "window_close",
    "window_float",
    "window_fullscreen",
    "window_next",
    "overview",
    "screenshot",
    "media_play_pause",
    "media_next",
    "media_prev",
    "mute",
    "tab_next",
    "tab_prev",
    "browser_back",
    "browser_forward"
  ]

  function getButtonAction(btnKey) {
    if (btnKey === "back") return root.buttonBack
    if (btnKey === "forward") return root.buttonForward
    if (btnKey === "middle") return root.buttonMiddle
    if (btnKey === "tiltLeft") return root.buttonTiltLeft
    if (btnKey === "tiltRight") return root.buttonTiltRight
    return "default"
  }

  function getCustomShortcut(btnKey) {
    if (btnKey === "back") return root.buttonCustomShortcutBack
    if (btnKey === "forward") return root.buttonCustomShortcutForward
    if (btnKey === "middle") return root.buttonCustomShortcutMiddle
    if (btnKey === "tiltLeft") return root.buttonCustomShortcutTiltLeft
    if (btnKey === "tiltRight") return root.buttonCustomShortcutTiltRight
    return ""
  }

  function getCustomCommand(btnKey) {
    if (btnKey === "back") return root.buttonCustomCmdBack
    if (btnKey === "forward") return root.buttonCustomCmdForward
    if (btnKey === "middle") return root.buttonCustomCmdMiddle
    if (btnKey === "tiltLeft") return root.buttonCustomCmdTiltLeft
    if (btnKey === "tiltRight") return root.buttonCustomCmdTiltRight
    return ""
  }

  function setButtonAction(btnKey, action) {
    var act = String(action || "default")
    if (btnKey === "back") root.buttonBack = act
    else if (btnKey === "forward") root.buttonForward = act
    else if (btnKey === "middle") root.buttonMiddle = act
    else if (btnKey === "tiltLeft") root.buttonTiltLeft = act
    else if (btnKey === "tiltRight") root.buttonTiltRight = act
    applyButtonBind(btnKey, act)
    saveDebounce.restart()
  }

  function setCustomShortcut(btnKey, shortcutStr) {
    var s = String(shortcutStr || "").trim()
    if (btnKey === "back") root.buttonCustomShortcutBack = s
    else if (btnKey === "forward") root.buttonCustomShortcutForward = s
    else if (btnKey === "middle") root.buttonCustomShortcutMiddle = s
    else if (btnKey === "tiltLeft") root.buttonCustomShortcutTiltLeft = s
    else if (btnKey === "tiltRight") root.buttonCustomShortcutTiltRight = s
    setButtonAction(btnKey, "custom_shortcut")
  }

  function setCustomCommand(btnKey, cmdStr) {
    var c = String(cmdStr || "").trim()
    if (btnKey === "back") root.buttonCustomCmdBack = c
    else if (btnKey === "forward") root.buttonCustomCmdForward = c
    else if (btnKey === "middle") root.buttonCustomCmdMiddle = c
    else if (btnKey === "tiltLeft") root.buttonCustomCmdTiltLeft = c
    else if (btnKey === "tiltRight") root.buttonCustomCmdTiltRight = c
    setButtonAction(btnKey, "custom_command")
  }

  function resetButtonToDefault(btnKey) {
    if (btnKey === "back") {
      root.buttonBack = "default"
      root.buttonCustomShortcutBack = ""
      root.buttonCustomCmdBack = ""
    } else if (btnKey === "forward") {
      root.buttonForward = "default"
      root.buttonCustomShortcutForward = ""
      root.buttonCustomCmdForward = ""
    } else if (btnKey === "middle") {
      root.buttonMiddle = "default"
      root.buttonCustomShortcutMiddle = ""
      root.buttonCustomCmdMiddle = ""
    } else if (btnKey === "tiltLeft") {
      root.buttonTiltLeft = "default"
      root.buttonCustomShortcutTiltLeft = ""
      root.buttonCustomCmdTiltLeft = ""
    } else if (btnKey === "tiltRight") {
      root.buttonTiltRight = "default"
      root.buttonCustomShortcutTiltRight = ""
      root.buttonCustomCmdTiltRight = ""
    }
    applyButtonBind(btnKey, "default")
    saveDebounce.restart()
  }

  function actionLabel(action, btnKey) {
    if (action === "custom_shortcut") {
      var s = getCustomShortcut(btnKey)
      return s !== "" ? s : I18n.t("tab_shortcut", root.effectiveLanguage)
    }
    if (action === "custom_command") {
      var c = getCustomCommand(btnKey)
      return c !== "" ? c : I18n.t("tab_command", root.effectiveLanguage)
    }
    return I18n.t("action_" + action, root.effectiveLanguage)
  }

  // Convert human-readable key combination ("CTRL + SHIFT + T", "SUPER + 8", "Super P+8") to wtype shell command
  function shortcutToWtype(shortcutStr) {
    if (!shortcutStr) return ""
    var raw = String(shortcutStr).replace(/,/g, " ").replace(/\+/g, " ")
    var tokens = raw.trim().split(/\s+/)
    if (tokens.length === 0) return ""
    var mods = []
    var releaseMods = []
    var keys = []
    for (var i = 0; i < tokens.length; i++) {
      var t = tokens[i].toUpperCase()
      if (t === "CTRL" || t === "CONTROL") {
        mods.push("-M ctrl")
        releaseMods.unshift("-m ctrl")
      } else if (t === "SHIFT") {
        mods.push("-M shift")
        releaseMods.unshift("-m shift")
      } else if (t === "ALT") {
        mods.push("-M alt")
        releaseMods.unshift("-m alt")
      } else if (t === "SUPER" || t === "WIN" || t === "LOGO" || t === "META") {
        mods.push("-M logo")
        releaseMods.unshift("-m logo")
      } else {
        keys.push(tokens[i])
      }
    }
    var cmd = "wtype -s 25 -d 20"
    for (var m = 0; m < mods.length; m++) cmd += " " + mods[m]
    for (var k = 0; k < keys.length; k++) {
      var key = keys[k]
      var uKey = key.toUpperCase()
      if (key.length === 1) {
        cmd += " -k " + key.toLowerCase()
      } else if (uKey === "SPACE") {
        cmd += " -k space"
      } else if (uKey === "ENTER" || uKey === "RETURN") {
        cmd += " -k Return"
      } else if (uKey === "TAB") {
        cmd += " -k Tab"
      } else if (uKey === "ESCAPE" || uKey === "ESC") {
        cmd += " -k Escape"
      } else if (uKey === "BACKSPACE") {
        cmd += " -k BackSpace"
      } else if (uKey === "DELETE" || uKey === "DEL") {
        cmd += " -k Delete"
      } else if (uKey === "INSERT" || uKey === "INS") {
        cmd += " -k Insert"
      } else if (uKey === "HOME") {
        cmd += " -k Home"
      } else if (uKey === "END") {
        cmd += " -k End"
      } else if (uKey === "PAGEUP" || uKey === "PGUP" || uKey === "PAGE_UP" || uKey === "PRIOR") {
        cmd += " -k Prior"
      } else if (uKey === "PAGEDOWN" || uKey === "PGDN" || uKey === "PAGE_DOWN" || uKey === "NEXT") {
        cmd += " -k Next"
      } else if (uKey === "LEFT") {
        cmd += " -k Left"
      } else if (uKey === "RIGHT") {
        cmd += " -k Right"
      } else if (uKey === "UP") {
        cmd += " -k Up"
      } else if (uKey === "DOWN") {
        cmd += " -k Down"
      } else if (uKey === "PRINT" || uKey === "PRINTSCREEN") {
        cmd += " -k Print"
      } else if (uKey === "PAUSE") {
        cmd += " -k Pause"
      } else if (uKey === "MENU") {
        cmd += " -k Menu"
      } else {
        cmd += " -k " + key
      }
    }
    for (var r = 0; r < releaseMods.length; r++) cmd += " " + releaseMods[r]
    return cmd
  }

  // Debounced slider applicator
  property Timer applyDebounce: Timer {
    interval: 250
    repeat: false
    onTriggered: root.applySensitivity()
  }

  // Debounced config writer
  property Timer saveDebounce: Timer {
    interval: 500
    repeat: false
    onTriggered: root.saveConfig()
  }

  // Hyprland Lua dispatch helpers
  function applySensitivity() {
    if (root.hyprDeviceName === "") return
    var val = root.sensitivity.toFixed(2)
    var lua = 'hl.device({ name = "' + root.hyprDeviceName + '", sensitivity = ' + val + ' })'
    Quickshell.execDetached(["hyprctl", "eval", "do\n" + lua + "\nend"])
  }

  function applyAccelProfile() {
    if (root.hyprDeviceName === "") return
    var lua = 'hl.device({ name = "' + root.hyprDeviceName + '", accel_profile = "' + root.accelProfile + '" })'
    Quickshell.execDetached(["hyprctl", "eval", "do\n" + lua + "\nend"])
  }

  function applyNaturalScroll() {
    if (root.hyprDeviceName === "") return
    var lua = 'hl.device({ name = "' + root.hyprDeviceName + '", natural_scroll = ' + (root.naturalScroll ? "true" : "false") + ' })'
    Quickshell.execDetached(["hyprctl", "eval", "do\n" + lua + "\nend"])
  }

  function buildBindSnippet(code, action, btnKey) {
    var lua = "pcall(function() hl.unbind(\"" + code + "\") end)\n"
    if (action === "default") {
      return lua
    } else if (action === "workspace_next") {
      lua += "o.bind(\"" + code + "\", \"MX Ergo: Next Workspace\", hl.dsp.focus({ workspace = \"e+1\" }))\n"
    } else if (action === "workspace_prev") {
      lua += "o.bind(\"" + code + "\", \"MX Ergo: Prev Workspace\", hl.dsp.focus({ workspace = \"e-1\" }))\n"
    } else if (action === "window_close") {
      lua += "o.bind(\"" + code + "\", \"MX Ergo: Close Window\", hl.dsp.window.close())\n"
    } else if (action === "window_float") {
      lua += "o.bind(\"" + code + "\", \"MX Ergo: Toggle Floating\", hl.dsp.window.float({ action = \"toggle\" }))\n"
    } else if (action === "window_fullscreen") {
      lua += "o.bind(\"" + code + "\", \"MX Ergo: Fullscreen\", hl.dsp.window.fullscreen({ mode = \"fullscreen\" }))\n"
    } else if (action === "window_next") {
      lua += "o.bind(\"" + code + "\", \"MX Ergo: Next Window\", hl.dsp.window.cycle_next())\n"
    } else if (action === "overview") {
      lua += "o.bind(\"" + code + "\", \"MX Ergo: Overview\", \"omarchy-shell moorgrove.overview toggle\")\n"
    } else if (action === "screenshot") {
      lua += "o.bind(\"" + code + "\", \"MX Ergo: Screenshot\", \"omarchy-capture-screenshot\")\n"
    } else if (action === "media_play_pause") {
      lua += "o.bind(\"" + code + "\", \"MX Ergo: Play/Pause\", \"playerctl play-pause\")\n"
    } else if (action === "media_next") {
      lua += "o.bind(\"" + code + "\", \"MX Ergo: Next Track\", \"playerctl next\")\n"
    } else if (action === "media_prev") {
      lua += "o.bind(\"" + code + "\", \"MX Ergo: Prev Track\", \"playerctl previous\")\n"
    } else if (action === "mute") {
      lua += "o.bind(\"" + code + "\", \"MX Ergo: Toggle Mute\", \"wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle\")\n"
    } else if (action === "tab_next") {
      lua += "o.bind(\"" + code + "\", \"MX Ergo: Next Tab\", \"wtype -M ctrl -k Tab\")\n"
    } else if (action === "tab_prev") {
      lua += "o.bind(\"" + code + "\", \"MX Ergo: Prev Tab\", \"wtype -M ctrl -M shift -k Tab\")\n"
    } else if (action === "browser_back") {
      lua += "o.bind(\"" + code + "\", \"MX Ergo: Browser Back\", \"wtype -M alt -k Left\")\n"
    } else if (action === "browser_forward") {
      lua += "o.bind(\"" + code + "\", \"MX Ergo: Browser Forward\", \"wtype -M alt -k Right\")\n"
    } else if (action === "custom_shortcut") {
      var sc = getCustomShortcut(btnKey)
      if (sc !== "") {
        var norm = sc.toUpperCase().replace(/,/g, " ").replace(/\+/g, " ").trim().replace(/\s+/g, " ")
        var wsMatch = norm.match(/^(SUPER|WIN|LOGO)\s+([0-9]+)$/)
        if (wsMatch) {
          lua += "o.bind(" + JSON.stringify(code) + ", " + JSON.stringify("MX Ergo: Workspace " + wsMatch[2]) + ", hl.dsp.focus({ workspace = \"" + wsMatch[2] + "\" }))\n"
        } else if (norm === "SUPER CTRL TAB" || norm === "SUPER CONTROL TAB" || norm === "WIN CTRL TAB" || norm === "WIN CONTROL TAB") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Former Workspace\", hl.dsp.focus({ workspace = \"previous\" }))\n"
        } else if (norm === "SUPER SHIFT TAB" || norm === "WIN SHIFT TAB") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Prev Workspace\", hl.dsp.focus({ workspace = \"e-1\" }))\n"
        } else if (norm === "SUPER TAB" || norm === "WIN TAB") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Next Workspace\", hl.dsp.focus({ workspace = \"e+1\" }))\n"
        } else if (norm === "SUPER W" || norm === "SUPER Q" || norm === "WIN W" || norm === "WIN Q") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Close Window\", hl.dsp.window.close())\n"
        } else if (norm === "SUPER F" || norm === "WIN F") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Fullscreen\", hl.dsp.window.fullscreen({ mode = \"fullscreen\" }))\n"
        } else if (norm === "SUPER T" || norm === "WIN T") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Toggle Float\", hl.dsp.window.float({ action = \"toggle\" }))\n"
        } else if (norm === "SUPER SPACE" || norm === "WIN SPACE") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Menu\", \"omarchy-menu toggle\")\n"
        } else if (norm === "SUPER S" || norm === "WIN S") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Scratchpad\", hl.dsp.workspace.toggle_special(\"scratchpad\"))\n"
        } else if (norm === "SUPER LEFT" || norm === "WIN LEFT") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Focus Left\", hl.dsp.focus({ direction = \"l\" }))\n"
        } else if (norm === "SUPER RIGHT" || norm === "WIN RIGHT") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Focus Right\", hl.dsp.focus({ direction = \"r\" }))\n"
        } else if (norm === "SUPER UP" || norm === "WIN UP") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Focus Up\", hl.dsp.focus({ direction = \"u\" }))\n"
        } else if (norm === "SUPER DOWN" || norm === "WIN DOWN") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Focus Down\", hl.dsp.focus({ direction = \"d\" }))\n"
        } else if (norm === "INSERT" || norm === "INS") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Voxtype Dictation\", \"voxtype record toggle\")\n"
        } else if (norm === "SUPER INSERT" || norm === "WIN INSERT") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Voice Agent\", \"omarchy-voice-agent toggle || omarchy-voice-agent start\")\n"
        } else if (norm === "SUPER ALT A" || norm === "WIN ALT A") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: TTS Clipboard\", \"/home/slovn/.config/omarchy/plugins/io.github.hikari112.tts/bin/speak --clipboard\")\n"
        } else if (norm === "SUPER ALT E" || norm === "WIN ALT E") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: TTS Selection\", \"/home/slovn/.config/omarchy/plugins/io.github.hikari112.tts/bin/speak --toggle\")\n"
        } else if (norm === "SUPER ALT X" || norm === "WIN ALT X") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: TTS Stop\", \"/home/slovn/.config/omarchy/plugins/io.github.hikari112.tts/bin/speak --stop\")\n"
        } else if (norm === "SUPER ALT R" || norm === "WIN ALT R") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: TTS Snip\", \"/home/slovn/.config/omarchy/plugins/io.github.hikari112.tts/bin/speak --snip\")\n"
        } else {
          var wcmd = shortcutToWtype(sc)
          if (wcmd !== "") {
            lua += "o.bind(" + JSON.stringify(code) + ", " + JSON.stringify("MX Ergo: " + sc) + ", " + JSON.stringify(wcmd) + ")\n"
          }
        }
      }
    } else if (action === "custom_command") {
      var rawCmd = getCustomCommand(btnKey)
      if (rawCmd !== "") {
        lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Command\", " + JSON.stringify(rawCmd) + ")\n"
      }
    }
    return lua
  }

  function applyButtonBind(btnKey, action) {
    var lua = ""
    if (btnKey === "tiltLeft") {
      lua += buildBindSnippet("mouse_left", action, btnKey)
      lua += buildBindSnippet("mouse:278", action, btnKey)
    } else if (btnKey === "tiltRight") {
      lua += buildBindSnippet("mouse_right", action, btnKey)
      lua += buildBindSnippet("mouse:279", action, btnKey)
    } else {
      var codes = {
        "back": "mouse:275",
        "forward": "mouse:276",
        "middle": "mouse:274"
      }
      var code = codes[btnKey]
      if (code) {
        lua += buildBindSnippet(code, action, btnKey)
      }
    }
    if (lua !== "") {
      Quickshell.execDetached(["hyprctl", "eval", "do\n" + lua + "end"])
    }
  }

  function applyAllSettings() {
    applySensitivity()
    applyAccelProfile()
    applyNaturalScroll()
    applyButtonBind("back", root.buttonBack)
    applyButtonBind("forward", root.buttonForward)
    applyButtonBind("middle", root.buttonMiddle)
    applyButtonBind("tiltLeft", root.buttonTiltLeft)
    applyButtonBind("tiltRight", root.buttonTiltRight)
  }

  // Config persistence (saves to ~/.config/omarchy/mx-ergo.json via safe discrete argv without shell execution)
  function saveConfig() {
    var cfg = {
      "sensitivity": root.sensitivity,
      "accelProfile": root.accelProfile,
      "naturalScroll": root.naturalScroll,
      "autoReconnect": root.autoReconnect,
      "buttons": {
        "back": root.buttonBack,
        "forward": root.buttonForward,
        "middle": root.buttonMiddle,
        "tiltLeft": root.buttonTiltLeft,
        "tiltRight": root.buttonTiltRight
      },
      "customShortcuts": {
        "back": root.buttonCustomShortcutBack,
        "forward": root.buttonCustomShortcutForward,
        "middle": root.buttonCustomShortcutMiddle,
        "tiltLeft": root.buttonCustomShortcutTiltLeft,
        "tiltRight": root.buttonCustomShortcutTiltRight
      },
      "customCommands": {
        "back": root.buttonCustomCmdBack,
        "forward": root.buttonCustomCmdForward,
        "middle": root.buttonCustomCmdMiddle,
        "tiltLeft": root.buttonCustomCmdTiltLeft,
        "tiltRight": root.buttonCustomCmdTiltRight
      }
    }
    var jsonStr = JSON.stringify(cfg, null, 2)
    var targetPath = Quickshell.env("HOME") + "/.config/omarchy/mx-ergo.json"
    Quickshell.execDetached([
      "python3", "-c",
      "import sys, pathlib; p = pathlib.Path(sys.argv[1]); p.parent.mkdir(parents=True, exist_ok=True); p.write_text(sys.argv[2], encoding='utf-8')",
      targetPath,
      jsonStr
    ])
  }

  // Config loader process (discrete argv, no shell interpreter)
  property Process configLoader: Process {
    id: configLoader
    command: ["cat", Quickshell.env("HOME") + "/.config/omarchy/mx-ergo.json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var txt = (text || "").trim()
        if (!txt) return
        try {
          var cfg = JSON.parse(txt)
          if (typeof cfg.sensitivity === "number") root.sensitivity = cfg.sensitivity
          if (typeof cfg.accelProfile === "string") root.accelProfile = cfg.accelProfile
          if (typeof cfg.naturalScroll === "boolean") root.naturalScroll = cfg.naturalScroll
          if (typeof cfg.autoReconnect === "boolean") root.autoReconnect = cfg.autoReconnect
          if (cfg.buttons && typeof cfg.buttons === "object") {
            if (cfg.buttons.back) root.buttonBack = cfg.buttons.back
            if (cfg.buttons.forward) root.buttonForward = cfg.buttons.forward
            if (cfg.buttons.middle) root.buttonMiddle = cfg.buttons.middle
            if (cfg.buttons.tiltLeft) root.buttonTiltLeft = cfg.buttons.tiltLeft
            if (cfg.buttons.tiltRight) root.buttonTiltRight = cfg.buttons.tiltRight
          }
          if (cfg.customShortcuts && typeof cfg.customShortcuts === "object") {
            if (cfg.customShortcuts.back) root.buttonCustomShortcutBack = cfg.customShortcuts.back
            if (cfg.customShortcuts.forward) root.buttonCustomShortcutForward = cfg.customShortcuts.forward
            if (cfg.customShortcuts.middle) root.buttonCustomShortcutMiddle = cfg.customShortcuts.middle
            if (cfg.customShortcuts.tiltLeft) root.buttonCustomShortcutTiltLeft = cfg.customShortcuts.tiltLeft
            if (cfg.customShortcuts.tiltRight) root.buttonCustomShortcutTiltRight = cfg.customShortcuts.tiltRight
          }
          if (cfg.customCommands && typeof cfg.customCommands === "object") {
            if (cfg.customCommands.back) root.buttonCustomCmdBack = cfg.customCommands.back
            if (cfg.customCommands.forward) root.buttonCustomCmdForward = cfg.customCommands.forward
            if (cfg.customCommands.middle) root.buttonCustomCmdMiddle = cfg.customCommands.middle
            if (cfg.customCommands.tiltLeft) root.buttonCustomCmdTiltLeft = cfg.customCommands.tiltLeft
            if (cfg.customCommands.tiltRight) root.buttonCustomCmdTiltRight = cfg.customCommands.tiltRight
          }
          root.applyAllSettings()
        } catch (e) {
          // ignore invalid json
        }
      }
    }
  }

  // System sleep/resume monitor (logind PrepareForSleep signal listener)
  property Process sleepMonitor: Process {
    id: sleepMonitor
    command: [
      "dbus-monitor", "--system",
      "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'"
    ]
    stdout: SplitParser {
      onRead: function(line) {
        // boolean false indicates system resumed from suspend
        if (String(line).indexOf("boolean false") !== -1) {
          wakeReconnectTimer.restart()
        }
      }
    }
  }

  // Double-staged reconnection timer after system wake
  property Timer wakeReconnectTimer: Timer {
    id: wakeReconnectTimer
    interval: 600
    repeat: false
    onTriggered: {
      if (root.autoReconnect && !root.connected) {
        root.reconnectDevice()
        // Second stage attempt after Bluetooth controller powers up
        wakeStage2Timer.restart()
      }
    }
  }

  property Timer wakeStage2Timer: Timer {
    id: wakeStage2Timer
    interval: 1800
    repeat: false
    onTriggered: {
      if (root.autoReconnect && !root.connected) {
        root.reconnectDevice()
      }
    }
  }

  // Linux kernel hid-logitech-hidpp telemetry reader process (pure shell built-ins, zero external binary forks)
  property Process driverReader: Process {
    id: driverReader
    command: [
      "sh", "-c",
      "for d in /sys/class/power_supply/hidpp_battery_*; do " +
      "[ -d \"$d\" ] || continue; " +
      "read -r m < \"$d/model_name\" 2>/dev/null || m=\"\"; " +
      "read -r c < \"$d/capacity_level\" 2>/dev/null || c=\"\"; " +
      "read -r s < \"$d/status\" 2>/dev/null || s=\"\"; " +
      "read -r o < \"$d/online\" 2>/dev/null || o=\"0\"; " +
      "read -r sr < \"$d/serial_number\" 2>/dev/null || sr=\"\"; " +
      "echo \"{\\\"found\\\":true,\\\"model\\\":\\\"$m\\\",\\\"capacity\\\":\\\"$c\\\",\\\"status\\\":\\\"$s\\\",\\\"online\\\":$o,\\\"serial\\\":\\\"$sr\\\"}\"; " +
      "exit 0; done; echo '{\"found\":false}'"
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var txt = (text || "").trim()
        if (!txt) return
        try {
          var res = JSON.parse(txt)
          if (res.found) {
            root.driverFound = true
            root.driverModel = res.model || ""
            root.driverCapacityLevel = res.capacity || ""
            root.driverStatus = res.status || ""
            root.driverOnline = res.online === 1
            root.driverSerial = res.serial || ""
          } else {
            root.driverFound = false
            root.driverCapacityLevel = ""
            root.driverStatus = ""
            root.driverOnline = false
          }
        } catch (e) {
          // ignore parse errors
        }
      }
    }
  }

  function refreshDriver() {
    if (!driverReader.running) {
      driverReader.running = true
    }
  }

  // Dual-cadence polling: fast (15s) when card is open, relaxed (120s) in background
  property Timer driverPollTimer: Timer {
    interval: root.panelOpen ? 15000 : 120000
    repeat: true
    running: true
    onTriggered: root.refreshDriver()
  }

  Component.onCompleted: {
    refreshDriver()
    checkLowLatency()
    configLoader.running = true
    sleepMonitor.running = true
  }
}
