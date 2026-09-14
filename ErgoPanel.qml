import QtQuick
import qs.Commons
import qs.Ui

// Logitech MX Ergo trackball control card with complete keyboard & mouse navigation
PanelKeyCatcher {
  id: root

  required property QtObject bar
  required property QtObject model

  property int focusIndex: 0
  property bool cursorActive: false

  readonly property color fgColor: bar ? bar.foreground : Color.foreground
  readonly property string fontFam: bar ? bar.fontFamily : Style.font.family

  readonly property real contentHeight: contentColumn.implicitHeight + Style.space(8)

  function stepFocus(dir) {
    cursorActive = true
    focusIndex = (focusIndex + dir + 4) % 4
  }

  function handleMove(dx, dy) {
    cursorActive = true
    if (dy !== 0) {
      if (dy > 0) {
        if (focusIndex <= 1) focusIndex = 2
        else if (focusIndex === 2) focusIndex = 3
        else focusIndex = 0
      } else {
        if (focusIndex === 3) focusIndex = 2
        else if (focusIndex === 2) focusIndex = 0
        else focusIndex = 3
      }
      return
    }

    if (dx !== 0) {
      if (focusIndex <= 1) {
        focusIndex = dx > 0 ? 1 : 0
      } else if (focusIndex === 2) {
        root.model.setSensitivity(root.model.sensitivity + dx * 0.05)
      } else if (focusIndex === 3) {
        root.model.setNaturalScroll(!root.model.naturalScroll)
      }
    }
  }

  function handleActivate() {
    cursorActive = true
    if (focusIndex === 0) {
      root.model.setAccelProfile("adaptive")
    } else if (focusIndex === 1) {
      root.model.setAccelProfile("flat")
    } else if (focusIndex === 2) {
      root.model.setSensitivity(0.0)
    } else if (focusIndex === 3) {
      root.model.setNaturalScroll(!root.model.naturalScroll)
    }
  }

  onTabRequested: function(dir) { root.stepFocus(dir) }
  onMoveRequested: function(dx, dy) { root.handleMove(dx, dy) }
  onActivateRequested: root.handleActivate()
  onTextKey: function(t) {
    if (t === "1") {
      root.focusIndex = 0
      root.model.setAccelProfile("adaptive")
    } else if (t === "2") {
      root.focusIndex = 1
      root.model.setAccelProfile("flat")
    } else if (t === "s" || t === "S" || t === "ы" || t === "Ы") {
      root.focusIndex = 3
      root.model.setNaturalScroll(!root.model.naturalScroll)
    }
  }

  Column {
    id: contentColumn
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    spacing: Style.space(12)

    // ---------- Header ----------
    Item {
      width: parent.width
      height: Style.space(28)
      implicitHeight: height

      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: root.model.t("plugin_name")
        color: root.fgColor
        font.family: root.fontFam
        font.pixelSize: Style.font.title
        font.bold: true
      }

      // Connection Status Badge
      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        width: statusText.implicitWidth + Style.space(16)
        height: Style.space(22)
        radius: height / 2
        color: root.model.connected
          ? Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.15)
          : Qt.rgba(Color.muted.r, Color.muted.g, Color.muted.b, 0.12)
        border.width: 1
        border.color: root.model.connected
          ? Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.3)
          : Qt.rgba(Color.muted.r, Color.muted.g, Color.muted.b, 0.25)

        Text {
          id: statusText
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: root.model.connected
            ? ("● " + root.model.t("connected"))
            : ("○ " + root.model.t("disconnected"))
          color: root.model.connected ? root.fgColor : Color.muted
          font.family: root.fontFam
          font.pixelSize: Style.font.caption
          font.bold: true
        }
      }
    }

    PanelSeparator {
      foreground: root.fgColor
    }

    // ---------- Device Status Section ----------
    PanelSectionHeader {
      text: root.model.t("hardware_status")
      foreground: root.fgColor
      fontFamily: root.fontFam
    }

    // Battery Tier & Gauge
    Column {
      width: parent.width
      spacing: Style.space(6)

      Item {
        width: parent.width
        height: batLabel.implicitHeight
        implicitHeight: height

        Text {
          id: batLabel
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: root.model.batteryIcon + "  " + root.model.t("battery")
          color: root.fgColor
          font.family: root.fontFam
          font.pixelSize: Style.font.body
        }

        Text {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: root.model.connected
            ? root.model.batteryLevelText
            : root.model.t("disconnected")
          color: root.model.connected ? root.fgColor : Color.muted
          font.family: root.fontFam
          font.pixelSize: Style.font.bodySmall
          font.bold: true
        }
      }

      // Battery level progress bar
      Rectangle {
        id: batTrack
        width: parent.width
        height: Style.space(6)
        radius: height / 2
        color: Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.12)

        Rectangle {
          id: batFill
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          radius: parent.radius
          color: root.fgColor
          width: root.model.batteryFraction !== null
            ? Math.max(parent.height, parent.width * root.model.batteryFraction)
            : 0

          Behavior on width {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
          }
        }
      }
    }

    // MAC Address
    Row {
      width: parent.width
      spacing: Style.space(8)

      Text {
        textFormat: Text.PlainText
        text: root.model.t("mac_address") + ":"
        color: Color.muted
        font.family: root.fontFam
        font.pixelSize: Style.font.caption
      }

      Text {
        textFormat: Text.PlainText
        text: root.model.targetAddress
        color: root.fgColor
        font.family: root.fontFam
        font.pixelSize: Style.font.caption
      }
    }

    // Hardware Precision Note
    Text {
      width: parent.width
      wrapMode: Text.WordWrap
      textFormat: Text.PlainText
      text: root.model.t("hardware_precision_info")
      color: Color.muted
      font.family: root.fontFam
      font.pixelSize: Style.font.caption
    }

    PanelSeparator {
      foreground: root.fgColor
    }

    // ---------- Pointer & Hyprland Controls ----------
    PanelSectionHeader {
      text: root.model.t("pointer_settings")
      foreground: root.fgColor
      fontFamily: root.fontFam
    }

    // Acceleration Profile
    Column {
      width: parent.width
      spacing: Style.space(6)

      Text {
        textFormat: Text.PlainText
        text: root.model.t("accel_profile")
        color: root.fgColor
        font.family: root.fontFam
        font.pixelSize: Style.font.bodySmall
      }

      Row {
        id: profileRow
        width: parent.width
        spacing: Style.space(8)

        readonly property real btnWidth: (width - spacing) / 2

        Button {
          width: profileRow.btnWidth
          text: root.model.t("accel_adaptive")
          fontSize: Style.font.bodySmall
          foreground: root.fgColor
          fontFamily: root.fontFam
          bordered: true
          selected: root.model.accelProfile === "adaptive"
          active: root.model.accelProfile === "adaptive"
          hasCursor: root.cursorActive && root.focusIndex === 0
          onClicked: {
            root.focusIndex = 0
            root.model.setAccelProfile("adaptive")
          }
        }

        Button {
          width: profileRow.btnWidth
          text: root.model.t("accel_flat")
          fontSize: Style.font.bodySmall
          foreground: root.fgColor
          fontFamily: root.fontFam
          bordered: true
          selected: root.model.accelProfile === "flat"
          active: root.model.accelProfile === "flat"
          hasCursor: root.cursorActive && root.focusIndex === 1
          onClicked: {
            root.focusIndex = 1
            root.model.setAccelProfile("flat")
          }
        }
      }
    }

    // Sensitivity Slider
    Column {
      width: parent.width
      spacing: Style.space(4)

      Item {
        width: parent.width
        height: sensLabel.implicitHeight
        implicitHeight: height

        Text {
          id: sensLabel
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: root.model.t("sensitivity") + (root.cursorActive && root.focusIndex === 2 ? " [◄ ►]" : "")
          color: root.cursorActive && root.focusIndex === 2 ? root.fgColor : Color.muted
          font.family: root.fontFam
          font.pixelSize: Style.font.bodySmall
          font.bold: root.cursorActive && root.focusIndex === 2
        }

        Text {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: (root.model.sensitivity > 0 ? "+" : "") + root.model.sensitivity.toFixed(2)
          color: root.fgColor
          font.family: root.fontFam
          font.pixelSize: Style.font.bodySmall
          font.bold: true
        }
      }

      PanelSlider {
        width: parent.width
        bar: root.bar
        minimum: -1.0
        maximum: 1.0
        step: 0.05
        value: root.model.sensitivity
        onMoved: function(val) {
          root.focusIndex = 2
          root.model.setSensitivity(val)
        }
        onReleased: function(val) {
          root.focusIndex = 2
          root.model.setSensitivity(val)
        }
      }
    }

    // Natural Scrolling Toggle Row
    Item {
      width: parent.width
      height: Style.space(32)
      implicitHeight: height

      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: root.model.t("natural_scroll")
        color: root.fgColor
        font.family: root.fontFam
        font.pixelSize: Style.font.bodySmall
      }

      ToggleSwitch {
        id: naturalSwitch
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: root.model.naturalScroll
        interactive: false
        hasCursor: root.cursorActive && root.focusIndex === 3
        foreground: root.fgColor
        onToggled: root.model.setNaturalScroll(!root.model.naturalScroll)
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          root.focusIndex = 3
          root.model.setNaturalScroll(!root.model.naturalScroll)
        }
      }
    }

    // Bottom breathing margin
    Item {
      width: parent.width
      height: Style.space(4)
      implicitHeight: height
    }
  }
}
