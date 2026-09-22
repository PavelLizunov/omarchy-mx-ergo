import QtQuick
import QtTest
import "../.." as Plugin

TestCase {
  id: testCase
  name: "TrackballMap"
  when: windowShown
  visible: true
  width: 420
  height: 620

  function sampleButtons() {
    return [
      { key: "back", label: "Back Button", action: "SUPER + ALT + E" },
      { key: "forward", label: "Forward Button", action: "Insert" },
      { key: "middle", label: "Middle Click", action: "Default" },
      { key: "tiltLeft", label: "Tilt Left", action: "Previous Workspace" },
      { key: "tiltRight", label: "Tilt Right", action: "Next Workspace" }
    ]
  }

  Flickable {
    id: viewport
    width: 320
    height: 500
    contentWidth: width
    contentHeight: map.height
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    Plugin.TrackballMap {
      id: map
      width: viewport.width
      height: implicitHeight
      buttons: testCase.sampleButtons()
      foreground: "white"
      background: "darkslategray"
      accent: "lightblue"
      fontFamily: "monospace"
      labelSize: 11
      actionSize: 10
      gap: 4
      padding: 6
      borderWidth: 1
      cornerRadius: 2
      onSelectionRequested: function (key) { selectedButton = key }
    }
  }

  SignalSpy { id: selectedSpy; target: map; signalName: "selectionRequested" }

  function init() {
    viewport.width = 320
    viewport.height = 500
    viewport.contentY = 0
    map.buttons = sampleButtons()
    map.selectedButton = "back"
    selectedSpy.clear()
    wait(30)
  }

  function test_callouts_and_hotspots_data() {
    return sampleButtons().map(function (button) { return { tag: button.key, key: button.key } })
  }
  function test_callouts_and_hotspots(data) {
    var original = JSON.stringify(map.buttons)
    var callout = findChild(map, "callout_" + data.key)
    verify(callout !== null)
    mouseClick(callout, callout.width / 2, callout.height / 2)
    compare(selectedSpy.count, 1)
    compare(selectedSpy.signalArguments[0][0], data.key)
    compare(map.selectedButton, data.key)
    var hotspot = findChild(map, "hotspot_" + data.key)
    verify(hotspot !== null)
    mouseClick(hotspot, hotspot.width / 2, hotspot.height / 2)
    compare(selectedSpy.count, 2)
    compare(selectedSpy.signalArguments[1][0], data.key)
    compare(JSON.stringify(map.buttons), original, "selection must not mutate assignments")
  }

  function test_keyboard_and_unknown_key() {
    var callout = findChild(map, "callout_forward")
    callout.forceActiveFocus()
    keyClick(Qt.Key_Return)
    compare(map.selectedButton, "forward")
    compare(selectedSpy.count, 1)
    map.selectButton("not-a-button")
    compare(selectedSpy.count, 1)
  }

  function test_live_assignment_label() {
    var changed = sampleButtons()
    changed[0].action = "CTRL + SHIFT + F12"
    map.buttons = changed
    compare(findChild(map, "action_back").text, "CTRL + SHIFT + F12")
    compare(selectedSpy.count, 0)
  }

  function test_narrow_and_translated_labels() {
    viewport.width = 260
    var changed = sampleButtons()
    changed[0].label = "Кнопка перехода назад"
    changed[0].action = "Очень длинное название пользовательского действия"
    map.buttons = changed
    wait(30)
    for (var i = 0; i < changed.length; ++i) {
      var callout = findChild(map, "callout_" + changed[i].key)
      var point = callout.mapToItem(map, 0, 0)
      verify(point.x >= 0 && point.x + callout.width <= map.width + 0.01)
      verify(point.y >= 0 && point.y + callout.height <= map.height + 0.01)
      var label = findChild(map, "label_" + changed[i].key)
      verify(label.height >= label.paintedHeight, "title must wrap without clipping")
    }
  }

  function test_scroll_when_height_is_limited() {
    viewport.height = 180
    verify(viewport.contentHeight > viewport.height)
    mouseWheel(viewport, 160, 160, 0, -240)
    wait(80)
    verify(viewport.contentY > 0, "wheel must scroll the diagram")
    compare(selectedSpy.count, 0, "scrolling must not select a button")
  }

  function test_connector_origins_follow_layout() {
    for (var pass = 0; pass < 2; ++pass) {
      if (pass === 1) {
        var changed = sampleButtons()
        changed[2].label = "Нажатие на среднюю кнопку колеса"
        map.buttons = changed
      }
      wait(30)
      var buttons = sampleButtons()
      for (var i = 0; i < buttons.length; ++i) {
        var callout = findChild(map, "callout_" + buttons[i].key)
        var expected = callout.mapToItem(map, callout.topSide ? callout.width / 2 : callout.leftSide ? callout.width : 0, callout.topSide ? callout.height : callout.height / 2)
        compare(callout.origin.x, expected.x, buttons[i].key + " connector x")
        compare(callout.origin.y, expected.y, buttons[i].key + " connector y")
      }
    }
  }

  function test_asset_and_preview() {
    var illustration = findChild(map, "trackballIllustration")
    tryCompare(illustration, "status", Image.Ready)
    verify(illustration.sourceSize.width > 0)
  }

  function test_balanced_geometry_with_long_labels() {
    var changed = sampleButtons()
    changed[0].label = "Кнопка перехода назад"
    changed[4].action = "Очень длинное название рабочего пространства"
    map.buttons = changed
    wait(30)
    var illustration = findChild(map, "trackballIllustration")
    compare(illustration.x + illustration.width / 2, map.width / 2)
    var middle = findChild(map, "callout_middle")
    compare(middle.x + middle.width / 2, map.width / 2)
    for (var pair of [["forward", "tiltLeft"], ["back", "tiltRight"]]) {
      var left = findChild(map, "callout_" + pair[0])
      var right = findChild(map, "callout_" + pair[1])
      compare(left.width, right.width)
      compare(left.height, right.height)
      compare(left.mapToItem(map, 0, 0).y, right.mapToItem(map, 0, 0).y)
    }
  }
}
