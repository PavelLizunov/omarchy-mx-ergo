.pragma library

// Identity only. Battery status stays in Quickshell's native UPower/BlueZ models.
function identity(text) {
  var fields = {}
  String(text || "").split("\n").forEach(function(line) {
    var pos = line.indexOf("=")
    if (pos > 0) fields[line.slice(0, pos)] = line.slice(pos + 1).trim()
  })
  var id = String(fields.HID_ID || "").toUpperCase()
  var transport = /^0005:0000046D:0000B01D$/.test(id) ? "ble"
    : /^0003:0000046D:0000406F$/.test(id) ? "unifying" : ""
  return { transport: transport, address: String(fields.HID_UNIQ || "").toUpperCase() }
}

function matches(info, target) {
  if (!info || !info.transport || !info.address) return false
  // A receiver serial is not the Bluetooth MAC. Do not conflate identities.
  return !target || info.address === String(target).toUpperCase()
}

function iconTier(icon) {
  // Installed Quickshell does not expose UPower.BatteryLevel. IconName is a
  // conservative categorical fallback; UPower.Percentage may be synthetic.
  var match = /^battery-(full|good|low|caution|empty)(?:-charged)?(?:-symbolic)?$/.exec(String(icon || ""))
  if (!match) return ""
  return { full: "full", good: "normal", low: "low", caution: "critical", empty: "critical" }[match[1]]
}

function reportedTier(value) {
  if (typeof value !== "number" || !isFinite(value) || value < 0 || value > 1) return ""
  if (value >= 0.8) return "full"
  if (value >= 0.3) return "normal"
  if (value >= 0.1) return "low"
  return "critical"
}

function tier(connected, charging, upIcon, btAvailable, btValue) {
  if (!connected || charging || /-charging(?:-symbolic)?$/.test(String(upIcon || ""))) return ""
  var up = iconTier(upIcon)
  var bt = btAvailable ? reportedTier(btValue) : ""
  // Conflicting sources must not hide a low-battery report behind Full.
  var levels = ["critical", "low", "normal", "full"]
  if (up && bt) return levels[Math.min(levels.indexOf(up), levels.indexOf(bt))]
  return up || bt
}

function label(connected, charging, level, translate) {
  if (!connected) return translate("disconnected")
  if (charging) return translate("battery_charging")
  if (["full", "normal", "low", "critical"].indexOf(level) >= 0) return translate("battery_" + level)
  return translate("battery_unverified")
}
