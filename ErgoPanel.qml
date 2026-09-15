import QtQuick
import qs.Commons
import qs.Ui

// Logitech MX Ergo trackball control card with complete keyboard & mouse navigation
PanelKeyCatcher {
  id: root

  blocked: root.isRecording || (shortcutInput && shortcutInput.activeFocus) || (cmdField && cmdField.activeFocus)

  required property QtObject bar
  required property QtObject model

  property int focusIndex: 0
  property bool cursorActive: false

  // Selected button tab: "back" | "forward" | "middle" | "tiltLeft" | "tiltRight"
  property string selectedButton: "back"
  // Button setup mode: "presets" | "shortcut" | "command"
  property string setupMode: "presets"
  // Shortcut recording active flag
  property bool isRecording: false
  // Language picker expanded flag
  property bool languageExpanded: false
  // Function keys expanded flag
  property bool fKeysExpanded: false

  readonly property color fgColor: bar ? bar.foreground : Color.foreground
  readonly property string fontFam: bar ? bar.fontFamily : Style.font.family

  readonly property real contentHeight: contentColumn.implicitHeight + Style.space(8)

  readonly property var buttonList: [
    { key: "back", labelKey: "btn_back" },
    { key: "forward", labelKey: "btn_forward" },
    { key: "middle", labelKey: "btn_middle" },
    { key: "tiltLeft", labelKey: "btn_tilt_left" },
    { key: "tiltRight", labelKey: "btn_tilt_right" }
  ]

  function buttonShortTitle(key) {
    var isRu = root.model.effectiveLanguage === "ru"
    if (key === "back") return isRu ? "◄ Назад" : "◄ Back"
    if (key === "forward") return isRu ? "Вперёд ►" : "Fwd ►"
    if (key === "middle") return isRu ? "● Колесо" : "● Mid"
    if (key === "tiltLeft") return isRu ? "◂ Влево" : "◂ Tilt L"
    if (key === "tiltRight") return isRu ? "Вправо ▸" : "Tilt R ▸"
    return key
  }

  function stepFocus(dir) {
    cursorActive = true
    focusIndex = (focusIndex + dir + 5) % 5
  }

  function syncActiveButton() {
    var act = root.model.getButtonAction(root.selectedButton)
    if (act === "custom_shortcut") {
      root.setupMode = "shortcut"
    } else if (act === "custom_command") {
      root.setupMode = "command"
    } else {
      root.setupMode = "presets"
    }
  }

  function addTokenToShortcut(token) {
    var cur = shortcutInput ? shortcutInput.text.trim() : ""
    var isMod = (token === "SUPER" || token === "CTRL" || token === "ALT" || token === "SHIFT")
    var nextText = ""
    if (cur === "") {
      nextText = isMod ? (token + " + ") : token
    } else if (cur.endsWith("+")) {
      nextText = cur + " " + token
    } else {
      if (isMod) {
        var parts = cur.split(/\s*\+\s*/)
        var idx = parts.indexOf(token)
        if (idx !== -1) {
          parts.splice(idx, 1)
          nextText = parts.join(" + ")
        } else {
          parts.unshift(token)
          nextText = parts.join(" + ")
        }
      } else {
        nextText = cur + " + " + token
      }
    }
    if (shortcutInput) shortcutInput.text = nextText
    root.model.setCustomShortcut(root.selectedButton, nextText.trim())
  }

  onSelectedButtonChanged: {
    root.isRecording = false
    syncActiveButton()
  }

  Component.onCompleted: {
    syncActiveButton()
  }

  function handleMove(dx, dy) {
    cursorActive = true
    if (dy !== 0) {
      if (dy > 0) {
        if (focusIndex <= 1) focusIndex = 2
        else if (focusIndex === 2) focusIndex = 3
        else if (focusIndex === 3) focusIndex = 4
        else focusIndex = 0
      } else {
        if (focusIndex === 0 || focusIndex === 1) focusIndex = 4
        else if (focusIndex === 2) focusIndex = 0
        else if (focusIndex === 3) focusIndex = 2
        else if (focusIndex === 4) focusIndex = 3
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
      } else if (focusIndex === 4) {
        // Switch selected button
        var curIdx = 0
        for (var i = 0; i < buttonList.length; i++) {
          if (buttonList[i].key === selectedButton) { curIdx = i; break }
        }
        var nextIdx = (curIdx + (dx > 0 ? 1 : -1) + buttonList.length) % buttonList.length
        selectedButton = buttonList[nextIdx].key
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

  Column {
    id: contentColumn
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    spacing: Style.space(10)

    // ---------- Header ----------
    Item {
      width: parent.width
      height: Style.space(26)
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

      Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        spacing: Style.space(6)

        // Connection Status Badge
        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: statusText.implicitWidth + Style.space(12)
          height: Style.space(20)
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
              ? root.model.transportText
              : root.model.t("disconnected")
            color: root.model.connected ? root.fgColor : Color.muted
            font.family: root.fontFam
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }

        // Language Picker Toggle Button
        Button {
          anchors.verticalCenter: parent.verticalCenter
          text: (root.model.language === "system" ? "AUTO" : root.model.effectiveLanguage.toUpperCase()) + (root.languageExpanded ? " ▴" : " ▾")
          fontSize: Style.font.caption
          foreground: root.fgColor
          fontFamily: root.fontFam
          bordered: true
          selected: root.languageExpanded
          active: root.languageExpanded
          onClicked: root.languageExpanded = !root.languageExpanded
        }
      }
    }

    // Expandable Language Picker Section
    Column {
      visible: root.languageExpanded
      width: parent.width
      spacing: Style.space(6)

      PanelSectionHeader {
        width: parent.width
        text: root.model.t("language_title")
        foreground: root.fgColor
        fontFamily: root.fontFam
      }

      Grid {
        id: languageGrid
        width: parent.width
        columns: 3
        spacing: Style.space(4)

        readonly property real itemWidth: Math.floor((width - spacing * 2) / 3)

        Repeater {
          model: [
            { code: "system", label: root.model.t("lang_system") },
            { code: "en", label: "English" },
            { code: "zh", label: "简体中文" },
            { code: "es", label: "Español" },
            { code: "ru", label: "Русский" },
            { code: "pt", label: "Português" },
            { code: "fr", label: "Français" },
            { code: "de", label: "Deutsch" },
            { code: "ja", label: "日本語" },
            { code: "ko", label: "한국어" },
            { code: "it", label: "Italiano" }
          ]

          Button {
            width: languageGrid.itemWidth
            text: modelData.label
            fontFamily: root.fontFam
            fontSize: Style.font.caption
            foreground: root.fgColor
            bordered: true
            selected: root.model.language === modelData.code
            active: root.model.language === modelData.code
            onClicked: {
              var code = modelData.code
              root.languageExpanded = false
              root.model.setLocale(code)
            }
          }
        }
      }
    }

    PanelSeparator {
      foreground: root.fgColor
    }

    // Connect Trackball Button (visible when disconnected)
    Button {
      visible: !root.model.connected
      width: parent.width
      text: root.model.isConnecting ? root.model.t("connecting") : ("󰂯 " + root.model.t("connect_device"))
      fontSize: Style.font.bodySmall
      foreground: root.fgColor
      fontFamily: root.fontFam
      bordered: true
      onClicked: root.model.reconnectDevice()
    }

    // ---------- Battery (3 Hardware Segments) ----------
    Column {
      width: parent.width
      spacing: Style.space(4)

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
          font.pixelSize: Style.font.bodySmall
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

      // 3-Segment discrete battery gauge (hardware matching)
      Row {
        id: batTrack
        width: parent.width
        height: Style.space(5)
        spacing: Style.space(4)

        readonly property real segWidth: (width - spacing * 2) / 3

        Repeater {
          model: 3
          Rectangle {
            required property int index
            width: batTrack.segWidth
            height: batTrack.height
            radius: height / 2
            readonly property bool filled: root.model.batterySegments !== null && root.model.batterySegments > index
            color: filled
              ? root.fgColor
              : Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.15)

            Behavior on color {
              ColorAnimation { duration: 200 }
            }
          }
        }
      }
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

    // Acceleration Profile (Adaptive vs Flat)
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

    // Sensitivity Slider
    Column {
      width: parent.width
      spacing: Style.space(3)

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
      height: Style.space(26)
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

    // Auto-reconnect on Wake Toggle Row
    Item {
      width: parent.width
      height: Style.space(26)
      implicitHeight: height

      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: root.model.t("auto_reconnect")
        color: root.fgColor
        font.family: root.fontFam
        font.pixelSize: Style.font.bodySmall
      }

      ToggleSwitch {
        id: autoRecSwitch
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: root.model.autoReconnect
        interactive: false
        foreground: root.fgColor
        onToggled: root.model.setAutoReconnect(!root.model.autoReconnect)
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          root.model.setAutoReconnect(!root.model.autoReconnect)
        }
      }
    }

    // Cursor Polling Rate / Low Latency Mode Row (OpenDesign 2-line layout with ToggleSwitch)
    Item {
      width: parent.width
      height: Style.space(32)
      implicitHeight: height

      Column {
        anchors.left: parent.left
        anchors.right: lowLatencySwitch.left
        anchors.rightMargin: Style.space(12)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(2)

        Text {
          textFormat: Text.PlainText
          text: root.model.t("polling_rate")
          color: root.fgColor
          font.family: root.fontFam
          font.pixelSize: Style.font.bodySmall
        }

        Text {
          textFormat: Text.PlainText
          text: root.model.lowLatencyEnabled
            ? root.model.t("rate_low_latency")
            : root.model.t("rate_standard")
          color: root.model.lowLatencyEnabled ? root.fgColor : Color.muted
          font.family: root.fontFam
          font.pixelSize: Style.font.caption
        }
      }

      ToggleSwitch {
        id: lowLatencySwitch
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: root.model.lowLatencyEnabled
        interactive: false
        foreground: root.fgColor
        onToggled: {
          if (root.model.lowLatencyEnabled) {
            root.model.revertLowLatency()
          } else {
            root.model.applyLowLatency()
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (root.model.lowLatencyEnabled) {
            root.model.revertLowLatency()
          } else {
            root.model.applyLowLatency()
          }
        }
      }
    }

    PanelSeparator {
      foreground: root.fgColor
    }

    // ---------- Button Mapping Section ----------
    PanelSectionHeader {
      text: root.model.t("button_mapping")
      foreground: root.fgColor
      fontFamily: root.fontFam
    }

    // 5 Button Selector Tabs
    Row {
      id: btnSelectorRow
      width: parent.width
      spacing: Style.space(4)

      readonly property real tabWidth: (width - spacing * 4) / 5

      Repeater {
        model: root.buttonList

        delegate: Rectangle {
          required property var modelData
          width: btnSelectorRow.tabWidth
          height: Style.space(38)
          radius: Style.space(4)

          readonly property bool isCurrent: root.selectedButton === modelData.key
          readonly property bool hasKeyCursor: root.cursorActive && root.focusIndex === 4 && isCurrent
          readonly property string currentAction: root.model.getButtonAction(modelData.key)
          readonly property string currentActionLabel: root.model.actionLabel(currentAction, modelData.key)

          color: isCurrent
            ? Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.22)
            : (btnHover.hovered
              ? Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.10)
              : Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.04))

          border.width: 1
          border.color: hasKeyCursor
            ? root.fgColor
            : (isCurrent
              ? Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.45)
              : Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.12))

          Column {
            anchors.centerIn: parent
            width: parent.width - Style.space(4)
            spacing: 1

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              width: parent.width
              horizontalAlignment: Text.AlignHCenter
              elide: Text.ElideRight
              textFormat: Text.PlainText
              text: root.buttonShortTitle(modelData.key)
              color: isCurrent ? root.fgColor : Color.muted
              font.family: root.fontFam
              font.pixelSize: Style.font.caption
              font.bold: isCurrent
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              width: parent.width
              horizontalAlignment: Text.AlignHCenter
              elide: Text.ElideRight
              textFormat: Text.PlainText
              text: currentActionLabel
              color: isCurrent ? root.fgColor : Qt.darker(Color.muted, 1.2)
              font.family: root.fontFam
              font.pixelSize: Style.font.caption - 1
            }
          }

          HoverHandler { id: btnHover }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.focusIndex = 4
              root.selectedButton = modelData.key
              root.isRecording = false
            }
          }
        }
      }
    }

    // Active Button Card
    Rectangle {
      width: parent.width
      radius: Style.space(6)
      color: Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.05)
      border.width: 1
      border.color: Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.12)
      height: activeCardCol.implicitHeight + Style.space(16)

      Column {
        id: activeCardCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Style.space(8)
        spacing: Style.space(8)

        // Status banner of selected button
        Item {
          width: parent.width
          height: Style.space(24)
          implicitHeight: height

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.PlainText
            text: root.model.t("selected_button") + ":"
            color: Color.muted
            font.family: root.fontFam
            font.pixelSize: Style.font.caption
          }

          Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(6)

            Rectangle {
              width: activeActionText.implicitWidth + Style.space(12)
              height: Style.space(20)
              radius: Style.space(3)
              color: Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.15)
              border.width: 1
              border.color: Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.3)

              Text {
                id: activeActionText
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: root.model.actionLabel(root.model.getButtonAction(root.selectedButton), root.selectedButton)
                color: root.fgColor
                font.family: root.fontFam
                font.pixelSize: Style.font.caption
                font.bold: true
              }
            }

            Button {
              text: "↺ " + root.model.t("btn_reset_default")
              fontSize: Style.font.caption
              foreground: root.fgColor
              fontFamily: root.fontFam
              bordered: true
              onClicked: {
                root.model.resetButtonToDefault(root.selectedButton)
                root.setupMode = "presets"
                root.isRecording = false
              }
            }
          }
        }

        // Mode Switcher (Presets | Record Shortcut | Command)
        Row {
          width: parent.width
          spacing: Style.space(6)

          readonly property real modeBtnWidth: (width - spacing * 2) / 3

          Button {
            width: parent.modeBtnWidth
            text: root.model.t("tab_presets")
            fontSize: Style.font.caption
            foreground: root.fgColor
            fontFamily: root.fontFam
            bordered: true
            selected: root.setupMode === "presets"
            active: root.setupMode === "presets"
            onClicked: { root.setupMode = "presets"; root.isRecording = false }
          }

          Button {
            width: parent.modeBtnWidth
            text: root.model.t("tab_shortcut")
            fontSize: Style.font.caption
            foreground: root.fgColor
            fontFamily: root.fontFam
            bordered: true
            selected: root.setupMode === "shortcut"
            active: root.setupMode === "shortcut"
            onClicked: { root.setupMode = "shortcut"; root.isRecording = false }
          }

          Button {
            width: parent.modeBtnWidth
            text: root.model.t("tab_command")
            fontSize: Style.font.caption
            foreground: root.fgColor
            fontFamily: root.fontFam
            bordered: true
            selected: root.setupMode === "command"
            active: root.setupMode === "command"
            onClicked: { root.setupMode = "command"; root.isRecording = false }
          }
        }

        // Mode 1: Presets Catalog (Categorized pills)
        Column {
          visible: root.setupMode === "presets"
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            model: [
              {
                title: root.model.t("category_workspaces"),
                items: [
                  { id: "workspace_next", label: root.model.t("action_workspace_next") },
                  { id: "workspace_prev", label: root.model.t("action_workspace_prev") }
                ]
              },
              {
                title: root.model.t("category_windows"),
                items: [
                  { id: "window_close", label: root.model.t("action_window_close") },
                  { id: "window_float", label: root.model.t("action_window_float") },
                  { id: "window_fullscreen", label: root.model.t("action_window_fullscreen") },
                  { id: "window_next", label: root.model.t("action_window_next") }
                ]
              },
              {
                title: root.model.t("category_media"),
                items: [
                  { id: "media_play_pause", label: root.model.t("action_media_play_pause") },
                  { id: "mute", label: root.model.t("action_mute") },
                  { id: "media_next", label: root.model.t("action_media_next") },
                  { id: "media_prev", label: root.model.t("action_media_prev") }
                ]
              },
              {
                title: root.model.t("category_browser"),
                items: [
                  { id: "tab_next", label: root.model.t("action_tab_next") },
                  { id: "tab_prev", label: root.model.t("action_tab_prev") },
                  { id: "browser_back", label: root.model.t("action_browser_back") },
                  { id: "browser_forward", label: root.model.t("action_browser_forward") }
                ]
              },
              {
                title: root.model.t("category_system"),
                items: [
                  { id: "overview", label: root.model.t("action_overview") },
                  { id: "screenshot", label: root.model.t("action_screenshot") },
                  { id: "default", label: root.model.t("clear_binding") }
                ]
              }
            ]

            delegate: Column {
              required property var modelData
              width: parent.width
              spacing: Style.space(3)

              Text {
                textFormat: Text.PlainText
                text: modelData.title
                color: Color.muted
                font.family: root.fontFam
                font.pixelSize: Style.font.caption
                font.bold: true
              }

              Flow {
                width: parent.width
                spacing: Style.space(4)

                Repeater {
                  model: modelData.items

                  delegate: Rectangle {
                    required property var modelData
                    width: itemText.implicitWidth + Style.space(12)
                    height: Style.space(22)
                    radius: Style.space(3)

                    readonly property bool isSelected: root.model.getButtonAction(root.selectedButton) === modelData.id

                    color: isSelected
                      ? Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.25)
                      : (itHover.hovered
                        ? Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.12)
                        : Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.05))

                    border.width: 1
                    border.color: isSelected
                      ? root.fgColor
                      : (itHover.hovered
                        ? Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.35)
                        : Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.15))

                    Text {
                      id: itemText
                      anchors.centerIn: parent
                      textFormat: Text.PlainText
                      text: modelData.label
                      color: isSelected ? root.fgColor : (itHover.hovered ? root.fgColor : Color.muted)
                      font.family: root.fontFam
                      font.pixelSize: Style.font.caption
                      font.bold: isSelected
                    }

                    HoverHandler { id: itHover }

                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        root.model.setButtonAction(root.selectedButton, modelData.id)
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // Mode 2: Custom Shortcut (Direct Input + System Chips + Key Recorder)
        Column {
          visible: root.setupMode === "shortcut"
          width: parent.width
          spacing: Style.space(6)

          // Direct editable text input field with Clear and Apply buttons
          Row {
            width: parent.width
            spacing: Style.space(4)

            TextField {
              id: shortcutInput
              width: parent.width - btnClear.implicitWidth - btnApply.implicitWidth - Style.space(8)
              font.pixelSize: Style.font.bodySmall
              placeholderText: root.model.t("shortcut_input_placeholder")
              text: root.model.getCustomShortcut(root.selectedButton)
              onEditingFinished: {
                root.model.setCustomShortcut(root.selectedButton, text)
              }
              Binding {
                target: shortcutInput
                property: "text"
                value: root.model.getCustomShortcut(root.selectedButton)
              }

              Keys.onPressed: function(event) {
                if (!root.isRecording) return

                if (event.key === Qt.Key_Escape) {
                  root.isRecording = false
                  event.accepted = true
                  return
                }

                // Ignore solitary modifiers
                if (event.key === Qt.Key_Control || event.key === Qt.Key_Shift ||
                    event.key === Qt.Key_Alt || event.key === Qt.Key_Meta) {
                  event.accepted = true
                  return
                }

                var mods = []
                if (event.modifiers & Qt.MetaModifier) mods.push("SUPER")
                if (event.modifiers & Qt.ControlModifier) mods.push("CTRL")
                if (event.modifiers & Qt.AltModifier) mods.push("ALT")
                if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT")

                var keyName = ""
                if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                  keyName = String(event.key - Qt.Key_0)
                } else if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z) {
                  keyName = String.fromCharCode(event.key)
                } else if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F12) {
                  keyName = "F" + (event.key - Qt.Key_F1 + 1)
                } else if (event.key === Qt.Key_Insert) {
                  keyName = "Insert"
                } else if (event.key === Qt.Key_Delete) {
                  keyName = "Delete"
                } else if (event.key === Qt.Key_Home) {
                  keyName = "Home"
                } else if (event.key === Qt.Key_End) {
                  keyName = "End"
                } else if (event.key === Qt.Key_PageUp) {
                  keyName = "PageUp"
                } else if (event.key === Qt.Key_PageDown) {
                  keyName = "PageDown"
                } else if (event.key === Qt.Key_Print) {
                  keyName = "Print"
                } else if (event.key === Qt.Key_Pause) {
                  keyName = "Pause"
                } else if (event.key === Qt.Key_Menu) {
                  keyName = "Menu"
                } else if (event.key === Qt.Key_Space) {
                  keyName = "Space"
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  keyName = "Return"
                } else if (event.key === Qt.Key_Tab) {
                  keyName = "Tab"
                } else if (event.key === Qt.Key_Backtab) {
                  keyName = "Tab"
                  if (mods.indexOf("SHIFT") === -1) mods.push("SHIFT")
                } else if (event.key === Qt.Key_Backspace) {
                  keyName = "BackSpace"
                } else if (event.key === Qt.Key_Left) {
                  keyName = "Left"
                } else if (event.key === Qt.Key_Right) {
                  keyName = "Right"
                } else if (event.key === Qt.Key_Up) {
                  keyName = "Up"
                } else if (event.key === Qt.Key_Down) {
                  keyName = "Down"
                } else if (event.text && event.text.trim().length === 1) {
                  keyName = event.text.trim().toUpperCase()
                }

                if (keyName !== "") {
                  var full = (mods.length > 0 ? (mods.join(" + ") + " + ") : "") + keyName
                  shortcutInput.text = full
                  root.model.setCustomShortcut(root.selectedButton, full)
                  root.isRecording = false
                  event.accepted = true
                }
              }
            }

            Button {
              id: btnClear
              text: root.model.t("btn_clear")
              fontSize: Style.font.caption
              foreground: root.fgColor
              fontFamily: root.fontFam
              bordered: true
              onClicked: {
                shortcutInput.text = ""
                root.model.setCustomShortcut(root.selectedButton, "")
              }
            }

            Button {
              id: btnApply
              text: root.model.t("btn_apply")
              fontSize: Style.font.caption
              foreground: root.fgColor
              fontFamily: root.fontFam
              bordered: true
              onClicked: {
                root.model.setCustomShortcut(root.selectedButton, shortcutInput.text.trim())
              }
            }
          }

          // Row 1: Quick Modifier Chips (SUPER, CTRL, ALT, SHIFT)
          Row {
            id: modChipsRow
            width: parent.width
            spacing: Style.space(4)

            readonly property real modWidth: (width - spacing * 3) / 4

            Repeater {
              model: ["SUPER", "CTRL", "ALT", "SHIFT"]
              delegate: Rectangle {
                required property string modelData
                width: modChipsRow.modWidth
                height: Style.space(22)
                radius: Style.space(3)
                color: chipHover.hovered
                  ? Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.20)
                  : Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.08)
                border.width: 1
                border.color: Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.25)

                Text {
                  anchors.centerIn: parent
                  textFormat: Text.PlainText
                  text: "+ " + modelData
                  color: root.fgColor
                  font.family: root.fontFam
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }

                HoverHandler { id: chipHover }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.addTokenToShortcut(modelData)
                }
              }
            }
          }

          // Row 2: System & Navigation Chips (Insert, Delete, Home, End, PgUp, PgDn...)
          Flow {
            width: parent.width
            spacing: Style.space(4)

            Repeater {
              model: [
                { id: "Insert", label: "Insert" },
                { id: "Delete", label: "Delete" },
                { id: "Home", label: "Home" },
                { id: "End", label: "End" },
                { id: "PageUp", label: "PgUp" },
                { id: "PageDown", label: "PgDn" },
                { id: "Tab", label: "Tab" },
                { id: "Return", label: "Return" },
                { id: "Space", label: "Space" },
                { id: "Escape", label: "Esc" }
              ]
              delegate: Rectangle {
                required property var modelData
                width: navText.implicitWidth + Style.space(12)
                height: Style.space(22)
                radius: Style.space(3)
                color: navHover.hovered
                  ? Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.20)
                  : Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.06)
                border.width: 1
                border.color: Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.20)

                Text {
                  id: navText
                  anchors.centerIn: parent
                  textFormat: Text.PlainText
                  text: modelData.label
                  color: root.fgColor
                  font.family: root.fontFam
                  font.pixelSize: Style.font.caption
                }

                HoverHandler { id: navHover }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.addTokenToShortcut(modelData.id)
                }
              }
            }
          }

          // Row 3: Workspace Digits 1..9 (fits 100% width, never overflows)
          Row {
            id: digitChipsRow
            width: parent.width
            spacing: Style.space(3)

            readonly property real digitWidth: (width - spacing * 8) / 9

            Repeater {
              model: ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
              delegate: Rectangle {
                required property string modelData
                width: digitChipsRow.digitWidth
                height: Style.space(22)
                radius: Style.space(3)
                color: numHover.hovered
                  ? Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.20)
                  : Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.05)
                border.width: 1
                border.color: Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.20)

                Text {
                  anchors.centerIn: parent
                  textFormat: Text.PlainText
                  text: modelData
                  color: root.fgColor
                  font.family: root.fontFam
                  font.pixelSize: Style.font.caption
                }

                HoverHandler { id: numHover }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.addTokenToShortcut(modelData)
                }
              }
            }
          }

          // Row 4: Function Keys Toggle + Extra System Keys
          Row {
            width: parent.width
            spacing: Style.space(4)

            Button {
              text: "F1–F12" + (root.fKeysExpanded ? " ▴" : " ▾")
              fontSize: Style.font.caption
              foreground: root.fgColor
              fontFamily: root.fontFam
              bordered: true
              selected: root.fKeysExpanded
              active: root.fKeysExpanded
              onClicked: root.fKeysExpanded = !root.fKeysExpanded
            }

            Repeater {
              model: ["Print", "Pause", "Menu"]
              delegate: Rectangle {
                required property string modelData
                width: sysText.implicitWidth + Style.space(12)
                height: Style.space(22)
                radius: Style.space(3)
                color: sysHover.hovered
                  ? Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.20)
                  : Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.06)
                border.width: 1
                border.color: Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.20)

                Text {
                  id: sysText
                  anchors.centerIn: parent
                  textFormat: Text.PlainText
                  text: modelData
                  color: root.fgColor
                  font.family: root.fontFam
                  font.pixelSize: Style.font.caption
                }

                HoverHandler { id: sysHover }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.addTokenToShortcut(modelData)
                }
              }
            }
          }

          // Expandable F1-F12 Grid
          Grid {
            visible: root.fKeysExpanded
            width: parent.width
            columns: 6
            spacing: Style.space(3)

            readonly property real fKeyWidth: (width - spacing * 5) / 6

            Repeater {
              model: ["F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"]
              delegate: Rectangle {
                required property string modelData
                width: parent.fKeyWidth
                height: Style.space(22)
                radius: Style.space(3)
                color: fHover.hovered
                  ? Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.20)
                  : Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.06)
                border.width: 1
                border.color: Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.20)

                Text {
                  anchors.centerIn: parent
                  textFormat: Text.PlainText
                  text: modelData
                  color: root.fgColor
                  font.family: root.fontFam
                  font.pixelSize: Style.font.caption
                }

                HoverHandler { id: fHover }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.addTokenToShortcut(modelData)
                }
              }
            }
          }

          // Interactive Key Recording Box (Zero emoji, clean vector circle)
          Rectangle {
            id: recorderBox
            width: parent.width
            height: Style.space(32)
            radius: Style.space(4)
            color: root.isRecording
              ? Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.22)
              : Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.08)
            border.width: root.isRecording ? 2 : 1
            border.color: root.isRecording
              ? root.fgColor
              : (recHover.hovered ? Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.4) : Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.2))

            Row {
              anchors.centerIn: parent
              spacing: Style.space(8)

              // Geometric vector record indicator (no emoji glyph)
              Rectangle {
                width: 8
                height: 8
                radius: 4
                color: root.isRecording ? root.fgColor : "transparent"
                border.width: 1.5
                border.color: root.fgColor
                anchors.verticalCenter: parent.verticalCenter

                Behavior on color { ColorAnimation { duration: 150 } }
              }

              Text {
                textFormat: Text.PlainText
                text: root.isRecording
                  ? root.model.t("recording_active")
                  : root.model.t("btn_record")
                color: root.fgColor
                font.family: root.fontFam
                font.pixelSize: Style.font.caption
                font.bold: root.isRecording
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            HoverHandler { id: recHover }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.isRecording = !root.isRecording
                if (root.isRecording) {
                  shortcutInput.forceActiveFocus()
                }
              }
            }
          }
        }

        // Mode 3: Direct Shell Command
        Column {
          visible: root.setupMode === "command"
          width: parent.width
          spacing: Style.space(4)

          TextField {
            id: cmdField
            width: parent.width
            font.pixelSize: Style.font.bodySmall
            placeholderText: root.model.t("custom_shortcut_placeholder")
            text: root.model.getCustomCommand(root.selectedButton)
            onEditingFinished: {
              root.model.setCustomCommand(root.selectedButton, text)
            }
            Binding {
              target: cmdField
              property: "text"
              value: root.model.getCustomCommand(root.selectedButton)
            }
          }
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
