#!/usr/bin/env node
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.join(__dirname, '..', 'ErgoModel.qml'), 'utf8');
const root = { sensitivity: 0.25, accelProfile: 'flat', naturalScroll: true,
  hyprDeviceName: 'test-mx-ergo', configReadComplete: false,
  pendingSettingsRequest: null, settingsApplying: false, settingsGeneration: 0, settingsHelper: '/test/apply-settings.py', configHome: "/tmp/home with 'quote'/.config" };
for (const button of ['Back', 'Forward', 'Middle', 'TiltLeft', 'TiltRight']) {
  root['button' + button] = 'default';
  root['buttonCustomShortcut' + button] = '';
  root['buttonCustomCmd' + button] = '';
}
const later = new Set();
const applier = { running: false };
const timer = { restart() {}, stop() {} };
const context = vm.createContext({ root, console: { info() {}, warn() {} },
  Qt: { callLater: fn => later.add(fn) }, settingsApplier: applier,
  settingsDeadline: timer, settingsStartCheck: timer });
// QML unqualified properties refer to root; use accessors rather than a copied model.
for (const name of ['pendingSettingsRequest', 'settingsApplying', 'settingsStopping', 'settingsExitCode',
  'settingsOutput', 'settingsRecoveryFailed', 'settingsGeneration', 'settingsCapturedGeneration']) {
  Object.defineProperty(context, name, { get: () => root[name], set: v => { root[name] = v; } });
}
for (const name of ['shellQuote', 'getButtonAction', 'getCustomShortcut', 'getCustomCommand', 'shortcutToWtype',
  'buildBindSnippet', 'buildSettingsRequest', 'applyButtonBind', 'applySensitivity', 'applyAccelProfile',
  'applyNaturalScroll', 'applyAllSettings', 'drainSettingsRequest', 'finishSettingsApply']) {
  const fn = source.match(new RegExp('^  function ' + name + '\\([^]*?^  \\}', 'm'));
  // One-line delegators are deliberately handled separately.
  const short = source.match(new RegExp('^  function ' + name + '\\([^\\n]+\\}\\s*$', 'm'));
  assert.ok(short || fn, name);
  vm.runInContext((short || fn)[0], context);
  root[name] = context[name];
}
function flush() { while(later.size) { const batch = [...later]; later.clear(); batch.forEach(fn => fn()); } }
function finish(ok) {
  applier.running = false; root.settingsExitCode = ok ? 0 : 1;
  root.settingsOutput = JSON.stringify({ ok }); root.finishSettingsApply(); flush();
}
const connection = source.match(/property Connections hyprlandEvents: Connections \{([\s\S]*?)^  \}/m);
const handler = connection[1].match(/function onRawEvent\(event\) \{([\s\S]*?)^    \}/m);
vm.runInContext('function deliver(event) {' + handler[1] + '\n}', context);
context.deliver({name:'configreloaded'}); flush();
assert.equal(applier.running, false, 'No defaults before saved configuration');
root.configReadComplete = true;
root.settingsConfigured = false;
context.deliver({name:"configreloaded"}); flush();
assert.equal(applier.running, false, "Missing or corrupt preferences must not apply defaults on theme reload");
root.settingsConfigured = true;
root.buttonBack = 'custom_shortcut'; root.buttonCustomShortcutBack = 'SUPER + ALT + E';
root.buttonForward = 'custom_command'; root.buttonCustomCmdForward = 'printf "example"';
root.buttonTiltLeft = 'workspace_prev'; root.buttonTiltRight = 'workspace_next';
context.deliver({name:'configreloaded'}); flush();
assert.equal(applier.running, true);
assert.equal(applier.command[0], '/usr/bin/python3');
assert.equal(applier.command[1], '-I');
const first = JSON.parse(applier.command[3]);
assert.equal(first.expected['mouse:275'], 'MX Ergo: TTS Selection');
assert.equal(first.expected['mouse:274'], null);
assert.equal(first.expected['mouse_left'], 'MX Ergo: Prev Workspace');
assert.equal(Object.keys(first.expected).length, 7);
assert.equal((first.lua.match(/hl.device\(/g)||[]).length,1);
// Several UI changes must not overlap the active helper, and only the last survives.
root.buttonForward = 'workspace_prev'; root.applyAllSettings(); flush();
root.buttonForward = 'workspace_next'; root.applyAllSettings(); flush();
assert.deepEqual(JSON.parse(applier.command[3]), first);
finish(false);
assert.equal(applier.running,true);
assert.equal(JSON.parse(applier.command[3]).expected['mouse:276'],'MX Ergo: Next Workspace');
assert.equal(root.settingsRecoveryFailed,false,'Old failure cannot overwrite newer request status');
finish(true);
assert.equal(root.settingsApplying,false);
assert.equal(root.settingsRecoveryFailed,false);
for (const event of [null, {}, {name:'workspace'}, {name:'activewindow'}]) context.deliver(event);
flush(); assert.equal(applier.running,false);
root.applyAllSettings(); flush(); finish(false);
assert.equal(root.settingsRecoveryFailed,true,'Exhausted helper reports failure');
assert.equal(applier.running,false,'No unbounded restarts');
// Bad settings must not launch Lua or falsely clear the failure.
root.accelProfile = 'bad"profile'; root.applyAllSettings(); flush();
assert.equal(applier.running,false);
assert.equal(root.settingsRecoveryFailed,true);
root.accelProfile='flat'; root.hyprDeviceName='name"with\\escapes';
assert.ok(root.buildSettingsRequest().lua.includes(JSON.stringify(root.hyprDeviceName)));
// Existing descriptions with escaped quotes survive extraction.
root.buttonBack='custom_shortcut'; root.buttonCustomShortcutBack='CTRL + "';
assert.equal(root.buildSettingsRequest().expected['mouse:275'],'MX Ergo: CTRL + "');
console.log('PASS: production recovery queue, reload gate, latest-wins, verification result and safe payload generation');

// Shell metacharacters in the shortcut field are literal key operands.
for (const key of [";id", "$(id)", "`id`", "'", '"']) {
  const command = context.shortcutToWtype('CTRL + ' + key);
  assert.ok(command.includes(context.shellQuote(key)), command);
}
assert.equal(context.shortcutToWtype('CTRL + SHIFT'), '');
assert.equal(context.shortcutToWtype('  '), '');
assert.ok(first.lua.includes("home with"));
assert.ok(!first.lua.includes('/home/slovn/'));
