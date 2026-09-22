import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Services.UPower
import "I18n.js" as I18n
import "Battery.js" as Battery

// Single state owner for Logitech MX Ergo trackball.
// Reactive BlueZ/UPower telemetry and Hyprland pointer/button controls.
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

  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string configPath: configHome + "/omarchy/mx-ergo.json"
  readonly property string configHelper: decodeURIComponent(Qt.resolvedUrl("scripts/config-store.py").toString().replace(/^file:\/\//, ""))

  // User adjustable pointer settings
  property real sensitivity: 0.0
  property string accelProfile: "adaptive"
  property bool naturalScroll: false
  property bool configReadComplete: false
  property bool settingsConfigured: false
  property bool configLoadFailed: false
  property bool configSaveFailed: false
  property bool configWriting: false
  property bool sleeping: false
  property bool shuttingDown: false
  property bool sleepMonitorFailed: false
  property int sleepMonitorRestarts: 0

  // Theme changes reload Hyprland and discard settings applied via hyprctl eval.
  property Connections hyprlandEvents: Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event && event.name === "configreloaded" && root.configReadComplete && root.settingsConfigured) {
        console.info("MX Ergo: restoring settings after Hyprland reload")
        root.applyAllSettings()
      }
    }
  }

  // Refresh optional controller diagnostics when the panel opens
  property bool panelOpen: false
  onPanelOpenChanged: {
    if (root.panelOpen) {
      root.checkLowLatency()
    }
  }

  property string lowLatencyState: "unknown"
  property bool lowLatencyHelperAvailable: false
  property bool lowLatencyCanRestore: false
  property bool lowLatencyLegacy: false
  property bool lowLatencyConfigured: false
  property bool lowLatencyFailed: false
  readonly property bool lowLatencyEnabled: lowLatencyState === "applied"
  readonly property bool lowLatencyBusy: lowLatencyApply.running
  readonly property string bluetoothAdapter: btDevice && btDevice.adapter
    ? String(btDevice.adapter.adapterId).split("/").pop() : ""
  readonly property string lowLatencyScript: decodeURIComponent(Qt.resolvedUrl("scripts/low-latency.sh").toString().replace(/^file:\/\//, ""))
  onBluetoothAdapterChanged: root.checkLowLatency()

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

  // Reactive devices from native C++ services
  readonly property var btDevicesList: Bluetooth.devices ? Bluetooth.devices.values : []
  readonly property var upDevicesList: UPower.devices ? UPower.devices.values : []

  // Matched Bluetooth device
  readonly property var btDevice: {
    var list = btDevicesList
    var target = root.targetAddress.toUpperCase().replace(/:/g, "")
    var matches = []
    for (var i = 0; i < list.length; i++) {
      var d = list[i]
      if (!d) continue
      var addr = String(d.address || "").toUpperCase().replace(/:/g, "")
      var name = String(d.name || d.deviceName || "")
      if ((target !== "" && addr === target) || (target === "" && name.indexOf("MX Ergo") !== -1)) {
        matches.push(d)
      }
    }
    return matches.length === 1 ? matches[0] : null
  }

  property var powerCandidates: []
  property Instantiator powerDevices: Instantiator {
    model: root.upDevicesList
    delegate: PowerDevice {
      required property var modelData
      device: modelData
    }
    onObjectAdded: function(index, object) {
      root.powerCandidates = root.powerCandidates.concat([object])
    }
    onObjectRemoved: function(index, object) {
      root.powerCandidates = root.powerCandidates.filter(function(item) { return item !== object })
    }
  }

  // Reject ambiguous/foreign devices instead of selecting the first Logitech battery.
  readonly property var matchedPower: {
    var target = root.btDevice ? root.btDevice.address : root.targetAddress
    var available = root.powerCandidates.filter(function(item) {
      return item.device && item.device.ready && item.device.isPresent && item.identity
        && (item.identity.transport !== "ble" || (root.btDevice && root.btDevice.connected))
    })
    var matches = available.filter(function(item) { return Battery.matches(item.identity, target) })
    if (matches.length === 1) return matches[0]
    if (matches.length > 1 || (root.btDevice && root.btDevice.connected)) return null
    // Bluetooth MAC and receiver serial differ. With no active BLE link, a
    // single receiver-side MX Ergo can be selected by its verified product ID.
    var receivers = available.filter(function(item) { return item.identity.transport === "unifying" })
    return receivers.length === 1 ? receivers[0] : null
  }
  readonly property var upDevice: matchedPower ? matchedPower.device : null

  readonly property string transport: {
    if (btDevice && btDevice.connected) return "ble"
    // A cached BLE battery is not evidence of a receiver connection.
    if (matchedPower && matchedPower.identity.transport === "unifying") return "unifying"
    return ""
  }

  readonly property bool connected: transport !== ""
  readonly property bool deviceFound: btDevice !== null || matchedPower !== null
  readonly property var isCharging: !connected || !upDevice || upDevice.state === UPowerDeviceState.Unknown
    ? null : upDevice.state === UPowerDeviceState.Charging

  onConnectedChanged: {
    if (root.connected) {
      root.isConnecting = false
      connectingResetTimer.stop()
      wakeReconnectTimer.stop()
      wakeStage2Timer.stop()
    }
  }

  readonly property bool canReconnect: !!root.btDevice && /^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/.test(root.btDevice.address)

  function reconnectDevice() {
    if (root.connected || root.isConnecting || root.sleeping || !root.btDevice) return

    var target = root.btDevice.address
    // Strict operand validation: must match valid 6-octet MAC address pattern
    if (!/^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/.test(target)) return

    root.isConnecting = true
    connectingResetTimer.restart()

    root.btDevice.connect()
  }

  function setAutoReconnect(enabled) {
    var b = !!enabled
    if (root.autoReconnect !== b) {
      root.autoReconnect = b
      saveDebounce.restart()
    }
  }

  // The process lifetime includes the Polkit prompt; do not guess with a 3s timer.
  function checkLowLatency(preserveError) {
    if (root.lowLatencyBusy || root.sleeping || root.shuttingDown) return
    if (lowLatencyCheck.running) return
    if (preserveError !== true) root.lowLatencyFailed = false
    root.lowLatencyState = "unknown"
    root.lowLatencyConfigured = false
    root.lowLatencyHelperAvailable = false
    root.lowLatencyCanRestore = false
    root.lowLatencyLegacy = false
    lowLatencyCheck.adapterAtStart = root.bluetoothAdapter
    lowLatencyCheck.command = [root.lowLatencyScript, "--status", root.bluetoothAdapter || "-"]
    lowLatencyCheck.running = true
  }

  function applyLowLatency() {
    runLowLatency("--enable")
  }

  function revertLowLatency() {
    runLowLatency("--disable")
  }

  function runLowLatency(action) {
    if (root.lowLatencyBusy || !root.lowLatencyHelperAvailable) return
    if (["--enable", "--disable", "--remove-legacy"].indexOf(action) < 0) return
    if (action === "--enable" && !/^hci[0-9]+$/.test(root.bluetoothAdapter)) return
    lowLatencyCheck.running = false
    root.lowLatencyFailed = false
    lowLatencyApply.command = [root.lowLatencyScript, action, root.bluetoothAdapter || "-"]
    lowLatencyApply.running = true
  }

  property Process lowLatencyApply: Process {
    onExited: function(exitCode) {
      root.lowLatencyFailed = exitCode !== 0
      Qt.callLater(function() { root.checkLowLatency(true) })
    }
  }

  property Process lowLatencyCheck: Process {
    id: lowLatencyCheck
    property string adapterAtStart: ""
    onExited: {
      if (adapterAtStart !== root.bluetoothAdapter) Qt.callLater(root.checkLowLatency)
    }
    stdout: StdioCollector {
      onStreamFinished: {
        if (lowLatencyCheck.adapterAtStart !== root.bluetoothAdapter || root.lowLatencyBusy) return
        try {
          var result = JSON.parse(text)
          root.lowLatencyHelperAvailable = result.version === 1 && result.helperAvailable === true
          root.lowLatencyCanRestore = result.canRestore === true
          root.lowLatencyLegacy = result.state === "legacy"
          root.lowLatencyConfigured = result.configured === true
          root.lowLatencyState = ["applied", "partial", "off", "unknown", "unavailable", "legacy", "restart", "restore_pending"].indexOf(result.state) >= 0 ? result.state : "unknown"
        } catch (e) {
          root.lowLatencyState = "unknown"
        }
      }
    }
  }

  property Timer connectingResetTimer: Timer {
    interval: 8000
    repeat: false
    onTriggered: { root.isConnecting = false }
  }

  // MAC / hardware address
  readonly property string macAddress: {
    if (root.matchedPower) return root.matchedPower.identity.address
    if (btDevice && btDevice.address) return String(btDevice.address).toUpperCase()
    if (root.targetAddress !== "") return root.targetAddress.toUpperCase()
    return "046D:B01D"
  }

  // Every level is approximate: this MX Ergo interface does not expose verified SOC.
  readonly property string batteryTier: Battery.tier(root.connected, root.isCharging,
    root.upDevice ? root.upDevice.iconName : "",
    !!(root.btDevice && root.btDevice.connected && root.btDevice.batteryAvailable),
    root.btDevice ? root.btDevice.battery : null)
  // Show the reported category; the hint explains that exact charge is unavailable.
  readonly property string batteryLevelText: Battery.label(root.connected, root.isCharging, root.batteryTier,
    function(key) { return root.t(key) })
  readonly property string batteryReportText: root.batteryTier || root.isCharging
    ? root.t("battery_reported")
    : root.t("battery_estimate_hint")
  readonly property string batteryIcon: root.isCharging ? "󰂄" : "󰂑"

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
    if (root.availableActions.indexOf(act) < 0 && act !== "custom_shortcut" && act !== "custom_command") return
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
    if (s.length > 256 || s.indexOf("\u0000") >= 0) return
    if (btnKey === "back") root.buttonCustomShortcutBack = s
    else if (btnKey === "forward") root.buttonCustomShortcutForward = s
    else if (btnKey === "middle") root.buttonCustomShortcutMiddle = s
    else if (btnKey === "tiltLeft") root.buttonCustomShortcutTiltLeft = s
    else if (btnKey === "tiltRight") root.buttonCustomShortcutTiltRight = s
    setButtonAction(btnKey, "custom_shortcut")
  }

  function setCustomCommand(btnKey, cmdStr) {
    var c = String(cmdStr || "").trim()
    if (c.length > 2048 || c.indexOf("\u0000") >= 0) return
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

  function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\"'\"'") + "'"
  }

  // Convert human-readable key combination ("CTRL + SHIFT + T", "SUPER + 8", "Super P+8") to wtype shell command
  function shortcutToWtype(shortcutStr) {
    if (!shortcutStr) return ""
    var raw = String(shortcutStr).replace(/,/g, " ").replace(/\+/g, " ")
    var tokens = raw.trim().split(/\s+/)
    if (tokens.length === 0 || !raw.trim()) return ""
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
    if (keys.length === 0) return ""
    var cmd = "wtype -s 25 -d 20"
    for (var m = 0; m < mods.length; m++) cmd += " " + mods[m]
    for (var k = 0; k < keys.length; k++) {
      var key = keys[k]
      var uKey = key.toUpperCase()
      if (key.length === 1) {
        cmd += " -k " + shellQuote(key.toLowerCase())
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
        cmd += " -k " + shellQuote(key)
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

  // All callers share one verified application path.
  function applySensitivity() { applyAllSettings() }
  function applyAccelProfile() { applyAllSettings() }
  function applyNaturalScroll() { applyAllSettings() }

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
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: TTS Clipboard\", " + JSON.stringify(shellQuote(root.configHome + "/omarchy/plugins/io.github.hikari112.tts/bin/speak") + " --clipboard") + ")\n"
        } else if (norm === "SUPER ALT E" || norm === "WIN ALT E") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: TTS Selection\", " + JSON.stringify(shellQuote(root.configHome + "/omarchy/plugins/io.github.hikari112.tts/bin/speak") + " --toggle") + ")\n"
        } else if (norm === "SUPER ALT X" || norm === "WIN ALT X") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: TTS Stop\", " + JSON.stringify(shellQuote(root.configHome + "/omarchy/plugins/io.github.hikari112.tts/bin/speak") + " --stop") + ")\n"
        } else if (norm === "SUPER ALT R" || norm === "WIN ALT R") {
          lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: TTS Snip\", " + JSON.stringify(shellQuote(root.configHome + "/omarchy/plugins/io.github.hikari112.tts/bin/speak") + " --snip") + ")\n"
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

  function applyButtonBind(btnKey, action) { applyAllSettings() }

  function buildSettingsRequest() {
    var lua = "do\n"
    if (root.hyprDeviceName !== "") {
      var sensitivity = Number(root.sensitivity)
      if (!isFinite(sensitivity)) throw new Error("Invalid sensitivity")
      var profile = root.accelProfile
      if (profile !== "adaptive" && profile !== "flat") throw new Error("Invalid acceleration profile")
      lua += "hl.device({ name = " + JSON.stringify(root.hyprDeviceName)
        + ", sensitivity = " + Math.max(-1, Math.min(1, sensitivity)).toFixed(2)
        + ", accel_profile = " + JSON.stringify(profile)
        + ", natural_scroll = " + (root.naturalScroll ? "true" : "false") + " })\n"
    }
    var buttons = { "mouse:275": "back", "mouse:276": "forward", "mouse:274": "middle",
      "mouse_left": "tiltLeft", "mouse:278": "tiltLeft", "mouse_right": "tiltRight", "mouse:279": "tiltRight" }
    var expected = {}
    for (var code in buttons) {
      var key = buttons[code]
      var snippet = buildBindSnippet(code, getButtonAction(key), key)
      // Read the description from the same generated bind, including JSON escapes.
      var match = snippet.match(/o\.bind\([^,]+,\s*("(?:\\.|[^"\\])*")/)
      expected[code] = match ? JSON.parse(match[1]) : null
      lua += snippet
    }
    return { lua: lua + "end\n", expected: expected }
  }

  property var pendingSettingsRequest: null
  property bool settingsApplying: false
  property bool settingsRecoveryFailed: false
  property bool settingsStopping: false
  property int settingsGeneration: 0
  property int settingsCapturedGeneration: -1
  property int settingsExitCode: -1
  property string settingsOutput: ""
  readonly property string settingsHelper: decodeURIComponent(Qt.resolvedUrl("scripts/apply-settings.py").toString().replace(/^file:\/\//, ""))

  function applyAllSettings() {
    if (!root.configReadComplete || root.shuttingDown) return
    settingsGeneration++
    try {
      pendingSettingsRequest = buildSettingsRequest()
      root.settingsConfigured = true
      settingsRecoveryFailed = false
      Qt.callLater(drainSettingsRequest)
    } catch (_) {
      pendingSettingsRequest = null
      settingsRecoveryFailed = true
      console.warn("MX Ergo: invalid settings; application skipped")
    }
  }

  function drainSettingsRequest() {
    if (root.sleeping || root.shuttingDown || settingsApplying || settingsApplier.running || pendingSettingsRequest === null) return
    settingsApplying = true
    settingsCapturedGeneration = settingsGeneration
    settingsStopping = false
    settingsExitCode = -1
    settingsOutput = ""
    settingsApplier.command = ["/usr/bin/python3", "-I", root.settingsHelper, JSON.stringify(pendingSettingsRequest)]
    pendingSettingsRequest = null
    settingsDeadline.interval = 40000
    settingsDeadline.restart()
    settingsApplier.running = true
    settingsStartCheck.restart()
  }

  function finishSettingsApply() {
    if (!settingsApplying || settingsApplier.running) return
    settingsStartCheck.stop()
    settingsDeadline.stop()
    settingsApplying = false
    var ok = false
    try { ok = settingsExitCode === 0 && JSON.parse(settingsOutput).ok === true } catch (_) {}
    if (settingsCapturedGeneration === settingsGeneration) settingsRecoveryFailed = !ok
    if (ok) console.info("MX Ergo: settings applied and button bindings verified")
    else console.warn("MX Ergo: settings verification failed after bounded recovery")
    Qt.callLater(drainSettingsRequest)
  }

  property Process settingsApplier: Process {
    id: settingsApplier
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.settingsOutput = text.length <= 1024 ? text : ""
    }
    onExited: function(exitCode) {
      root.settingsExitCode = exitCode
      Qt.callLater(root.finishSettingsApply)
    }
    onRunningChanged: {
      if (!running && root.settingsApplying) Qt.callLater(root.finishSettingsApply)
    }
  }
  property Timer settingsStartCheck: Timer {
    id: settingsStartCheck
    interval: 1000
    onTriggered: root.finishSettingsApply()
  }
  property Timer settingsDeadline: Timer {
    id: settingsDeadline
    interval: 40000
    onTriggered: {
      if (settingsApplier.running && settingsApplier.processId > 0) {
        settingsApplier.signal(root.settingsStopping ? 9 : 15)
        root.settingsStopping = true
        interval = 2000
        restart()
      } else root.finishSettingsApply()
    }
  }
  Component.onDestruction: {
    root.shuttingDown = true
    sleepRetry.stop()
    sleepStartCheck.stop()
    wakeReconnectTimer.stop()
    wakeStage2Timer.stop()
    saveDebounce.stop()
    applyDebounce.stop()
    sleepMonitor.running = false
    pendingSettingsRequest = null
    settingsStartCheck.stop()
    settingsDeadline.stop()
    if (settingsApplier.running) settingsApplier.running = false
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
    root.pendingConfig = jsonStr
    drainConfigWrite()
  }

  property string pendingConfig: ""
  function drainConfigWrite() {
    if (root.shuttingDown || root.configWriting || configWriter.running || !root.pendingConfig) return
    configWriter.command = ["/usr/bin/python3", "-I", root.configHelper, "write", root.configPath, root.pendingConfig]
    root.pendingConfig = ""
    root.configWriting = true
    configWriter.running = true
    configWriteStartCheck.restart()
  }
  property Process configWriter: Process {
    id: configWriter
    onExited: function(exitCode) {
      root.finishConfigWrite(exitCode)
    }
  }

  function finishConfigWrite(exitCode) {
    configWriteStartCheck.stop()
    root.configWriting = false
    root.configSaveFailed = exitCode !== 0
    if (exitCode === 0) root.configLoadFailed = false
    else console.warn("MX Ergo: preferences could not be saved")
    Qt.callLater(root.drainConfigWrite)
  }
  function retrySettings() {
    if (root.configSaveFailed) root.saveConfig()
    if (root.settingsRecoveryFailed) root.applyAllSettings()
  }
  property Timer configWriteStartCheck: Timer {
    id: configWriteStartCheck
    interval: 1000
    onTriggered: if (root.configWriting && !configWriter.running) root.finishConfigWrite(-1)
  }
  property Timer configReadStartCheck: Timer {
    id: configReadStartCheck
    interval: 1000
    onTriggered: {
      if (!configLoader.running && !root.configReadComplete) {
        root.configReadComplete = true
        root.configLoadFailed = true
      }
    }
  }

  // Config loader process (discrete argv, no shell interpreter)
  property Process configLoader: Process {
    id: configLoader
    command: ["/usr/bin/python3", "-I", root.configHelper, "read", root.configPath]
    onExited: function(exitCode) {
      configReadStartCheck.stop()
      root.configReadComplete = true
      if (exitCode !== 0) root.configLoadFailed = true
      if (exitCode !== 0) console.warn("MX Ergo: invalid or unreadable preferences; using defaults without applying them")
    }
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.configReadComplete = true
        var txt = (text || "").trim()
        if (!txt) return
        try {
          var cfg = JSON.parse(txt)
          if (!cfg) return // First install: do not overwrite existing compositor bindings.
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
          root.configLoadFailed = true
        }
      }
    }
  }

  // System sleep/resume monitor (logind PrepareForSleep signal listener)
  property Process sleepMonitor: Process {
    id: sleepMonitor
    command: [
      "/usr/bin/dbus-monitor", "--system",
      "type='signal',sender='org.freedesktop.login1',path='/org/freedesktop/login1',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'"
    ]
    onExited: root.scheduleSleepMonitorRetry()
    stdout: SplitParser {
      onRead: function(line) {
        // The selected logind signal has one bounded boolean argument.
        var value = String(line).trim()
        if (value === "boolean true") root.prepareForSleep(true)
        else if (value === "boolean false") root.prepareForSleep(false)
      }
    }
  }

  function prepareForSleep(asleep) {
    root.sleeping = asleep
    if (asleep) {
      wakeReconnectTimer.stop()
      wakeStage2Timer.stop()
      if (settingsApplier.running) settingsApplier.signal(15)
    } else {
      root.sleepMonitorRestarts = 0
      root.sleepMonitorFailed = false
      if (root.settingsConfigured) root.applyAllSettings()
      if (root.autoReconnect) wakeReconnectTimer.restart()
    }
  }
  function scheduleSleepMonitorRetry() {
    if (root.shuttingDown) return
    root.sleepMonitorFailed = true
    if (root.sleepMonitorRestarts < 3) sleepRetry.restart()
  }
  property Timer sleepRetry: Timer {
    id: sleepRetry
    interval: 2000
    onTriggered: {
      if (root.shuttingDown || sleepMonitor.running) return
      root.sleepMonitorRestarts++
      sleepMonitor.running = true
      sleepStartCheck.restart()
    }
  }
  property Timer sleepStartCheck: Timer {
    id: sleepStartCheck
    interval: 1000
    onTriggered: {
      if (!sleepMonitor.running) root.scheduleSleepMonitorRetry()
      else root.sleepMonitorFailed = false
    }
  }

  // Bounded reconnection attempts after the controller has had time to resume.
  property Timer wakeReconnectTimer: Timer {
    id: wakeReconnectTimer
    interval: 2000
    repeat: false
    onTriggered: {
      if (root.autoReconnect && !root.connected && !root.sleeping) {
        root.reconnectDevice()
        // Second stage attempt after Bluetooth controller powers up
        wakeStage2Timer.restart()
      }
    }
  }

  property Timer wakeStage2Timer: Timer {
    id: wakeStage2Timer
    interval: 10000
    repeat: false
    onTriggered: {
      if (root.autoReconnect && !root.connected && !root.sleeping) {
        root.reconnectDevice()
      }
    }
  }

  Component.onCompleted: {
    console.info("MX Ergo: model loaded with categorical battery display and Hyprland reload recovery")
    checkLowLatency()
    configLoader.running = true
    configReadStartCheck.restart()
    sleepMonitor.running = true
    sleepStartCheck.restart()
  }
}
