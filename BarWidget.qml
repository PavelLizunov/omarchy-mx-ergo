import QtQuick
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.pavellizunov.mx-ergo"
  ipcTarget: "io.github.pavellizunov.mx-ergo"

  readonly property bool showPercentage: root.setting("showPercentage", true)
  readonly property bool hideWhenDisconnected: root.setting("hideWhenDisconnected", false)

  ErgoModel {
    id: ergoModel
    targetAddress: root.setting("deviceAddress", "C2:B5:BB:BB:64:FF")
    hyprDeviceName: root.setting("hyprDeviceName", "logitech-mx-ergo-multi-device-trackball-")
    sensitivity: root.setting("sensitivity", 0.0)
    accelProfile: root.setting("accelProfile", "adaptive")
    naturalScroll: root.setting("naturalScroll", false)
    language: root.setting("locale", "ru")
  }

  readonly property bool vertical: root.bar ? root.bar.vertical : false

  visible: ergoModel.connected || !root.hideWhenDisconnected
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.showPercentage && !root.vertical && ergoModel.barBatteryText !== ""
      ? (ergoModel.deviceIcon + " " + ergoModel.barBatteryText)
      : ergoModel.deviceIcon
    slotSize: Style.bar.iconSlot * (root.showPercentage && !root.vertical && ergoModel.barBatteryText !== "" ? 2 : 1)
    tooltipText: ergoModel.connected
      ? ("Logitech MX Ergo: " + ergoModel.batteryLevelText)
      : ("Logitech MX Ergo: " + ergoModel.t("disconnected"))
    onPressed: function(b) {
      root.toggle()
    }
  }

  KeyboardPanel {
    id: popup
    anchorItem: button
    owner: root
    open: root.opened
    bar: root.bar
    focusTarget: panelCard
    contentWidth: popup.fittedContentWidth(Style.space(340))
    contentHeight: popup.fittedContentHeight(panelCard.contentHeight)

    ErgoPanel {
      id: panelCard
      anchors.fill: parent
      bar: root.bar
      model: ergoModel
      onCloseRequested: root.close()
    }
  }
}
