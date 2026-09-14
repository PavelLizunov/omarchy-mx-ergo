import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import "I18n.js" as I18n

// Single state owner for Logitech MX Ergo trackball.
// Manages Bluetooth connection, discrete battery tiers, and Hyprland pointer controls.
QtObject {
  id: root

  property string targetAddress: "C2:B5:BB:BB:64:FF"
  property string hyprDeviceName: "logitech-mx-ergo-multi-device-trackball-"
  property string language: "ru"

  // User adjustable pointer settings
  property real sensitivity: 0.0
  property string accelProfile: "adaptive"
  property bool naturalScroll: false

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
      if ((target !== "" && addr === target) || name.indexOf("MX Ergo") !== -1) {
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

  readonly property bool connected: btDevice ? (btDevice.connected === true) : false
  readonly property bool deviceFound: btDevice !== null

  // Battery Tier: "full" | "normal" | "low" | "critical" | null
  // Logitech MX Ergo does NOT report continuous percentage; hardware reports coarse levels.
  readonly property string batteryTier: {
    if (!root.connected) return ""
    // Read percentage from BT GATT or UPower
    var raw = -1
    if (btDevice && btDevice.batteryAvailable && typeof btDevice.battery === "number" && btDevice.battery >= 0) {
      raw = btDevice.battery * 100
    } else if (upDevice && upDevice.isPresent && typeof upDevice.percentage === "number" && upDevice.percentage >= 0) {
      raw = upDevice.percentage * 100
    }

    if (raw < 0) return ""
    if (raw >= 80) return "full"
    if (raw >= 30) return "normal"
    if (raw >= 10) return "low"
    return "critical"
  }

  // Visual battery fraction for progress bar (0.0 to 1.0)
  readonly property var batteryFraction: {
    if (!root.connected || root.batteryTier === "") return null
    if (root.batteryTier === "full") return 1.0
    if (root.batteryTier === "normal") return 0.60
    if (root.batteryTier === "low") return 0.25
    return 0.08
  }

  // Localized battery tier label
  readonly property string batteryLevelText: {
    if (!root.connected) return I18n.t("disconnected", root.language)
    if (root.batteryTier === "full") return I18n.t("battery_full", root.language)
    if (root.batteryTier === "normal") return I18n.t("battery_normal", root.language)
    if (root.batteryTier === "low") return I18n.t("battery_low", root.language)
    if (root.batteryTier === "critical") return I18n.t("battery_critical", root.language)
    return I18n.t("battery_unknown", root.language)
  }

  // Short badge text for bar (e.g. "Full", "Norm", "Low")
  readonly property string barBatteryText: {
    if (!root.connected || root.batteryTier === "") return ""
    if (root.batteryTier === "full") return "Full"
    if (root.batteryTier === "normal") return "Norm"
    if (root.batteryTier === "low") return "Low"
    return "Crit"
  }

  // Battery icon based on tier
  readonly property string batteryIcon: {
    if (!root.connected || root.batteryTier === "") return "󰂑"
    if (root.batteryTier === "full") return "󰁹"
    if (root.batteryTier === "normal") return "󰁾"
    if (root.batteryTier === "low") return "󰁻"
    return "󰂃"
  }

  // Device icon (trackball)
  readonly property string deviceIcon: root.connected ? "󰍽" : "󰍿"

  function t(key) {
    return I18n.t(key, root.language)
  }

  // Setting update helpers
  function setSensitivity(val) {
    var clamped = Math.max(-1.0, Math.min(1.0, Number(val)))
    if (Math.abs(root.sensitivity - clamped) > 0.01) {
      root.sensitivity = clamped
      applyDebounce.restart()
    }
  }

  function setAccelProfile(profile) {
    var p = (profile === "flat" || profile === "adaptive") ? profile : "adaptive"
    if (root.accelProfile !== p) {
      root.accelProfile = p
      applyAccelProfile()
    }
  }

  function setNaturalScroll(enabled) {
    var b = !!enabled
    if (root.naturalScroll !== b) {
      root.naturalScroll = b
      applyNaturalScroll()
    }
  }

  // Debounced slider applicator
  property Timer applyDebounce: Timer {
    interval: 250
    repeat: false
    onTriggered: root.applySensitivity()
  }

  // Immediate Hyprland Lua dispatch via Quickshell.execDetached
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

  function applyAllSettings() {
    applySensitivity()
    applyAccelProfile()
    applyNaturalScroll()
  }
}
