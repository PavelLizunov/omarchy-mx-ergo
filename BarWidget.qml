import QtQuick
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.pavellizunov.mx-ergo"
  ipcTarget: "io.github.pavellizunov.mx-ergo"

  readonly property bool hideWhenDisconnected: root.setting("hideWhenDisconnected", false)
  readonly property bool vertical: root.bar ? root.bar.vertical : false

  ErgoModel {
    id: ergoModel
    targetAddress: root.setting("deviceAddress", "")
    hyprDeviceName: root.setting("hyprDeviceName", "logitech-mx-ergo-multi-device-trackball-")
    sensitivity: root.setting("sensitivity", 0.0)
    accelProfile: root.setting("accelProfile", "adaptive")
    naturalScroll: root.setting("naturalScroll", false)
    language: root.setting("locale", "system")
    panelOpen: root.opened
    onLocaleRequested: function(code) {
      if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function") {
        var entry = Object.assign({}, root.settings || {}, {
          id: root.moduleName,
          locale: code
        })
        root.bar.shell.updateEntryInline(root.moduleName, entry)
      }
    }
  }

  visible: ergoModel.connected || !root.hideWhenDisconnected
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    fixedWidth: root.vertical ? -1 : Style.bar.iconSlot
    fixedHeight: root.vertical ? Style.bar.iconSlot : -1
    horizontalMargin: 0
    verticalPadding: 0
    tooltipText: ergoModel.connected
      ? ("Logitech MX Ergo: " + ergoModel.batteryLevelText)
      : ("Logitech MX Ergo: " + ergoModel.t("disconnected"))
    onPressed: function(b) {
      root.toggle()
    }

    Row {
      id: barContent
      anchors.centerIn: parent
      spacing: Style.space(3)

      Text {
        textFormat: Text.PlainText
        text: ergoModel.deviceIcon
        color: button.active && button.useActiveColor ? button.activeColor : button.foreground
        font.family: Style.font.family
        font.pixelSize: Style.bar.iconFont
        anchors.verticalCenter: parent.verticalCenter
      }

      // 3 vertical micro-segments (fits strictly inside single 27px slot)
      Column {
        visible: ergoModel.connected && ergoModel.batterySegments !== null && !ergoModel.isCharging
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Repeater {
          model: 3
          Rectangle {
            required property int index
            readonly property int segNumber: 3 - index
            readonly property bool active: ergoModel.batterySegments >= segNumber
            width: 3
            height: 3
            radius: 1
            color: active
              ? (button.active && button.useActiveColor ? button.activeColor : button.foreground)
              : Qt.rgba(button.foreground.r, button.foreground.g, button.foreground.b, 0.20)
          }
        }
      }

      // Charging micro-bolt
      Text {
        visible: ergoModel.connected && ergoModel.isCharging
        textFormat: Text.PlainText
        text: "󰂄"
        color: button.active && button.useActiveColor ? button.activeColor : button.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        anchors.verticalCenter: parent.verticalCenter
      }
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
