import QtQuick
import Quickshell.Io
import "Battery.js" as Battery

QtObject {
  id: root
  required property var device
  property var identity: null
  property string capacityLevel: ""
  // UPower owns the live battery properties. This small, read-only metadata
  // file supplies the hardware identity missing from its QML API.
  property FileView metadata: FileView {
    path: root.device && /^hidpp_battery_[0-9]+$/.test(root.device.nativePath)
      ? "/sys/class/power_supply/" + root.device.nativePath + "/device/uevent" : ""
    printErrors: false
    onPathChanged: root.identity = null
    onLoaded: root.identity = Battery.identity(text())
    onLoadFailed: root.identity = null
  }

  // UPower's percentage is synthetic for coarse HID++ reports. Read the
  // kernel's category for this verified HID power supply instead of decoding
  // UPower's presentation icon. Refresh when UPower observes a level change.
  property FileView batteryLevelFile: FileView {
    path: root.device && /^hidpp_battery_[0-9]+$/.test(root.device.nativePath)
      ? "/sys/class/power_supply/" + root.device.nativePath + "/capacity_level" : ""
    printErrors: false
    onPathChanged: root.capacityLevel = ""
    onLoaded: root.capacityLevel = text().trim()
    onLoadFailed: root.capacityLevel = ""
  }

  property Connections batteryUpdates: Connections {
    target: root.device
    function onPercentageChanged() {
      if (root.batteryLevelFile.path) root.batteryLevelFile.reload()
    }
  }
}
