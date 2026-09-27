#!/usr/bin/env python3
"""Offscreen UI checks: installed controls and inert copies of shell theme tokens.

Quickshell's core plugin is embedded in the shell executable and cannot be loaded
by qmltestrunner. Remove only theme I/O tails in the temporary fixture; production
controls, profile component and test input remain unchanged. No second shell or
live desktop input is used. This does not verify the running shell's theme I/O.
"""
from pathlib import Path
import argparse
import json
import os
import re
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument('--capture', type=Path)
parser.add_argument('--capture-panel', type=Path)
parser.add_argument('--capture-states', type=Path)
args = parser.parse_args()
with tempfile.TemporaryDirectory(prefix='mx-profile-ui-') as temporary:
    imports = Path(temporary)
    for name in ('Commons', 'Ui'):
        shutil.copytree(Path('/usr/share/omarchy/shell') / name, imports / 'qs' / name)
    for name, boundary in [('Style', '  property Process hyprctlProc:'),
                           ('Color', '  property FileView colorsFile:')]:
        file = imports / 'qs/Commons' / (name + '.qml')
        source = file.read_text()
        if boundary not in source:
            raise RuntimeError('Installed shell theme structure changed: ' + name)
        source = source[:source.index(boundary)] + '}\n'
        source = re.sub(r'^import Quickshell(?:\.Io)?\n', '', source, flags=re.M)
        source = re.sub(r'Quickshell\.env\("[A-Z_]+"\)', '""', source)
        file.write_text(source)
    util = imports / 'qs/Commons/Util.qml'
    util.write_text(re.sub(r'^import Quickshell\n', '', util.read_text(), flags=re.M))
    inputs = root / 'tests/profiles-ui'
    if args.capture or args.capture_panel or args.capture_states:
        inputs = imports / 'capture'
        inputs.mkdir()
        fixture = 'tst_editor.qml' if args.capture_panel or args.capture_states else 'tst_profiles.qml'
        source = (root / 'tests/profiles-ui' / fixture).read_text()
        source = source.replace('"../.." as Plugin', json.dumps(root.as_uri()) + ' as Plugin')
        source = source.replace('"../../ButtonProfiles.js"', json.dumps((root/'ButtonProfiles.js').as_uri()))
        source = source.replace('"../../I18n.js"', json.dumps((root/'I18n.js').as_uri()))
        if args.capture_states:
            args.capture_states.mkdir(parents=True, exist_ok=True)
            capture = """
  function test_visual_capture() {
    function save(name) {
      mouseMove(editor, editor.width - 4, editor.height - 4)
      // Installed native Button has a 120 ms color transition. Capture after
      // that transition and the next render opportunity, with known state below.
      wait(160)
      grabImage(surface).save(%s + "/" + name + ".png")
    }
    save("buttons")
    editor.editButton("back")
    save("assignment-workspaces")
    editor.setupMode = "shortcut"
    findChild(editor, "assignmentShortcut").text = "ALT + F4"
    save("assignment-draft")
    model.setCustomShortcut("back", "ALT + F4")
    save("assignment-applying")
    model.settingsPending = false
    model.settingsVerified = true
    save("assignment-saving")
    model.configPending = false
    save("assignment-saved")
    model.settingsRecoveryFailed = true
    model.settingsVerified = false
    save("assignment-error")
    model.settingsRecoveryFailed = false
    model.settingsVerified = true
    model.actions = Object.assign({}, model.actions, {back: "workspace_next"})
    editor.editButton("back")
    findChild(editor, "actionCategory").open()
    save("assignment-category-menu")
    for (var step = 0; step < 4; step++) keyClick(Qt.Key_Down)
    keyClick(Qt.Key_Return)
    compare(findChild(editor, "actionCategory").value, "4")
    verify(findChild(editor, "action_profile_next").visible)
    save("assignment-system")
    editor.setupMode = "shortcut"
    save("assignment-shortcut")
    editor.fKeysExpanded = true
    save("assignment-function-keys")
    editor.setupMode = "command"
    save("assignment-command")
    editor.showPage("pointer")
    save("pointer")
    model.canRecover = true
    editor.showPage("device")
    save("device")
    editor.advancedExpanded = true
    save("device-advanced")
    model.lowLatencyFailed = true
    save("device-advanced-error")
    editor.advancedExpanded = false
    save("device-advanced-error-collapsed")
    model.lowLatencyFailed = false
    model.lowLatencyBusy = true
    save("device-advanced-busy")
    model.lowLatencyBusy = false
    editor.advancedExpanded = false
    editor.showPage("buttons")
    var profiles = findChild(editor, "buttonProfiles")
    profiles.managementExpanded = true
    save("profile-management")
    profiles.edit("create")
    save("profile-create")
    profiles.edit("rename")
    save("profile-rename")
    profiles.edit("delete")
    tryCompare(findChild(editor, "profileApply"), "caption", model.t("profile_delete"))
    tryCompare(labelFor(findChild(editor, "profileApply"), model.t("profile_delete")), "text", model.t("profile_delete"))
    save("profile-delete")
    profiles.edit("shortcut")
    save("profile-shortcut")
    editor.showPage("buttons")
    editor.editButton("back")
    editor.setupMode = "command"
    findChild(editor, "assignmentCommand").text = "unapplied command"
    save("editor-dismiss-before")
    var assignments = findChild(editor, "assignmentViewport")
    var point = assignments.mapToItem(editor, assignments.width / 2, assignments.height - 12)
    mouseClick(editor, point.x, point.y)
    verify(!editor.editingButton)
    compare(model.getCustomCommand("back"), "")
    save("editor-dismiss-after")
    ;["en", "ru", "de", "fr", "es", "it", "pt", "zh", "ja", "ko"].forEach(function(locale) {
      editor.showPage("buttons")
      model.effectiveLanguage = locale
      model.language = locale
      model.actions = {back: "workspace_next", forward: "default", middle: "default", tiltLeft: "workspace_prev", tiltRight: "workspace_next"}
      save("locale-" + locale + "-overview")
      editor.editButton("back")
      save("locale-" + locale + "-editor")
      editor.showPage("pointer")
      save("locale-" + locale + "-pointer")
      editor.showPage("device")
      save("locale-" + locale + "-device")
      editor.advancedExpanded = true
      save("locale-" + locale + "-device-advanced")
      editor.advancedExpanded = false
    })
    try {
      Color.foreground = "#202020"
      Color.background = "#fafaf7"
      Color.accent = Color.foreground
      Color.popups.background = Color.background
      model.effectiveLanguage = "en"
      model.language = "en"
      editor.showPage("buttons")
      save("light-buttons")
      editor.editButton("back")
      save("light-editor")
      editor.showPage("pointer")
      save("light-pointer")
      editor.showPage("device")
      save("light-device")
      Color.foreground = "#cacccc"
      Color.background = "#101315"
      Color.accent = Color.foreground
      Color.popups.background = Color.background
      testCase.width = 1100
      testCase.availableWidth = 1100
      testCase.height = 900
      Style.fontBaseSize = 16
      model.effectiveLanguage = "ru"
      model.language = "ru"
      editor.editButton("back")
      editor.setupMode = "shortcut"
      save("large-dark-shortcut")
      Color.foreground = "#202020"
      Color.background = "#fafaf7"
      Color.accent = Color.foreground
      Color.popups.background = Color.background
      model.effectiveLanguage = "de"
      model.language = "de"
      save("large-light-shortcut")
      editor.showPage("pointer")
      save("large-light-pointer")
      editor.showPage("device")
      editor.advancedExpanded = true
      save("large-light-device-advanced")
    } finally {
      Style.fontBaseSize = 12
      Color.foreground = "#cacccc"
      Color.background = "#101315"
      Color.accent = Color.foreground
      Color.popups.background = Color.background
      testCase.width = 780
    }
  }
""" % json.dumps(str(args.capture_states.resolve()))
        elif args.capture_panel:
            capture = """
  function test_visual_capture() {
    wait(150)
    var image = grabImage(surface)
    image.save(%s)
    editor.editButton("back")
    wait(70)
    image = grabImage(surface)
    image.save(%s)
  }
""" % (json.dumps(str(args.capture_panel.resolve())),
       json.dumps(str(args.capture_panel.with_name(args.capture_panel.stem + '-editor.png').resolve())))
        else:
            capture = """
  function test_visual_capture() {
    model.createProfile("Работа")
    panel.edit("shortcut")
    control("profileShortcutInput").text = "CTRL + SHIFT + F12"
    wait(50)
    catcher.height = panel.height
    wait(20)
    var image = grabImage(catcher)
    compare(image.width, 380)
    image.save(%s)
  }
""" % json.dumps(str(args.capture.resolve()))
        source = source[:source.rfind('}')] + capture + '}\n'
        (inputs / fixture).write_text(source)
    command = ['/usr/lib/qt6/bin/qmltestrunner', '-import', str(imports),
               '-input', str(inputs)]
    result = subprocess.run(command, env={**os.environ, 'QT_QPA_PLATFORM': 'offscreen', 'QT_QUICK_BACKEND': 'software'}, timeout=45 if args.capture_states else 30)
    capture_path = args.capture_panel or args.capture
    if capture_path and result.returncode == 0 and not capture_path.is_file():
        raise RuntimeError('UI capture was not written')
    raise SystemExit(result.returncode)
