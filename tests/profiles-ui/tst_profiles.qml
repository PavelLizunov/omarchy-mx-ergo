import QtQuick
import QtTest
import qs.Ui as Ui
import qs.Commons
import "../.." as Plugin
import "../../ButtonProfiles.js" as Profiles
import "../../I18n.js" as I18n

TestCase {
  id: testCase
  name: "ButtonProfilesPanel"
  when: windowShown
  visible: true
  width: 420
  height: 680

  QtObject {
    id: model
    property bool configReadComplete: true
    property bool profileBusy: false
    property var buttonProfiles: []
    property string activeProfileId: "main"
    property string profileShortcut: ""
    property string profileError: ""
    property string locale: "ru"
    readonly property string activeProfileName: {
      var item = Profiles.find(buttonProfiles, activeProfileId)
      return item ? item.name : "Main"
    }
    function t(key) { return I18n.t(key, locale) }
    function createProfile(name) {
      buttonProfiles = buttonProfiles.concat([Profiles.profile("work", name, buttonProfiles[0])])
      activeProfileId = "work"
      return true
    }
    function renameProfile(name) {
      buttonProfiles = buttonProfiles.map(function(p) {
        var copy = Profiles.copy(p)
        if (p.id === activeProfileId) copy.name = name
        return copy
      })
      return true
    }
    function selectProfile(id) { activeProfileId = id; return true }
    function deleteProfile() {
      if (buttonProfiles.length < 2) return false
      var previous = activeProfileId
      activeProfileId = buttonProfiles.find(function(p) { return p.id !== previous }).id
      buttonProfiles = buttonProfiles.filter(function(p) { return p.id !== previous })
      return true
    }
    function setProfileShortcut(value) { profileShortcut = value; return true }
  }

  Ui.PanelKeyCatcher {
    id: catcher
    width: 380
    height: testCase.height
    blocked: panel.ownsFocus || panel.popupOpen
    Rectangle {
      anchors.fill: parent
      color: Color.popups.background
    }
    Plugin.ButtonProfilesPanel {
      id: panel
      width: catcher.width
      model: model
    }
  }

  function control(name) { return findChild(panel, name) }
  function click(name) {
    wait(20) // Allow Column/Flow polish after a draft mode changes.
    var item = control(name)
    verify(item !== null, name)
    verify(item.visible && item.enabled, name)
    mouseClick(item, item.width / 2, item.height / 2)
    wait(10)
  }

  function init() {
    panel.reset()
    catcher.width = 380
    model.profileBusy = false
    model.profileError = ""
    model.profileShortcut = ""
    model.locale = "ru"
    model.buttonProfiles = [Profiles.profile("main", "Основной", null)]
    model.activeProfileId = "main"
    wait(20)
  }

  function test_create_rename_delete_and_draft() {
    click("profileManage")
    verify(!control("profileDelete").enabled)
    click("profileAdd")
    compare(panel.mode, "create")
    var field = control("profileNameInput")
    verify(field.activeFocus)
    field.text = "Работа"
    keyClick(Qt.Key_Return)
    compare(model.buttonProfiles.length, 2)
    compare(model.activeProfileName, "Работа")
    compare(panel.mode, "")
    if (!panel.managementExpanded) click("profileManage")
    click("profileRename")
    field.text = "Браузер"
    click("profileCancel")
    compare(model.activeProfileName, "Работа", "cancel preserves the profile")
    if (!panel.managementExpanded) click("profileManage")
    click("profileRename")
    field.text = "Браузер"
    click("profileApply")
    compare(model.activeProfileName, "Браузер")
    if (!panel.managementExpanded) click("profileManage")
    click("profileDelete")
    compare(panel.mode, "delete")
    click("profileApply")
    compare(model.buttonProfiles.length, 1)
    compare(model.activeProfileId, "main")
  }

  function test_picker_and_keyboard_focus() {
    model.createProfile("Работа")
    var picker = control("profilePicker")
    picker.open()
    wait(20)
    keyClick(Qt.Key_Up)
    keyClick(Qt.Key_Return)
    compare(model.activeProfileId, "main")
    panel.focusFirst()
    keyClick(Qt.Key_Tab)
    verify(control("profileAdd").activeFocus, "Tab reaches Add from dropdown")
    keyClick(Qt.Key_Return)
    verify(control("profileNameInput").activeFocus)
    keyClick(Qt.Key_Escape)
    compare(panel.mode, "")
  }

  function test_record_apply_clear_and_busy() {
    if (!panel.managementExpanded) click("profileManage")
    click("profileShortcut")
    click("profileRecord")
    verify(panel.recording)
    verify(catcher.blocked, "profile fields own the parent's key catcher")
    keyClick(Qt.Key_F12, Qt.ControlModifier | Qt.ShiftModifier)
    compare(control("profileShortcutInput").text, "CTRL + SHIFT + F12")
    compare(model.profileShortcut, "", "recording changes only the draft")
    click("profileApply")
    compare(model.profileShortcut, "CTRL + SHIFT + F12")
    if (!panel.managementExpanded) click("profileManage")
    click("profileShortcut")
    click("profileClear")
    compare(model.profileShortcut, "CTRL + SHIFT + F12")
    click("profileApply")
    compare(model.profileShortcut, "")
    model.profileBusy = true
    verify(!control("profileAdd").enabled)
    verify(!control("profilePicker").enabled)
  }

  function test_layout_bounds_data() {
    var rows = []
    ;["en", "ru", "de", "fr", "es", "it", "pt", "zh", "ja", "ko"].forEach(function(locale) {
      ;[280, 380].forEach(function(width) { rows.push({tag: locale + width, locale: locale, width: width}) })
    })
    return rows
  }

  function test_layout_bounds(data) {
    catcher.width = data.width
    model.locale = data.locale
    panel.edit("shortcut")
    panel.recording = true
    wait(20)
    var controls = []
    panel.collectControls(panel, controls)
    controls.forEach(function(item) {
      var position = item.mapToItem(panel, 0, 0)
      verify(position.x >= -1 && position.x + item.width <= panel.width + 1,
        "Control overflows in " + data.locale + ": " + item.objectName)
    })
  }
}
