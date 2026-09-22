import QtQuick
import QtQuick.Effects
import QtQuick.Controls as Controls
import qs.Commons
import qs.Ui

// Trackball controls hosted by the shell keyboard panel.
PanelKeyCatcher {
  id: root

  component ActionButton: Button {
    id: control
    focusable: true
    Accessible.role: Accessible.Button
    Accessible.name: control.text
    Accessible.onPressAction: if (control.enabled) control.clicked()
  }

  blocked: root.isRecording || (shortcutInput && shortcutInput.activeFocus) || (cmdField && cmdField.activeFocus)

  required property QtObject bar
  required property QtObject model

  property int focusIndex: 4
  property bool cursorActive: false
  property string panelPage: "buttons"
  property bool editingButton: false
  readonly property var languageCodes: ["system", "en", "zh", "es", "ru", "pt", "fr", "de", "ja", "ko", "it"]

  function resetViewport() {
    root.forceActiveFocus()
    Qt.callLater(function () { viewport.contentY = 0 })
  }

  function showPage(page) {
    if (page !== "buttons" && page !== "pointer" && page !== "device") return
    root.isRecording = false
    root.editingButton = false
    root.languageExpanded = false
    root.panelPage = page
    root.focusIndex = root.cursorActive ? -1 : (page === "buttons" ? 4 : page === "pointer" ? 0 : 5)
    resetViewport()
  }

  function editButton(key) {
    if (!root.buttonList.some(function (button) { return button.key === key })) return
    root.selectedButton = key
    root.isRecording = false
    root.languageExpanded = false
    root.panelPage = "buttons"
    root.editingButton = true
    syncActiveButton()
    shortcutInput.text = root.model.getCustomShortcut(key)
    cmdField.text = root.model.getCustomCommand(key)
    resetViewport()
  }

  function finishButtonEdit() {
    root.showPage("buttons")
    root.focusIndex = 4
  }

  Keys.onEscapePressed: function (event) {
    if (root.isRecording) root.isRecording = false
    else if (root.languageExpanded) { root.languageExpanded = false; root.focusIndex = -2; root.forceActiveFocus() }
    else if (root.editingButton) root.showPage("buttons")
    else root.closeRequested()
    event.accepted = true
  }


  // Selected physical button: "back" | "forward" | "middle" | "tiltLeft" | "tiltRight"
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
  readonly property color dim: Qt.rgba(fgColor.r, fgColor.g, fgColor.b, 0.85)
  readonly property string fontFam: bar ? bar.fontFamily : Style.font.family

  readonly property real contentHeight: contentColumn.implicitHeight + Style.space(8)

  readonly property var buttonList: [
    { key: "back", labelKey: "btn_back" },
    { key: "forward", labelKey: "btn_forward" },
    { key: "middle", labelKey: "btn_middle" },
    { key: "tiltLeft", labelKey: "btn_tilt_left" },
    { key: "tiltRight", labelKey: "btn_tilt_right" }
  ]

  readonly property string selectedAction: root.model.getButtonAction(root.selectedButton)
  onSelectedActionChanged: syncActiveButton()

  function selectedButtonLabel() {
    for (var i = 0; i < buttonList.length; ++i)
      if (buttonList[i].key === selectedButton) return root.model.t(buttonList[i].labelKey)
    return ""
  }

  onFocusIndexChanged: Qt.callLater(ensureCursorVisible)
  function ensureCursorVisible() {
    if (!cursorActive || editingButton) return
    if (focusIndex === -2 || focusIndex === -1) { viewport.contentY = 0; return }
    var target = focusIndex >= 10 ? languageGrid : focusIndex === -3 ? connectButton : focusIndex === -4 ? retrySettingsButton : focusIndex <= 1 ? profileRow : focusIndex === 2 ? sensitivityColumn
      : focusIndex === 3 ? naturalRow : focusIndex === 5 ? autoReconnectRow : focusIndex === 6 ? latencyRow : (btnSelectorRow.selectedControl || btnSelectorRow)
    var y = target.mapToItem(viewport.contentItem, 0, 0).y
    var next = y < viewport.contentY ? y : Math.max(viewport.contentY, y + target.height - viewport.height)
    viewport.contentY = Math.max(0, Math.min(viewport.contentHeight - viewport.height, next))
  }

  function stepFocus(dir) {
    cursorActive = true
    if (editingButton) {
      var controls = []
      collectEditorControls(contentColumn, controls)
      if (controls.length === 0) return
      var current = controls.findIndex(function (control) { return control.activeFocus })
      var index = current < 0 ? (dir > 0 ? 0 : controls.length - 1)
        : (current + dir + controls.length) % controls.length
      var target = controls[index]
      target.forceActiveFocus()
      var y = target.mapToItem(viewport.contentItem, 0, 0).y
      viewport.contentY = Math.max(0, Math.min(viewport.contentHeight - viewport.height,
        y < viewport.contentY ? y : Math.max(viewport.contentY, y + target.height - viewport.height)))
      return
    }
    root.forceActiveFocus()
    var order = [-2]
    if (languageExpanded) for (var code = 0; code < languageCodes.length; code++) order.push(10 + code)
    if (!root.model.connected && !root.model.isConnecting && root.model.canReconnect) order.push(-3)
    if (retrySettingsButton.visible && retrySettingsButton.enabled) order.push(-4)
    order = order.concat(panelPage === "buttons" ? [-1, 4] : panelPage === "pointer" ? [-1, 0, 1, 2, 3] : [-1, 5])
    if (panelPage === "device" && profileAction.enabled) order.push(6)
    var index = order.indexOf(focusIndex)
    focusIndex = order[(index + dir + order.length) % order.length]
  }

  function collectEditorControls(item, controls) {
    if (!item.visible || !item.enabled) return
    if (item.activeFocusOnTab) { controls.push(item); return }
    for (var i = 0; i < item.children.length; ++i) collectEditorControls(item.children[i], controls)
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
  }

  onSelectedButtonChanged: {
    root.isRecording = false
    syncActiveButton()
    Qt.callLater(ensureCursorVisible)
  }

  Component.onCompleted: {
    syncActiveButton()
  }

  function handleMove(dx, dy) {
    cursorActive = true
    if (editingButton) return
    if (focusIndex === -2 || focusIndex === -3 || focusIndex === -4 || focusIndex >= 10) {
      stepFocus(dx || dy)
      return
    }
    if (focusIndex === -1) {
      if (dx !== 0) {
        var pages = ["buttons", "pointer", "device"]
        showPage(pages[(pages.indexOf(panelPage) + (dx > 0 ? 1 : -1) + pages.length) % pages.length])
      }
      else if (dy !== 0) focusIndex = panelPage === "buttons" ? 4 : panelPage === "pointer" ? 0 : 5
      return
    }
    if (panelPage === "buttons") {
      var direction = dx || dy
      if (direction !== 0) {
        var index = buttonList.findIndex(function (button) { return button.key === selectedButton })
        selectedButton = buttonList[(index + (direction > 0 ? 1 : -1) + buttonList.length) % buttonList.length].key
      }
      return
    }
    if (panelPage === "device") { stepFocus(dx || dy); return }
    if (dy !== 0) {
      if (dy > 0) {
        if (focusIndex <= 1) focusIndex = 2
        else if (focusIndex === 2) focusIndex = 3
        else if (focusIndex === 3) focusIndex = -1
        else focusIndex = 0
      } else {
        if (focusIndex === 0 || focusIndex === 1) focusIndex = -1
        else if (focusIndex === 2) focusIndex = 0
        else if (focusIndex === 3) focusIndex = 2
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

  function activateBluetoothProfile() {
    if (!root.model.lowLatencyHelperAvailable || root.model.lowLatencyBusy || root.model.lowLatencyState === "restart") return
    if (root.model.lowLatencyLegacy) root.model.runLowLatency("--remove-legacy")
    else if (root.model.lowLatencyCanRestore) root.model.revertLowLatency()
    else root.model.applyLowLatency()
  }

  function handleActivate() {
    cursorActive = true
    if (editingButton) return
    if (focusIndex === -2) { root.languageExpanded = !root.languageExpanded; return }
    if (focusIndex >= 10 && focusIndex < 10 + languageCodes.length) {
      root.model.setLocale(languageCodes[focusIndex - 10])
      root.languageExpanded = false
      root.focusIndex = -2
      return
    }
    if (focusIndex === -3) { root.model.reconnectDevice(); return }
    if (focusIndex === -4) {
      if (retrySettingsButton.visible && retrySettingsButton.enabled) root.model.retrySettings()
      return
    }
    if (focusIndex < 0) return
    if (panelPage === "buttons") { editButton(selectedButton); return }
    if (panelPage === "device") {
      if (focusIndex === 5) root.model.setAutoReconnect(!root.model.autoReconnect)
      else if (focusIndex === 6) root.activateBluetoothProfile()
      return
    }
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

  Flickable {
    id: viewport
    anchors.fill: parent
    anchors.rightMargin: Style.spacing.controlGap
    contentWidth: width
    contentHeight: root.contentHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick
    Controls.ScrollBar.vertical: Controls.ScrollBar {
      id: scrollBar
      parent: root
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.right: parent.right
      width: Style.space(3)
      policy: Controls.ScrollBar.AsNeeded
      contentItem: Rectangle {
        implicitWidth: Style.space(3)
        radius: width / 2
        color: root.dim
        opacity: scrollBar.active || scrollBar.hovered ? 0.6 : 0.2
      }
    }
  }

  Column {
    id: contentColumn
    parent: viewport.contentItem
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    spacing: Style.spacing.panelGap

    PanelHero {
      width: parent.width
      title: root.model.t("plugin_name")
      meta: root.model.connected ? root.model.transportText : root.model.t("disconnected")
      foreground: root.fgColor
      fontFamily: root.fontFam
      iconOpacity: root.model.connected ? 1 : 0.45
      iconComponent: Component {
        Item {
          implicitWidth: Style.font.display
          implicitHeight: implicitWidth
          Image {
            id: heroIcon
            anchors.fill: parent
            source: Qt.resolvedUrl("assets/trackball.svg")
            sourceSize.width: Math.ceil(width * 4)
            sourceSize.height: Math.ceil(height * 4)
            smooth: true
            mipmap: true
            visible: false
          }
          MultiEffect {
            anchors.fill: parent
            source: heroIcon
            colorization: 1
            colorizationColor: root.fgColor
          }
        }
      }
      trailingControl: Component {
        ActionButton {
          text: root.model.effectiveLanguage.toUpperCase()
          iconText: "文"
          iconSize: Style.font.bodySmall
          focusable: true
          Accessible.name: root.model.t("language_title")
          tooltipText: root.model.t("language_title") + (root.model.language === "system" ? " · " + root.model.t("lang_system") : "")
          fontSize: Style.font.caption
          foreground: root.fgColor
          fontFamily: root.fontFam
          bordered: true
          selected: root.languageExpanded
          hasCursor: root.cursorActive && root.focusIndex === -2
          onClicked: { root.focusIndex = -2; root.languageExpanded = !root.languageExpanded }
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
        spacing: Style.spacing.labelGap

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

          ActionButton {
            width: languageGrid.itemWidth
            text: modelData.label
            fontFamily: root.fontFam
            fontSize: Style.font.caption
            foreground: root.fgColor
            bordered: false
            focusable: true
            hasCursor: root.cursorActive && root.focusIndex === 10 + root.languageCodes.indexOf(modelData.code)
            selected: root.model.language === modelData.code
            active: root.model.language === modelData.code
            onClicked: {
              var code = modelData.code
              root.languageExpanded = false
              root.model.setLocale(code)
              root.focusIndex = -2
              root.forceActiveFocus()
            }
          }
        }
      }
    }

    Column {
      width: parent.width
      visible: root.model.configLoadFailed || root.model.configSaveFailed || root.model.settingsRecoveryFailed || root.model.sleepMonitorFailed
      spacing: Style.spacing.labelGap
      Repeater {
        model: [
          {show: root.model.configLoadFailed, key: "settings_load_error"},
          {show: root.model.configSaveFailed, key: "settings_save_error"},
          {show: root.model.settingsRecoveryFailed, key: "settings_apply_error"},
          {show: root.model.sleepMonitorFailed, key: "resume_monitor_error"}
        ]
        Text {
          required property var modelData
          visible: modelData.show
          width: parent.width
          text: root.model.t(modelData.key)
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          color: root.fgColor
          font.family: root.fontFam
          font.pixelSize: Style.font.caption
          Accessible.role: Accessible.StaticText
          Accessible.name: text
        }
      }
      ActionButton {
        id: retrySettingsButton
        visible: root.model.configSaveFailed || root.model.settingsRecoveryFailed
        enabled: !root.model.settingsApplying && !root.model.configWriting
        focusable: true
        hasCursor: root.cursorActive && root.focusIndex === -4
        text: root.model.t("settings_retry")
        foreground: root.fgColor
        fontFamily: root.fontFam
        fontSize: Style.font.caption
        onClicked: root.model.retrySettings()
      }
    }

    // Connect Trackball Button (visible when disconnected)
    ActionButton {
      id: connectButton
      enabled: root.model.canReconnect && !root.model.isConnecting
      hasCursor: root.cursorActive && root.focusIndex === -3
      Accessible.name: root.model.t("connect_device")
      visible: !root.model.connected && !root.editingButton
      width: parent.width
      text: root.model.isConnecting ? root.model.t("connecting") : ("󰂯 " + root.model.t("connect_device"))
      fontSize: Style.font.bodySmall
      foreground: root.fgColor
      fontFamily: root.fontFam
      bordered: true
      onClicked: root.model.reconnectDevice()
    }

    // ---------- Battery report ----------
    Column {
      visible: !root.editingButton
      width: parent.width
      spacing: Style.spacing.labelGap

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
          color: root.model.connected ? root.fgColor : root.dim
          font.family: root.fontFam
          font.pixelSize: Style.font.bodySmall
          font.bold: true
        }
      }

    Text {
      width: parent.width
      visible: root.model.connected
      text: root.model.batteryReportText
      textFormat: Text.PlainText
      wrapMode: Text.WordWrap
      color: root.dim
      font.family: root.fontFam
      font.pixelSize: Style.font.caption
    }
    }

    Row {
      id: pageTabs
      visible: !root.editingButton
      width: parent.width
      spacing: Style.spacing.controlGap
      ActionButton {
        width: (pageTabs.width - pageTabs.spacing * 2) / 3
        text: root.model.t("page_buttons")
        fontSize: Style.font.bodySmall
        fontFamily: root.fontFam
        foreground: root.fgColor
        bordered: true
        selected: root.panelPage === "buttons"
        hasCursor: root.cursorActive && root.focusIndex === -1 && selected
        onClicked: root.showPage("buttons")
      }
      ActionButton {
        width: (pageTabs.width - pageTabs.spacing * 2) / 3
        text: root.model.t("page_pointer")
        fontSize: Style.font.bodySmall
        fontFamily: root.fontFam
        foreground: root.fgColor
        bordered: true
        selected: root.panelPage === "pointer"
        hasCursor: root.cursorActive && root.focusIndex === -1 && selected
        onClicked: root.showPage("pointer")
      }
      ActionButton {
        width: (pageTabs.width - pageTabs.spacing * 2) / 3
        text: root.model.t("page_device")
        fontSize: Style.font.bodySmall
        fontFamily: root.fontFam
        foreground: root.fgColor
        bordered: true
        selected: root.panelPage === "device"
        hasCursor: root.cursorActive && root.focusIndex === -1 && selected
        onClicked: root.showPage("device")
      }
    }

    ActionButton {
      id: editorBackButton
      visible: root.editingButton
      text: "← " + root.model.t("back_to_buttons")
      fontSize: Style.font.bodySmall
      fontFamily: root.fontFam
      foreground: root.fgColor
      focusable: true
      onClicked: root.showPage("buttons")
    }

    Column {
      visible: root.panelPage === "pointer" && !root.editingButton
      width: parent.width
      spacing: Style.spacing.controlGap
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
        spacing: Style.spacing.controlGap

        readonly property real btnWidth: (width - spacing) / 2

        ActionButton {
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

        ActionButton {
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
        id: sensitivityColumn
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
            color: root.cursorActive && root.focusIndex === 2 ? root.fgColor : root.dim
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
          Accessible.role: Accessible.Slider
          Accessible.name: root.model.t("sensitivity")
          Accessible.description: root.model.sensitivity.toFixed(2)
          Accessible.onIncreaseAction: root.model.setSensitivity(root.model.sensitivity + 0.05)
          Accessible.onDecreaseAction: root.model.setSensitivity(root.model.sensitivity - 0.05)
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
        id: naturalRow
        Accessible.role: Accessible.CheckBox
        Accessible.name: root.model.t("natural_scroll")
        Accessible.checkable: true
        Accessible.checked: root.model.naturalScroll
        Accessible.onPressAction: root.model.setNaturalScroll(!root.model.naturalScroll)
        width: parent.width
        height: Math.max(Style.spacing.controlHeight, naturalLabel.implicitHeight + Style.space(12))
        implicitHeight: height

        Text {
          id: naturalLabel
          anchors.right: naturalSwitch.left
          anchors.rightMargin: Style.spacing.controlGap
          wrapMode: Text.Wrap
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

    }

    Column {
      visible: root.panelPage === "device" && !root.editingButton
      width: parent.width
      spacing: Style.spacing.controlGap
      // Auto-reconnect on Wake Toggle Row
      Item {
        id: autoReconnectRow
        Accessible.role: Accessible.CheckBox
        Accessible.name: root.model.t("auto_reconnect")
        Accessible.checkable: true
        Accessible.checked: root.model.autoReconnect
        Accessible.onPressAction: root.model.setAutoReconnect(!root.model.autoReconnect)
        width: parent.width
        height: Math.max(Style.spacing.controlHeight, autoRecLabel.implicitHeight + Style.space(12))
        implicitHeight: height

        Text {
          id: autoRecLabel
          anchors.right: autoRecSwitch.left
          anchors.rightMargin: Style.spacing.controlGap
          wrapMode: Text.Wrap
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
          hasCursor: root.cursorActive && root.focusIndex === 5
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

      // Controller-wide administrative action, separate from ordinary device controls.
      Column {
        id: latencyRow
        width: parent.width
        spacing: Style.spacing.controlGap
        Text {
          width: parent.width
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          text: root.model.t("polling_rate")
          color: root.fgColor
          font.family: root.fontFam
          font.pixelSize: Style.font.bodySmall
        }
        Text {
          width: parent.width
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          text: root.model.t("low_latency_hint")
          color: root.dim
          font.family: root.fontFam
          font.pixelSize: Style.font.caption
        }
        Text {
          width: parent.width
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          text: root.model.lowLatencyBusy ? root.model.t("latency_busy") : root.model.t("latency_" + root.model.lowLatencyState)
          color: root.fgColor
          font.family: root.fontFam
          font.pixelSize: Style.font.caption
        }
        Text {
          visible: root.model.lowLatencyFailed
          width: parent.width
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          text: root.model.t("latency_error")
          color: root.fgColor
          font.family: root.fontFam
          font.pixelSize: Style.font.caption
        }
        Text {
          visible: !root.model.lowLatencyHelperAvailable
          width: parent.width
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          text: root.model.t("latency_setup")
          color: root.dim
          font.family: root.fontFam
          font.pixelSize: Style.font.caption
        }
        ActionButton {
          id: profileAction
          width: parent.width
          readonly property string actionLabel: root.model.t(root.model.lowLatencyLegacy ? "latency_cleanup" : root.model.lowLatencyCanRestore ? "latency_restore" : "latency_enable")
          implicitHeight: Math.max(Style.spacing.controlHeight, profileActionLabel.implicitHeight + verticalPadding * 2 + Style.normalBorderWidth * 2)
          Accessible.name: actionLabel
          enabled: root.model.lowLatencyHelperAvailable && !root.model.lowLatencyBusy
            && root.model.lowLatencyState !== "restart"
            && (root.model.lowLatencyCanRestore || root.model.lowLatencyLegacy || root.model.bluetoothAdapter !== "")
          hasCursor: root.cursorActive && root.focusIndex === 6
          foreground: root.fgColor
          fontFamily: root.fontFam
          fontSize: Style.font.bodySmall
          bordered: true
          onClicked: root.activateBluetoothProfile()
          Text {
            id: profileActionLabel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: profileAction.horizontalPadding + Style.normalBorderWidth
            anchors.verticalCenter: parent.verticalCenter
            text: profileAction.actionLabel
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            font.family: root.fontFam
            font.pixelSize: Style.font.bodySmall
            color: root.fgColor
          }
        }
      }

    }

    Column {
      visible: root.panelPage === "buttons"
      width: parent.width
      spacing: Style.spacing.controlGap
      // The diagram and editor occupy the same space, never stack vertically.

      TrackballMap {
        id: btnSelectorRow
        visible: !root.editingButton
        width: parent.width
        height: implicitHeight
        foreground: root.fgColor
        background: Color.popups.background
        accent: root.bar && root.bar.accent !== undefined ? root.bar.accent : Color.accent
        fontFamily: root.fontFam
        labelSize: Style.font.bodySmall
        actionSize: Style.font.caption
        gap: Style.spacing.labelGap
        padding: Style.space(6)
        borderWidth: Style.normalBorderWidth
        cornerRadius: Style.cornerRadius
        selectedButton: root.selectedButton
        hasCursor: root.cursorActive && root.focusIndex === 4
        buttons: root.buttonList.map(function (button) {
          return { key: button.key, label: root.model.t(button.key === "back" ? "button_back_short" : button.key === "forward" ? "button_forward_short" : button.labelKey),
            action: root.model.actionLabel(root.model.getButtonAction(button.key), button.key) }
        })
        onSelectionRequested: function (buttonKey) {
          root.editButton(buttonKey)
        }
      }

      // Active Button Card
      Rectangle {
        visible: root.editingButton
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
          spacing: Style.spacing.controlGap

          Column {
            width: parent.width
            spacing: Style.spacing.labelGap
            Row {
              width: parent.width
              spacing: Style.spacing.controlGap
              Text {
                width: Math.max(0, parent.width - resetButton.width - parent.spacing)
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                text: root.selectedButtonLabel()
                color: root.dim
                font.family: root.fontFam
                font.pixelSize: Style.font.caption
                wrapMode: Text.Wrap
              }
              ActionButton {
                focusable: true
                id: resetButton
                text: "↺ " + root.model.t("btn_reset_default")
                fontSize: Style.font.caption
                foreground: root.fgColor
                fontFamily: root.fontFam
                bordered: true
                onClicked: {
                  root.model.resetButtonToDefault(root.selectedButton)
                  root.finishButtonEdit()
                }
              }
            }
            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: root.model.actionLabel(root.model.getButtonAction(root.selectedButton), root.selectedButton)
              color: root.fgColor
              font.family: root.fontFam
              font.pixelSize: Style.font.bodySmall
              font.bold: true
              wrapMode: Text.Wrap
            }
          }

          // Mode Switcher (Presets | Record Shortcut | Command)
          Row {
            width: parent.width
            spacing: Style.space(6)

            readonly property real modeBtnWidth: (width - spacing * 2) / 3

            ActionButton {
                focusable: true
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

            ActionButton {
                focusable: true
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

            ActionButton {
                focusable: true
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
                  color: root.dim
                  font.family: root.fontFam
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }

                Flow {
                  width: parent.width
                  spacing: Style.spacing.labelGap

                  Repeater {
                    model: modelData.items

                    delegate: ActionButton {
                focusable: true
                      id: presetButton
                      required property var modelData
                      width: Math.min(implicitWidth, parent.width)
                      implicitWidth: presetLabel.implicitWidth + horizontalPadding * 2 + Style.normalBorderWidth * 2
                      implicitHeight: Math.max(Style.spacing.controlHeight, presetLabel.implicitHeight + verticalPadding * 2 + Style.normalBorderWidth * 2)
                      foreground: root.fgColor
                      fontFamily: root.fontFam
                      fontSize: Style.font.caption
                      selected: root.model.getButtonAction(root.selectedButton) === modelData.id
                      bordered: true
                      Accessible.name: modelData.label
                      onClicked: {
                        root.model.setButtonAction(root.selectedButton, modelData.id)
                        root.finishButtonEdit()
                      }
                      Text {
                        id: presetLabel
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: presetButton.horizontalPadding + Style.normalBorderWidth
                        anchors.verticalCenter: parent.verticalCenter
                        textFormat: Text.PlainText
                        text: presetButton.modelData.label
                        color: presetButton.selected ? Style.selectedStateColor(root.fgColor, presetButton.accent) : root.fgColor
                        font.family: root.fontFam
                        font.pixelSize: presetButton.fontSize
                        font.bold: presetButton.selected
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
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
            Column {
              width: parent.width
              spacing: Style.spacing.labelGap

              TextField {
                id: shortcutInput
                maximumLength: 256
                font.family: root.fontFam
                width: parent.width
                font.pixelSize: Style.font.bodySmall
                placeholderText: root.model.t("shortcut_input_placeholder")
                text: root.model.getCustomShortcut(root.selectedButton)
                Keys.onTabPressed: function(event) {
                  if (root.isRecording) event.accepted = false
                  else { root.stepFocus(1); event.accepted = true }
                }
                Keys.onBacktabPressed: function(event) {
                  if (root.isRecording) event.accepted = false
                  else { root.stepFocus(-1); event.accepted = true }
                }
                onAccepted: {
                  root.model.setCustomShortcut(root.selectedButton, text)
                  root.finishButtonEdit()
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
                    root.isRecording = false
                    event.accepted = true
                  }
                }
              }

              Row {
                width: parent.width
                spacing: Style.spacing.controlGap
              ActionButton {
                focusable: true
                id: btnClear
                text: root.model.t("btn_clear")
                fontSize: Style.font.caption
                foreground: root.fgColor
                fontFamily: root.fontFam
                bordered: true
                onClicked: {
                  shortcutInput.text = ""
                }
              }

              ActionButton {
                focusable: true
                id: btnApply
                text: root.model.t("btn_apply")
                fontSize: Style.font.caption
                foreground: root.fgColor
                fontFamily: root.fontFam
                bordered: true
                onClicked: {
                  root.model.setCustomShortcut(root.selectedButton, shortcutInput.text.trim())
                  root.finishButtonEdit()
                }
              }
            }
            }

            ActionButton {
              width: parent.width
              focusable: true
              text: root.model.t(root.isRecording ? "recording_active" : "btn_record")
              fontSize: Style.font.bodySmall
              fontFamily: root.fontFam
              foreground: root.fgColor
              bordered: true
              selected: root.isRecording
              onClicked: {
                root.isRecording = !root.isRecording
                if (root.isRecording) shortcutInput.forceActiveFocus()
              }
            }

            // Row 1: Quick Modifier Chips (SUPER, CTRL, ALT, SHIFT)
            Row {
              id: modChipsRow
              width: parent.width
              spacing: Style.spacing.labelGap

              readonly property real modWidth: (width - spacing * 3) / 4

              Repeater {
                model: ["SUPER", "CTRL", "ALT", "SHIFT"]
                delegate: ActionButton {
                  required property string modelData
                  focusable: true
                  width: modChipsRow.modWidth
                  text: "+ " + modelData
                  fontSize: Style.font.caption
                  fontFamily: root.fontFam
                  foreground: root.fgColor
                  bordered: true
                  onClicked: root.addTokenToShortcut(modelData)
                }
              }
            }

            // Row 2: System & Navigation Chips (Insert, Delete, Home, End, PgUp, PgDn...)
            Flow {
              width: parent.width
              spacing: Style.spacing.labelGap

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
                delegate: ActionButton {
                  required property var modelData
                  focusable: true

                  text: modelData.label
                  fontSize: Style.font.caption
                  fontFamily: root.fontFam
                  foreground: root.fgColor
                  bordered: true
                  onClicked: root.addTokenToShortcut(modelData.id)
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
                delegate: ActionButton {
                  required property string modelData
                  focusable: true
                  width: digitChipsRow.digitWidth
                  text: modelData
                  fontSize: Style.font.caption
                  fontFamily: root.fontFam
                  foreground: root.fgColor
                  bordered: true
                  onClicked: root.addTokenToShortcut(modelData)
                }
              }
            }

            // Row 4: Function Keys Toggle + Extra System Keys
            Row {
              width: parent.width
              spacing: Style.spacing.labelGap

              ActionButton {
                focusable: true
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
                delegate: ActionButton {
                  required property string modelData
                  focusable: true

                  text: modelData
                  fontSize: Style.font.caption
                  fontFamily: root.fontFam
                  foreground: root.fgColor
                  bordered: true
                  onClicked: root.addTokenToShortcut(modelData)
                }
              }
            }

            // Expandable F1-F12 Grid
            Grid {
              visible: root.fKeysExpanded
              width: parent.width
              columns: 6
              spacing: Style.space(3)

              id: functionKeyGrid
              readonly property real fKeyWidth: (width - spacing * 5) / 6

              Repeater {
                model: ["F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"]
                delegate: ActionButton {
                  required property string modelData
                  focusable: true
                  width: functionKeyGrid.fKeyWidth
                  text: modelData
                  fontSize: Style.font.caption
                  fontFamily: root.fontFam
                  foreground: root.fgColor
                  bordered: true
                  onClicked: root.addTokenToShortcut(modelData)
                }
              }
            }


          }

          // Mode 3: Direct Shell Command
          Column {
            visible: root.setupMode === "command"
            width: parent.width
            spacing: Style.spacing.labelGap

            TextField {
              id: cmdField
              maximumLength: 2048
              font.family: root.fontFam
              width: parent.width
              font.pixelSize: Style.font.bodySmall
              placeholderText: root.model.t("custom_shortcut_placeholder")
              text: root.model.getCustomCommand(root.selectedButton)
              Keys.onTabPressed: root.stepFocus(1)
              Keys.onBacktabPressed: root.stepFocus(-1)
              onAccepted: {
                root.model.setCustomCommand(root.selectedButton, text)
                root.finishButtonEdit()
              }
              Binding {
                target: cmdField
                property: "text"
                value: root.model.getCustomCommand(root.selectedButton)
              }
            }
            ActionButton {
                focusable: true
              text: root.model.t("btn_apply")
              fontSize: Style.font.bodySmall
              fontFamily: root.fontFam
              foreground: root.fgColor
              bordered: true
              onClicked: {
                root.model.setCustomCommand(root.selectedButton, cmdField.text)
                root.finishButtonEdit()
              }
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
