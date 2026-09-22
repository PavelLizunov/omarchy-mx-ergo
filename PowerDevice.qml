import QtQuick
import Quickshell.Io
import "Battery.js" as Battery

QtObject {
  id: root
  required property var device
  property var identity: null
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
}
