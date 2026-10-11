import QtQuick
import QtTest
import qs.Commons
import "../.." as Plugin
import "../../I18n.js" as I18n

// Render the real consumer panel with inert model operations. This exercises
// selection -> in-place editor -> assignment, without changing live settings.
TestCase {
  id: testCase
  name: "ButtonEditor"
  when: windowShown
  visible: true
  width: 780
  height: 800
  property real availableWidth: 1000
  property string chosen: ""
  property string chosenButton: ""

  QtObject {
    id: bar
    property color foreground: Color.foreground
    property color accent: Color.accent
    property string fontFamily: Style.font.family
  }
  QtObject {
    id: model
    property bool configReadComplete: true
    property bool configLoadFailed: false
    property bool configSaveFailed: false
    property bool configWriting: false
    property bool configPending: false
    property bool configStored: true
    property bool settingsPending: false
    property bool settingsVerified: true
    property int retries: 0
    property bool connected: true
    property bool isConnecting: false
    property bool settingsApplying: false
    property bool settingsRecoveryFailed: false
    property bool sleepMonitorFailed: false
    property bool profileBusy: false
    property bool rejectProfile: false
    property string profileRetryId: ""
    property string profileError: ""
    property string profileShortcut: ""
    property string activeProfileId: "main"
    property string activeProfileName: "Основной"
    property var buttonProfiles: [{id: "main", name: "Основной"}, {id: "work", name: "Работа"}]
    property string language: "ru"
    property string effectiveLanguage: "ru"
    property string connectionStatusText: "Bluetooth BLE"
    readonly property string batteryLevelText: t("battery_normal")
    property string batteryReportText: ""
    property string batterySourceDifference: ""
    property string batteryIcon: ""
    property var btDevice: ({address: "00:00:00:00:00:00", name: "MX Ergo", connected: true})
    property var bluetoothAdapter: ({})
    property bool canRecover: false
    property bool canStartRecovery: false
    property bool recoveryBusy: false
    property bool recoveryStopping: false
    property string recoveryStage: ""
    property string recoveryResult: ""
    property string recoveryOtherNote: ""
    property string recoveryScanNote: ""
    property int cancellations: 0
    property int recoveries: 0
    function cancelRecovery() { cancellations++ }
    function recoverDevice() { recoveries++; return true }
    property bool lowLatencyBusy: false
    property bool lowLatencyCanRestore: false
    property bool lowLatencyFailed: false
    property bool lowLatencyHelperAvailable: false
    property int adapterChanges: 0
    function applyLowLatency() { adapterChanges++ }
    property bool lowLatencyLegacy: false
    property string lowLatencyState: "off"
    property string accelProfile: "adaptive"
    property bool autoReconnect: true
    property bool naturalScroll: false
    property real sensitivity: 0
    property var actions: ({back: "workspace_next", forward: "default", middle: "default", tiltLeft: "default", tiltRight: "default"})
    function selectProfile(id) {
      if (profileBusy || rejectProfile || id === activeProfileId) return false
      activeProfileId = id
      activeProfileName = id === "main" ? "Основной" : "Работа"
      return true
    }
    function t(key) { return I18n.t(key, effectiveLanguage) }
    function getButtonAction(key) { return actions[key] }
    property var shortcuts: ({back: "CTRL + F2"})
    property var commands: ({})
    function getCustomShortcut(key) { return shortcuts[key] || "" }
    function getCustomCommand(key) { return commands[key] || "" }
    function actionLabel(action, key) {
      return action === "custom_shortcut" ? getCustomShortcut(key) || t("tab_shortcut")
        : action === "custom_command" ? getCustomCommand(key) || t("tab_command") : t("action_" + action)
    }
    function setCustomShortcut(key, value) {
      var next = Object.assign({}, shortcuts); next[key] = value.trim(); shortcuts = next
      setButtonAction(key, "custom_shortcut")
    }
    function setCustomCommand(key, value) {
      var next = Object.assign({}, commands); next[key] = value.trim(); commands = next
      setButtonAction(key, "custom_command")
    }
    function retrySettings() {
      retries++
      settingsRecoveryFailed = false
      settingsPending = true
    }
    function setButtonAction(key, action) {
      settingsPending = true
      configPending = true
      settingsVerified = false
      testCase.chosen = action
      testCase.chosenButton = key
      var next = Object.assign({}, actions); next[key] = action; actions = next
    }
    function resetButtonToDefault(key) { setButtonAction(key, "default") }
    function setAccelProfile(value) { accelProfile = value }
    function setSensitivity(value) { sensitivity = value }
    function setNaturalScroll(value) { naturalScroll = value }
    function setAutoReconnect(value) { autoReconnect = value }
    function setProfileSwitchForAll(key) { setButtonAction(key, "profile_next") }
  }

  Rectangle {
    id: surface
    width: Math.min(editor.preferredWidth, testCase.availableWidth) - editor.panelInset
    height: editor.height
    color: Color.popups.background
    Plugin.ErgoPanel {
      id: editor
      objectName: "consumerEditor"
      width: surface.width
      height: Math.min(contentHeight, testCase.height)
      bar: bar
      model: model
    }
  }

  function init() {
    testCase.height = 800
    testCase.availableWidth = 1000
    model.effectiveLanguage = "ru"
    model.language = "ru"
    model.canRecover = false
    model.canStartRecovery = false
    model.isConnecting = false
    model.recoveries = 0
    model.recoveryBusy = false
    model.recoveryStage = ""
    model.recoveryResult = ""
    model.cancellations = 0
    model.batteryReportText = ""
    model.batterySourceDifference = ""
    model.accelProfile = "adaptive"
    model.naturalScroll = false
    model.sensitivity = 0
    model.autoReconnect = true
    model.configPending = false
    model.configStored = true
    model.settingsPending = false
    model.settingsVerified = true
    model.configLoadFailed = false
    model.configSaveFailed = false
    model.settingsRecoveryFailed = false
    model.retries = 0
    model.shortcuts = {back: "CTRL + F2"}
    model.commands = {}
    model.actions = {back: "workspace_next", forward: "default", middle: "default", tiltLeft: "default", tiltRight: "default"}
    model.profileBusy = false
    model.rejectProfile = false
    model.activeProfileId = "main"
    model.activeProfileName = "Основной"
    chosen = ""
    chosenButton = ""
    editor.showPage("buttons")
    editor.fKeysExpanded = false
    editor.advancedExpanded = false
    model.lowLatencyBusy = false
    model.lowLatencyFailed = false
    model.lowLatencyHelperAvailable = false
    model.adapterChanges = 0
    wait(30)
  }

  function test_category_navigation_and_commit() {
    editor.editButton("back")
    wait(30)
    var picker = findChild(editor, "actionCategory")
    verify(picker !== null && picker.visible)
    compare(picker.value, "0", "opening matches the current action's category")
    picker.open()
    wait(20)
    verify(editor.blocked, "category popup owns keyboard navigation")
    keyClick(Qt.Key_Down)
    keyClick(Qt.Key_Return)
    wait(20)
    compare(picker.value, "1")
    compare(chosen, "", "browsing categories does not assign an action")
    var action = findChild(editor, "action_window_close")
    verify(action.visible)
    mouseClick(action, action.width / 2, action.height / 2)
    wait(20)
    compare(chosen, "window_close")
    compare(chosenButton, "back")
    verify(editor.editingButton, "save keeps the editor and overview together")
    verify(findChild(editor, "trackballIllustration").visible)
  }

  function test_reopening_restores_saved_action_category() {
    editor.editButton("back")
    wait(30)
    var picker = findChild(editor, "actionCategory")
    compare(picker.value, "0")
    picker.open()
    keyClick(Qt.Key_Down)
    keyClick(Qt.Key_Return)
    wait(20)
    compare(picker.value, "1")
    compare(chosen, "", "category navigation does not write")
    editor.closeButtonEdit()
    editor.editButton("back")
    wait(30)
    compare(picker.value, "0", "reopening the same button restores the saved category")
    var action = findChild(editor, "action_workspace_next")
    verify(action.visible && action.selected, "the current action is visible and selected")
    compare(chosen, "", "reopening does not change the assignment")
  }

  function test_profile_context_full_width_and_bounded_height() {
    model.canRecover = true
    wait(30)
    var image = findChild(editor, "trackballIllustration")
    var profiles = findChild(editor, "buttonProfiles")
    compare(image.width, (380 - Style.spacing.controlGap) * 0.7, "original illustration scale")
    verify(profiles.mapToItem(editor, 0, profiles.height).y <= image.mapToItem(editor, 0, 0).y,
      "profile controls precede the full mouse illustration")
    verify(editor.contentHeight <= 650, "normal overview fits the current logical screen without shrinking the mouse")
    verify(!findChild(editor, "profileShortcut").visible)
    verify(findChild(editor, "deviceRecovery").visible, "recovery is available without visiting Device")
    ;["back", "forward", "middle", "tiltLeft", "tiltRight"].forEach(function(key) {
      verify(findChild(editor, "callout_" + key).visible, "physical control remains reachable: " + key)
    })
    var callout = findChild(editor, "callout_forward")
    mouseClick(callout, callout.width / 2, callout.height / 2)
    verify(editor.editingButton)
    compare(editor.selectedButton, "forward")
    keyClick(Qt.Key_Escape)
    verify(image.visible, "editor returns to the mouse")
    editor.showPage("device")
    wait(20)
    verify(findChild(editor, "deviceRecovery").visible, "manual recovery remains accessible")
    model.canRecover = false
  }

  function test_keyboard_action_and_escape() {
    editor.editButton("middle")
    wait(20)
    var action = findChild(editor, "action_profile_next")
    action.forceActiveFocus()
    keyClick(Qt.Key_Return)
    compare(chosen, "profile_next")
    editor.editButton("middle")
    wait(20)
    verify(findChild(editor, "profileSwitchAll").visible)
    keyClick(Qt.Key_Escape)
    verify(!editor.editingButton)
  }

  function test_all_actions_data() {
    var groups = [["workspace_next", "workspace_prev"], ["window_close", "window_float", "window_fullscreen", "window_next"],
      ["media_play_pause", "mute", "media_next", "media_prev"], ["tab_next", "tab_prev", "browser_back", "browser_forward"],
      ["overview", "screenshot", "profile_next", "default"]]
    var rows = []
    groups.forEach(function(group, category) { group.forEach(function(action) { rows.push({tag: action, action: action, category: category}) }) })
    return rows
  }

  function test_all_actions(data) {
    model.actions = Object.assign({}, model.actions, {back: data.action})
    editor.editButton("back")
    wait(20)
    compare(findChild(editor, "actionCategory").value, String(data.category))
    var item = findChild(editor, "action_" + data.action)
    verify(item.visible && item.selected)
    mouseClick(item, item.width / 2, item.height / 2)
    compare(chosen, data.action)
    verify(editor.editingButton)
  }

  function test_editor_keeps_context_and_geometry() {
    var image = findChild(editor, "trackballIllustration")
    var profiles = findChild(editor, "buttonProfiles")
    var overview = findChild(editor, "overviewViewport")
    var beforeWidth = image.width
    var beforeHeight = editor.height
    var beforeY = image.mapToItem(editor, 0, 0).y
    var beforeProfileY = profiles.mapToItem(editor, 0, 0).y
    editor.editButton("back")
    wait(30)
    verify(image.visible && profiles.visible)
    compare(image.width, beforeWidth, "editing does not shrink the mouse")
    compare(image.mapToItem(editor, 0, 0).y, beforeY)
    compare(profiles.mapToItem(editor, 0, 0).y, beforeProfileY)
    compare(editor.height, beforeHeight, "editor does not add popup height")
    var assignments = findChild(editor, "assignmentViewport")
    verify(assignments.x >= overview.width, "editor is beside the mouse")
    editor.setupMode = "shortcut"
    wait(20)
    var field = findChild(editor, "assignmentShortcut")
    field.text = "ALT + F4"
    assignments.contentY = 40
    var callout = findChild(editor, "callout_forward")
    mouseClick(callout, callout.width / 2, callout.height / 2)
    wait(20)
    compare(editor.selectedButton, "forward")
    compare(field.text, "", "switching controls discards an unapplied draft")
    compare(chosen, "", "selection never saves the discarded draft")
    compare(assignments.contentY, 0)
    compare(overview.contentY, 0)
    mouseClick(findChild(editor, "closeAssignment"))
    verify(!editor.editingButton)
    compare(editor.focusIndex, 4)
    compare(image.width, beforeWidth)
  }

  function test_profile_change_closes_draft() {
    editor.editButton("back")
    editor.isRecording = true
    model.activeProfileId = "other"
    wait(20)
    verify(!editor.editingButton)
    verify(!editor.isRecording)
    compare(chosen, "")
    model.activeProfileId = "main"
  }

  function test_host_insets_preserve_mouse_width() {
    editor.panelInset = 32
    wait(20)
    var image = findChild(editor, "trackballIllustration")
    var beforeWidth = image.width
    editor.editButton("middle")
    wait(20)
    compare(image.width, beforeWidth, "host padding cannot enlarge or shrink the mouse on opening")
    compare(image.width, (380 - 32 - Style.spacing.controlGap) * 0.7)
    editor.closeButtonEdit()
    editor.panelInset = 0
  }

  function test_profile_selector_precedes_assignments() {
    var profiles = findChild(editor, "buttonProfiles")
    var firstCallout = findChild(editor, "callout_middle")
    verify(profiles.mapToItem(editor, 0, profiles.height).y <= firstCallout.mapToItem(editor, 0, 0).y,
      "choose the profile before looking through physical assignments")
    editor.editButton("back")
    editor.setupMode = "shortcut"
    var field = findChild(editor, "assignmentShortcut")
    field.text = "ALT + F4"
    var picker = findChild(editor, "profilePicker")
    picker.open()
    wait(20)
    verify(editor.blocked, "profile selection owns keyboard input even during editing")
    keyClick(Qt.Key_Down)
    keyClick(Qt.Key_Return)
    wait(30)
    compare(model.activeProfileId, "work")
    compare(picker.value, "work")
    verify(!editor.editingButton)
    compare(chosen, "", "changing profiles never saves the previous draft")
    editor.editButton("back")
    compare(field.text, "CTRL + F2", "opening loads saved data instead of the discarded draft")
  }

  function test_rejected_profile_switch_retains_context() {
    editor.editButton("back")
    editor.setupMode = "shortcut"
    var field = findChild(editor, "assignmentShortcut")
    field.text = "ALT + F4"
    model.rejectProfile = true
    var picker = findChild(editor, "profilePicker")
    picker.open()
    wait(20)
    keyClick(Qt.Key_Down)
    keyClick(Qt.Key_Return)
    wait(20)
    compare(model.activeProfileId, "main")
    compare(picker.value, "main")
    verify(editor.editingButton, "a rejected switch must not pretend to change the editing profile")
    compare(field.text, "ALT + F4")
    compare(chosen, "")
    model.profileBusy = true
    verify(!picker.enabled, "cannot select another profile while applying")
  }

  function test_assignment_draft_and_apply() {
    editor.editButton("back")
    compare(findChild(editor, "assignmentValue").text, model.t("action_workspace_next"))
    compare(editor.assignmentStatusKey, "assignment_done")
    compare(findChild(editor, "assignmentHint").text, model.t("assignment_preset_hint"))
    editor.setupMode = "shortcut"
    verify(!editor.assignmentDraft, "mode browsing is not a write or a text change")
    var input = findChild(editor, "assignmentShortcut")
    input.text = "ALT + F4"
    verify(editor.assignmentDraft)
    compare(findChild(editor, "assignmentHint").text, model.t("assignment_draft_hint"))
    compare(chosen, "", "typing never writes")
    wait(30)
    var apply = findChild(editor, "assignmentShortcutApply")
    mouseClick(apply, apply.width / 2, apply.height / 2)
    wait(20)
    compare(chosen, "custom_shortcut")
    compare(model.getCustomShortcut("back"), "ALT + F4")
    compare(findChild(editor, "assignmentValue").text, "ALT + F4")
    verify(!editor.assignmentDraft)
    compare(findChild(editor, "assignmentHint").text, model.t("assignment_edit_hint"))
    verify(editor.editingButton)
    compare(editor.assignmentStatusKey, "assignment_applying")
    model.settingsPending = false
    model.settingsVerified = true
    compare(editor.assignmentStatusKey, "assignment_saving", "verified application alone is not saved")
    model.configPending = false
    model.configStored = false
    compare(editor.assignmentStatusKey, "assignment_unverified", "missing storage receipt cannot show saved")
    model.configStored = true
    compare(editor.assignmentStatusKey, "assignment_done")
    input.text = ""
    verify(editor.assignmentDraft, "clearing remains a draft")
    compare(model.getCustomShortcut("back"), "ALT + F4")
    editor.closeButtonEdit()
    editor.editButton("back")
    compare(input.text, "ALT + F4", "reopening discards the cleared draft")
  }

  function test_assignment_errors_and_retry() {
    editor.editButton("back")
    var status = findChild(editor, "assignmentStatus")
    var retry = findChild(editor, "assignmentRetry")
    model.settingsRecoveryFailed = true
    model.settingsVerified = false
    compare(status.text, model.t("assignment_apply_error"))
    verify(retry.visible && retry.enabled)
    wait(30)
    mouseClick(retry, retry.width / 2, retry.height / 2)
    compare(model.retries, 1)
    compare(editor.assignmentStatusKey, "assignment_applying")
    verify(!retry.enabled)
    model.settingsPending = false
    model.settingsVerified = true
    model.configSaveFailed = true
    model.configStored = false
    compare(status.text, model.t("settings_save_error"))
    verify(retry.visible && retry.enabled)
    model.configPending = true
    compare(editor.assignmentStatusKey, "assignment_saving")
    verify(!retry.enabled)
    model.configPending = false
    model.configSaveFailed = false
    model.configStored = true
    compare(editor.assignmentStatusKey, "assignment_done")
    model.configLoadFailed = true
    compare(status.text, model.t("settings_load_error"))
    model.configLoadFailed = false
    model.settingsVerified = false
    compare(editor.assignmentStatusKey, "assignment_unverified")
  }

  function test_command_apply_and_enter() {
    editor.editButton("forward")
    editor.setupMode = "command"
    var input = findChild(editor, "assignmentCommand")
    input.text = "printf '<value>'"
    verify(editor.assignmentDraft)
    compare(chosen, "")
    input.forceActiveFocus()
    keyClick(Qt.Key_Return)
    wait(20)
    compare(chosen, "custom_command")
    compare(model.getCustomCommand("forward"), "printf '<value>'")
    compare(findChild(editor, "assignmentValue").text, "printf '<value>'", "command is plain text")
    verify(!editor.assignmentDraft)
    input.text = "printf 'next'"
    var apply = findChild(editor, "assignmentCommandApply")
    mouseClick(apply, apply.width / 2, apply.height / 2)
    compare(model.getCustomCommand("forward"), "printf 'next'")
    verify(editor.editingButton)
    verify(!editor.assignmentDraft)
  }

  function test_feedback_locales_data() {
    return ["en", "ru", "de", "fr", "es", "it", "pt", "zh", "ja", "ko"].map(function(locale) {
      return {tag: locale, locale: locale}
    })
  }
  function test_feedback_locales(data) {
    model.effectiveLanguage = data.locale
    wait(30)
    var beforeHeight = editor.height
    editor.editButton("back")
    editor.setupMode = "command"
    var input = findChild(editor, "assignmentCommand")
    input.text = "printf '<literal>'"
    model.settingsRecoveryFailed = true
    model.settingsVerified = false
    wait(30)
    var status = findChild(editor, "assignmentStatus")
    var hint = findChild(editor, "assignmentHint")
    verify(editor.assignmentDraft)
    verify(status.visible && hint.visible)
    verify(status.height >= status.implicitHeight && hint.height >= hint.implicitHeight)
    compare(status.textFormat, Text.PlainText)
    compare(hint.textFormat, Text.PlainText)
    compare(editor.height, beforeHeight, "feedback keeps the overview height")
    verify(editor.height <= 650)
    verify(findChild(editor, "assignmentRetry").enabled)
  }

  function test_selected_control_toggles_editor() {
    var callout = findChild(editor, "callout_back")
    mouseClick(callout, callout.width / 2, callout.height / 2)
    verify(editor.editingButton)
    editor.setupMode = "shortcut"
    findChild(editor, "assignmentShortcut").text = "ALT + F4"
    wait(30)
    mouseClick(callout, callout.width / 2, callout.height / 2)
    verify(!editor.editingButton, "repeat selected callout dismisses")
    compare(chosen, "")
    compare(editor.focusIndex, 4)
    var hotspot = findChild(editor, "hotspot_back")
    mouseClick(hotspot, hotspot.width / 2, hotspot.height / 2)
    verify(editor.editingButton)
    compare(findChild(editor, "assignmentShortcut").text, "CTRL + F2", "dismissed draft is not saved")
    wait(30)
    mouseClick(hotspot, hotspot.width / 2, hotspot.height / 2)
    verify(!editor.editingButton, "repeat selected physical hotspot dismisses")
    mouseClick(callout, callout.width / 2, callout.height / 2)
    wait(30)
    var other = findChild(editor, "callout_forward")
    mouseClick(other, other.width / 2, other.height / 2)
    verify(editor.editingButton, "different button switches the editor")
    compare(editor.selectedButton, "forward")
  }

  function test_background_click_dismisses_only_editor() {
    var overview = findChild(editor, "overviewViewport")
    var image = findChild(editor, "trackballIllustration")
    var beforeWidth = image.width
    editor.editButton("back")
    editor.setupMode = "command"
    findChild(editor, "assignmentCommand").text = "unapplied command"
    wait(30)
    var assignments = findChild(editor, "assignmentViewport")
    verify(assignments.contentHeight < assignments.height, "fixture has unused editor background")
    var point = assignments.mapToItem(editor, assignments.width / 2, assignments.height - 12)
    mouseClick(editor, point.x, point.y, Qt.RightButton)
    verify(editor.editingButton, "secondary click is not dismissal")
    editor.isRecording = true
    mouseClick(editor, point.x, point.y)
    verify(!editor.editingButton, "blank primary click dismisses")
    verify(!editor.isRecording)
    compare(editor.panelPage, "buttons")
    compare(chosen, "")
    compare(overview.contentY, 0)
    compare(image.width, beforeWidth)
    editor.editButton("back")
    compare(findChild(editor, "assignmentCommand").text, "")
    wait(30)
    // The gutter between columns is also unused background.
    mouseClick(editor, overview.width + Style.spacing.controlGap + 8, editor.height - 16)
    verify(!editor.editingButton)
  }

  function test_editor_content_and_popup_are_protected() {
    editor.editButton("back")
    wait(30)
    var value = findChild(editor, "assignmentValue")
    mouseClick(value, value.width / 2, value.height / 2)
    verify(editor.editingButton, "assignment text is protected content")
    var action = findChild(editor, "action_workspace_prev")
    mouseClick(action, action.width / 2, action.height / 2)
    compare(chosen, "workspace_prev")
    verify(editor.editingButton, "choosing an action does not dismiss")
    editor.setupMode = "shortcut"
    wait(30)
    var input = findChild(editor, "assignmentShortcut")
    mouseClick(input, input.width / 2, input.height / 2)
    input.text = "CTRL + F2"
    input.selectAll()
    keyClick(Qt.Key_F4)
    verify(editor.editingButton, "editing and selecting text are protected")
    editor.setupMode = "presets"
    wait(30)
    var picker = findChild(editor, "actionCategory")
    picker.open()
    wait(30)
    var assignments = findChild(editor, "assignmentViewport")
    var point = assignments.mapToItem(editor, assignments.width / 2, assignments.height - 12)
    mousePress(editor, point.x, point.y)
    wait(100)
    mouseRelease(editor, point.x, point.y)
    verify(editor.editingButton, "first outside click belongs to the nested popup even after a held press")
    verify(!picker.popupOpen)
    wait(30)
    mouseClick(editor, point.x, point.y)
    verify(!editor.editingButton, "second click can dismiss the editor")
    editor.editButton("back")
    wait(30)
    picker.open()
    wait(30)
    keyClick(Qt.Key_Escape)
    wait(30)
    mouseClick(editor, point.x, point.y)
    verify(!editor.editingButton, "keyboard popup closure leaves no stale pointer guard")
    editor.editButton("back")
    var profiles = findChild(editor, "profilePicker")
    profiles.open()
    wait(30)
    mouseClick(editor, point.x, point.y)
    verify(editor.editingButton, "profile menu also owns its first outside click")
    verify(!profiles.popupOpen)
    wait(30)
    mouseClick(editor, point.x, point.y)
    verify(!editor.editingButton)
  }

  function test_background_drag_does_not_dismiss() {
    editor.editButton("back")
    wait(30)
    var assignments = findChild(editor, "assignmentViewport")
    var point = assignments.mapToItem(editor, assignments.width / 2, assignments.height - 12)
    mouseDrag(editor, point.x, point.y, 0, -100)
    verify(editor.editingButton, "a scroll gesture is not a background click")
    var overview = findChild(editor, "overviewViewport")
    mouseDrag(editor, overview.width + Style.spacing.controlGap + 8, editor.height - 16, 0, -100)
    verify(editor.editingButton, "dragging the gutter also keeps the editor open")
    editor.setupMode = "shortcut"
    editor.fKeysExpanded = true
    testCase.height = 450
    wait(30)
    verify(assignments.contentHeight > assignments.height, "expanded key palette has real scrolling")
    mouseDrag(assignments, assignments.width / 2, assignments.height - 30, 0, -100)
    verify(editor.editingButton)
    verify(assignments.contentY > 0, "the editor still scrolls")
    keyClick(Qt.Key_Escape)
    verify(!editor.editingButton)
    testCase.height = 800
  }

  function test_stable_editor_width_and_prompt() {
    var beforeWidth = surface.width
    var beforeHeight = editor.height
    var image = findChild(editor, "trackballIllustration")
    var imageWidth = image.width
    var prompt = findChild(editor, "assignmentEmptyTitle")
    verify(prompt !== null && prompt.visible, "unselected editor has guidance")
    compare(prompt.text, model.t("assignment_empty_title"))
    editor.editButton("back")
    wait(30)
    compare(surface.width, beforeWidth, "opening never widens/recenters the card")
    compare(editor.height, beforeHeight)
    compare(image.width, imageWidth)
    verify(!prompt.visible)
    var close = findChild(editor, "closeAssignment")
    compare(close.caption, model.t("close_editor"))
    compare(close.tooltipText, model.t("close_editor_tooltip"))
    mouseClick(close, close.width / 2, close.height / 2)
    wait(30)
    compare(surface.width, beforeWidth, "closing never narrows/recenters the card")
    verify(prompt.visible)
    compare(chosen, "")
  }

  function test_localized_actions_retranslate_without_writes() {
    var ids = ["workspace_next", "workspace_prev", "window_close", "window_float", "window_fullscreen", "window_next",
      "media_play_pause", "mute", "media_next", "media_prev", "tab_next", "tab_prev", "browser_back", "browser_forward",
      "overview", "screenshot", "profile_next", "default"]
    var locales = ["en", "ru", "de", "fr", "es", "it", "pt", "zh", "ja", "ko"]
    editor.editButton("back")
    locales.forEach(function(locale) {
      model.effectiveLanguage = locale
      model.language = locale
      ids.forEach(function(action) {
        model.actions = {back: action, forward: action, middle: action, tiltLeft: action, tiltRight: action}
        wait(10)
        ;["back", "forward", "middle", "tiltLeft", "tiltRight"].forEach(function(key) {
          var label = findChild(editor, "action_" + key)
          compare(label.text, model.t("action_" + action))
          verify(!label.truncated, locale + ": complete label for " + action + "/" + key)
          verify(label.font.pixelSize >= Style.font.bodySmall)
        })
        compare(findChild(editor, "assignmentValue").text, model.t("action_" + action))
        compare(findChild(editor, "assignmentMethod").text, model.t("assignment_method"))
        compare(findChild(editor, "availableActionsLabel").text, model.t("action_options"))
        compare(findChild(editor, "closeAssignment").caption, model.t("close_editor"))
      })
    })
    compare(chosen, "", "language changes are presentation only")
    verify(editor.editingButton)
  }

  function test_narrow_editor_locales_data() {
    return ["en", "ru", "de", "fr", "es", "it", "pt", "zh", "ja", "ko"].map(function(locale) { return {tag:locale, locale:locale} })
  }
  function test_narrow_editor_locales(data) {
    testCase.availableWidth = 620
    testCase.height = 450
    model.effectiveLanguage = data.locale
    wait(20)
    var beforeWidth = surface.width
    var image = findChild(editor, "trackballIllustration")
    var beforeImageWidth = image.width
    editor.editButton("back")
    wait(30)
    compare(surface.width, beforeWidth)
    compare(image.width, beforeImageWidth)
    var assignments = findChild(editor, "assignmentViewport")
    verify(assignments.x >= findChild(editor, "overviewViewport").width)
    verify(assignments.x + assignments.width <= editor.width)
    var close = findChild(editor, "closeAssignment")
    var point = close.mapToItem(assignments, 0, 0)
    verify(point.x >= 0 && point.x + close.width <= assignments.width)
    mouseClick(close, close.width / 2, close.height / 2)
    verify(!editor.editingButton)
    compare(surface.width, beforeWidth)
  }
  function test_page_transitions_preserve_frame() {
    var before = {width: surface.width, height: surface.height}
    var nav = findChild(editor, "panelNavigation")
    var navY = nav.mapToItem(editor, 0, 0).y
    var image = findChild(editor, "trackballIllustration")
    var imageY = image.mapToItem(editor, 0, 0).y
    var imageWidth = image.width
    model.canRecover = true
    ;["buttons", "pointer", "device", "pointer", "buttons", "device", "buttons"].forEach(function(page) {
      var tab = findChild(editor, "page_" + page)
      mouseClick(tab, tab.width / 2, tab.height / 2)
      wait(30)
      compare(editor.panelPage, page, "actual tab switches page")
      compare(surface.width, before.width, "same frame width on " + page)
      compare(surface.height, before.height, "same frame height on " + page)
      compare(nav.mapToItem(editor, 0, 0).y, navY)
      verify(image.visible, "mouse context persists on " + page)
      compare(image.width, imageWidth)
      compare(image.mapToItem(editor, 0, 0).y, imageY)
      verify(findChild(editor, "buttonProfiles").visible)
    })
    var profiles = findChild(editor, "buttonProfiles")
    profiles.managementExpanded = true
    editor.languageExpanded = true
    model.settingsRecoveryFailed = true
    wait(30)
    compare(surface.height, before.height, "forms/status do not resize the frame")
    compare(nav.mapToItem(editor, 0, 0).y, navY)
    var overview = findChild(editor, "overviewViewport")
    mouseWheel(overview, overview.width / 2, overview.height / 2, 0, -120)
    wait(30)
    verify(overview.contentY > 0)
    compare(nav.mapToItem(editor, 0, 0).y, navY, "scrolling never moves navigation")
  }

  function test_pointer_controls_and_settings_scroll() {
    editor.showPage("pointer")
    wait(30)
    var flat = findChild(editor, "accelFlat")
    mouseClick(flat, flat.width / 2, flat.height / 2)
    compare(model.accelProfile, "flat")
    var natural = findChild(editor, "naturalScrollRow")
    mouseClick(natural, natural.width / 2, natural.height / 2)
    compare(model.naturalScroll, true)
    editor.cursorActive = true
    editor.focusIndex = 2
    model.sensitivity = 0.45
    editor.forceActiveFocus()
    keyClick(Qt.Key_Return)
    compare(model.sensitivity, 0, "keyboard operates the global pointer control")
    testCase.height = 450
    editor.showPage("device")
    model.batteryReportText = Array(120).join("Long battery diagnostic text. ")
    wait(30)
    var left = findChild(editor, "overviewViewport")
    var right = findChild(editor, "settingsViewport")
    editor.focusIndex = 5
    editor.ensureCursorVisible()
    verify(right.contentY > 0, "keyboard scrolls the page control into the right viewport")
    var autoReconnect = findChild(editor, "autoReconnectRow")
    var position = autoReconnect.mapToItem(right, 0, 0)
    verify(position.y >= 0 && position.y + autoReconnect.height <= right.height)
    compare(left.contentY, 0, "right-page navigation does not scroll the mouse")
    editor.forceActiveFocus()
    keyClick(Qt.Key_Return)
    compare(model.autoReconnect, false)
  }

  function labelFor(item, value) {
    if (typeof item.wrapMode === "number" && item.text === value) return item
    for (var i = 0; i < item.children.length; ++i) {
      var found = labelFor(item.children[i], value)
      if (found) return found
    }
    return null
  }
  function verifyWrappedCaption(control) {
    verify(control !== null, "wrapping control exists")
    var caption = control.caption === undefined ? control.actionLabel : control.caption
    var label = labelFor(control, caption)
    verify(label !== null, control.objectName + ": caption exists")
    var point = label.mapToItem(control, 0, 0)
    verify(point.x >= 0 && point.x + label.width <= control.width)
    verify(point.y >= 0 && point.y + label.height <= control.height)
    verify(!label.truncated)
  }
  function test_all_pages_short_locales_data() {
    return ["en", "ru", "de", "fr", "es", "it", "pt", "zh", "ja", "ko"].map(function(locale) { return {tag:locale, locale:locale} })
  }

  function test_recovery_action_on_every_page() {
    model.canRecover = true
    model.canStartRecovery = true
    var recovery = findChild(editor, "deviceRecovery")
    ;["buttons", "pointer", "device"].forEach(function(page, index) {
      editor.showPage(page)
      wait(20)
      verify(recovery.visible && recovery.enabled, page + ": recovery is immediately available")
      var content = findChild(editor, page === "buttons" ? "assignmentViewport" : "settingsViewport")
      verify(recovery.y + recovery.height <= content.y, "recovery does not cover page content")
      mouseClick(recovery, recovery.width / 2, recovery.height / 2)
      compare(model.recoveries, index + 1)
    })
    editor.editButton("back")
    editor.setupMode = "command"
    findChild(editor, "assignmentCommand").text = "unapplied recovery draft"
    wait(20)
    mouseClick(recovery, recovery.width / 2, recovery.height / 2)
    compare(model.recoveries, 4)
    verify(editor.editingButton)
    compare(findChild(editor, "assignmentCommand").text, "unapplied recovery draft")
    model.recoveryResult = "recovery_connect_failed"
    compare(recovery.detail, model.t("recovery_connect_failed"), "failure is visible on the initial page")
    wait(20)
    var viewport = findChild(editor, "assignmentViewport")
    verify(recovery.y + recovery.height <= viewport.y, "failure feedback cannot cover the editor")
    model.isConnecting = true
    verify(!recovery.enabled, "a pending Connect cannot be duplicated")
  }

  function test_recovery_cancel_remains_reachable() {
    model.recoveryBusy = true
    model.recoveryStage = "scanning"
    var cancel = findChild(editor, "deviceRecovery")
    ;["buttons", "pointer", "device"].forEach(function(page, index) {
      editor.showPage(page)
      wait(20)
      verify(cancel.visible && cancel.enabled)
      mouseClick(cancel, cancel.width / 2, cancel.height / 2)
      compare(model.cancellations, index + 1)
    })
    editor.editButton("back")
    wait(20)
    verify(cancel.visible && cancel.enabled, "active recovery can be cancelled during editing")
    mouseClick(cancel, cancel.width / 2, cancel.height / 2)
    compare(model.cancellations, 4)
    verify(editor.editingButton, "recovery control does not dismiss the editor")
  }
  function test_all_pages_short_locales(data) {
    testCase.height = 450
    testCase.availableWidth = 620
    model.effectiveLanguage = data.locale
    var nav = findChild(editor, "panelNavigation")
    var navY = nav.mapToItem(editor, 0, 0).y
    ;["buttons", "pointer", "device"].forEach(function(page) {
      editor.showPage(page)
      wait(20)
      compare(surface.width, 620)
      compare(surface.height, 450)
      compare(nav.mapToItem(editor, 0, 0).y, navY)
      verify(findChild(editor, "trackballIllustration").visible)
      if (page !== "buttons") {
        var right = findChild(editor, "settingsViewport")
        verify(right.visible && right.x >= findChild(editor, "overviewViewport").width)
        verify(right.x + right.width <= editor.width)
        if (page === "pointer") {
          verifyWrappedCaption(findChild(editor, "accelAdaptive"))
          verifyWrappedCaption(findChild(editor, "accelFlat"))
        } else {
          verify(findChild(editor, "autoReconnectRow").visible)
          verifyWrappedCaption(findChild(editor, "deviceAdvanced"))
          editor.advancedExpanded = true
          wait(20)
          verify(findChild(editor, "adapterSettings").visible)
          verifyWrappedCaption(findChild(editor, "adapterProfileAction"))
          model.canRecover = true
          wait(20)
          var recovery = findChild(editor, "deviceRecovery")
          verifyWrappedCaption(recovery)
          verify(recovery.y + recovery.height <= right.y, "long recovery label cannot overlap device content")
        }
      }
    })
    editor.editButton("back")
    editor.setupMode = "shortcut"
    wait(20)
    verifyWrappedCaption(findChild(editor, "assignmentClear"))
    verifyWrappedCaption(findChild(editor, "assignmentShortcutApply"))
    editor.setupMode = "command"
    wait(20)
    verifyWrappedCaption(findChild(editor, "assignmentCommandApply"))
  }

  function test_advanced_disclosure_keyboard_and_feedback() {
    editor.showPage("device")
    wait(20)
    var details = findChild(editor, "adapterSettings")
    var disclosure = findChild(editor, "deviceAdvanced")
    verify(details !== null && disclosure !== null, "adapter disclosure exists")
    verify(!details.visible, "rare adapter settings are initially disclosed only on request")
    verify(disclosure.visible)
    model.lowLatencyHelperAvailable = true
    editor.cursorActive = true
    editor.focusIndex = 6
    editor.forceActiveFocus()
    keyClick(Qt.Key_Return)
    verify(details.visible)
    compare(model.adapterChanges, 0, "disclosure must not change the adapter")
    editor.stepFocus(1)
    compare(editor.focusIndex, 8)
    keyClick(Qt.Key_Return)
    compare(model.adapterChanges, 1, "explicit profile action remains keyboard reachable")
    editor.focusIndex = 6
    keyClick(Qt.Key_Return)
    verify(!details.visible)
    model.lowLatencyFailed = true
    verify(details.visible, "a new adapter failure opens its details")
    keyClick(Qt.Key_Return)
    verify(!details.visible, "failure details remain explicitly collapsible")
    compare(disclosure.detail, model.t("latency_error"), "collapsed disclosure retains the failure summary")
    model.lowLatencyFailed = false
    model.lowLatencyBusy = true
    verify(details.visible, "a pending operation opens its details")
    keyClick(Qt.Key_Return)
    verify(!details.visible)
    compare(disclosure.detail, model.t("latency_busy"))
    compare(model.adapterChanges, 1)
  }

  function test_profile_forms_preserve_mouse_and_keyboard() {
    var profiles = findChild(editor, "buttonProfiles")
    var mouse = findChild(editor, "trackballIllustration")
    var original = mouse.mapToItem(editor, 0, 0)
    var frame = {width: surface.width, height: surface.height}
    ;["create", "rename", "delete", "shortcut"].forEach(function(mode) {
      profiles.edit(mode)
      wait(20)
      var tools = findChild(editor, "profileToolsViewport")
      verify(tools !== null && tools.visible, mode + ": profile form uses the adjacent column")
      compare(mouse.mapToItem(editor, 0, 0).y, original.y, mode + ": mouse is not pushed below the panel")
      compare(surface.width, frame.width)
      compare(surface.height, frame.height)
      verify(tools.x >= findChild(editor, "overviewViewport").width)
      var apply = findChild(editor, "profileApply")
      verifyWrappedCaption(apply)
      compare(apply.caption, model.t(mode === "delete" ? "profile_delete" : "btn_apply"),
        mode + ": primary action describes the operation")
      apply.forceActiveFocus()
      verify(editor.blocked, "external profile form retains keyboard ownership")
      keyClick(Qt.Key_Backtab)
      verify(findChild(editor, "profileCancel").activeFocus)
      keyClick(Qt.Key_Escape)
      compare(profiles.mode, "")
      verify(!tools.visible)
    })
    profiles.edit("shortcut")
    var record = findChild(editor, "profileRecord")
    mouseClick(record, record.width / 2, record.height / 2)
    verify(profiles.recording)
    keyClick(Qt.Key_Escape)
    verify(!profiles.recording)
    compare(profiles.mode, "shortcut", "first Escape stops recording before dismissing the form")
    keyClick(Qt.Key_Escape)
    compare(profiles.mode, "")
    profiles.managementExpanded = true
    wait(20)
    verify(findChild(editor, "profileToolsViewport").visible)
    compare(mouse.mapToItem(editor, 0, 0).y, original.y)
    editor.editButton("back")
    verify(editor.editingButton && !profiles.toolsActive, "assignment editing replaces the profile tools in place")
  }

  function test_assignment_fields_and_primary_keyboard_apply() {
    editor.editButton("back")
    editor.setupMode = "shortcut"
    var input = findChild(editor, "assignmentShortcut")
    compare(input.Accessible.name, model.t("tab_shortcut"))
    var clear = findChild(editor, "assignmentClear")
    var apply = findChild(editor, "assignmentShortcutApply")
    verify(clear !== null && apply !== null, "assignment form actions exist")
    verify(apply.selected && !clear.selected, "Apply is the primary form action")
    clear.forceActiveFocus()
    keyClick(Qt.Key_Return)
    compare(input.text, "")
    compare(chosen, "", "clearing a field keeps the existing assignment")
    input.text = "ALT + F4"
    apply.forceActiveFocus()
    keyClick(Qt.Key_Return)
    compare(model.getCustomShortcut("back"), "ALT + F4")
    verify(editor.editingButton)
    editor.setupMode = "command"
    compare(findChild(editor, "assignmentCommand").Accessible.name, model.t("tab_command"))
  }

  function test_font_and_palette_data() {
    return [
      {tag: "dark-large-ru", font: 16, foreground: "#cacccc", background: "#101315", locale: "ru"},
      {tag: "light-large-de", font: 16, foreground: "#202020", background: "#fafaf7", locale: "de"},
      {tag: "light-normal-ja", font: 12, foreground: "#202020", background: "#fafaf7", locale: "ja"}
    ]
  }

  function contrast(foreground, background) {
    function luminance(color) {
      function linear(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4) }
      return 0.2126 * linear(color.r) + 0.7152 * linear(color.g) + 0.0722 * linear(color.b)
    }
    var a = luminance(foreground), b = luminance(background)
    return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05)
  }
  function composite(top, bottom) {
    return Qt.rgba(top.r * top.a + bottom.r * (1 - top.a),
      top.g * top.a + bottom.g * (1 - top.a), top.b * top.a + bottom.b * (1 - top.a), 1)
  }

  function test_font_and_palette(data) {
    try {
      Style.fontBaseSize = data.font
      Color.foreground = data.foreground
      Color.background = data.background
      Color.accent = data.foreground
      Color.popups.background = data.background
      testCase.width = 1100
      testCase.availableWidth = 1100
      testCase.height = 900
      model.effectiveLanguage = data.locale
      wait(30)
      var frame = {width: surface.width, height: surface.height}
      var mouseWidth = findChild(editor, "trackballIllustration").width
      ;["buttons", "pointer", "device"].forEach(function(page) {
        editor.showPage(page)
        wait(20)
        compare(surface.width, frame.width)
        compare(surface.height, frame.height)
        compare(findChild(editor, "trackballIllustration").width, mouseWidth)
      })
      editor.editButton("back")
      editor.setupMode = "shortcut"
      wait(20)
      ;["assignmentClear", "assignmentShortcutApply", "closeAssignment"].forEach(function(name) {
        var control = findChild(editor, name)
        verify(control !== null, name + ": control exists")
        verifyWrappedCaption(control)
        var label = labelFor(control, control.caption)
        verify(contrast(label.color, composite(control.color, Color.popups.background)) >= 4.5,
          name + ": text contrast against actual control fill")
      })
      var apply = findChild(editor, "assignmentShortcutApply")
      apply.forceActiveFocus()
      wait(20)
      verify(apply.activeFocus && apply._showFocusRing)
      verify(contrast(labelFor(apply, apply.caption).color, composite(apply.color, Color.popups.background)) >= 4.5)
      compare(surface.width, frame.width)
      compare(surface.height, frame.height)
    } finally {
      Style.fontBaseSize = 12
      Color.foreground = "#cacccc"
      Color.background = "#101315"
      Color.accent = "#cacccc"
      Color.popups.background = Color.background
      testCase.width = 780
    }
  }


}
