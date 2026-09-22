#!/usr/bin/env node

const assert = require('node:assert/strict');
const path = require('node:path');
const fs = require('node:fs');
const vm = require('node:vm');

// Load I18n without .pragma library
const i18nSrc = fs.readFileSync(path.join(__dirname, '..', 'I18n.js'), 'utf8')
  .replace(/^\.pragma library\s*/, '');
const i18nCtx = {};
vm.runInNewContext(i18nSrc, i18nCtx);
const I18n = i18nCtx;

// Test 1: I18n basics & fallback
assert.equal(I18n.t('plugin_name', 'en'), 'Logitech MX Ergo');
assert.equal(I18n.t('plugin_name', 'ru'), 'Logitech MX Ergo');
assert.equal(I18n.t('connected', 'en'), 'Connected');
assert.equal(I18n.t('connected', 'ru'), 'Подключено');
assert.equal(I18n.t('connected', 'de'), 'Verbunden');
assert.equal(I18n.t('connected', 'unknown_lang'), 'Connected'); // fallback to en
assert.equal(I18n.t('button_mapping', 'ru'), 'НАСТРОЙКА КНОПОК');
assert.equal(I18n.t('action_workspace_next', 'ru'), 'След. воркспейс');
assert.equal(I18n.t('connect_device', 'ru'), 'Подключить трекбол');
assert.equal(I18n.t('auto_reconnect', 'ru'), 'Автоподключение при пробуждении');
assert.equal(I18n.t('connect_device', 'en'), 'Connect Trackball');

// Exercise the actual QML functions, never a test copy of the implementation.
const source = fs.readFileSync(path.join(__dirname, '..', 'ErgoModel.qml'), 'utf8');
const root = { sensitivity: .25, accelProfile: 'flat', naturalScroll: false,
  hyprDeviceName: 'test-device', configHome: '/tmp/user config',
  connected: false, isConnecting: false, btDevice: null, targetAddress: '' };
for (const button of ['Back', 'Forward', 'Middle', 'TiltLeft', 'TiltRight']) {
  root['button' + button] = 'default';
  root['buttonCustomShortcut' + button] = '';
  root['buttonCustomCmd' + button] = '';
}
const dispatches = [];
const context = vm.createContext({root, Quickshell: {execDetached: args => dispatches.push(Array.from(args))},
  connectingResetTimer: {restart() {}}});
for (const name of ['shellQuote', 'shortcutToWtype', 'getCustomShortcut', 'getCustomCommand',
                    'getButtonAction', 'buildBindSnippet', 'buildSettingsRequest', 'reconnectDevice']) {
  const fn = source.match(new RegExp('^  function ' + name + '\\([^]*?^  \\}', 'm'));
  assert.ok(fn, name);
  vm.runInContext(fn[0], context);
}
assert.equal(context.shortcutToWtype('CTRL + C'), "wtype -s 25 -d 20 -M ctrl -k 'c' -m ctrl");
assert.equal(context.shortcutToWtype('SUPER + Return'), 'wtype -s 25 -d 20 -M logo -k Return -m logo');
assert.equal(context.shortcutToWtype('ALT + F4'), "wtype -s 25 -d 20 -M alt -k 'F4' -m alt");
assert.equal(context.shortcutToWtype('CTRL + INSERT'), 'wtype -s 25 -d 20 -M ctrl -k Insert -m ctrl');
assert.equal(context.shortcutToWtype('SHIFT + PAGEUP'), 'wtype -s 25 -d 20 -M shift -k Prior -m shift');
root.buttonTiltLeft = 'workspace_prev'; root.buttonTiltRight = 'window_fullscreen';
root.buttonBack = 'custom_shortcut'; root.buttonCustomShortcutBack = 'SUPER + 8';
root.buttonForward = 'custom_shortcut'; root.buttonCustomShortcutForward = 'Insert';
const request = context.buildSettingsRequest();
assert.equal(request.expected['mouse_left'], request.expected['mouse:278']);
assert.equal(request.expected['mouse_right'], request.expected['mouse:279']);
assert.equal(request.expected['mouse:275'], 'MX Ergo: Workspace 8');
assert.equal(request.expected['mouse:276'], 'MX Ergo: Voxtype Dictation');
assert.equal(request.expected['mouse:274'], null);
assert.ok(request.lua.includes('sensitivity = 0.25'));
assert.ok(request.lua.includes('natural_scroll = false'));
// Unknown/invalid targets must never connect to an author's fallback address.
for (const target of ['', '046D:B01D', 'AA:BB:CC:DD:EE:FF;id']) {
  root.targetAddress = target; context.reconnectDevice();
}
assert.equal(dispatches.length, 0);
root.targetAddress = 'AA:BB:CC:DD:EE:FF'; context.reconnectDevice();
assert.equal(dispatches.length, 0, 'Unknown native device requires pairing/discovery, never a detached connect');
root.isConnecting = false;
let nativeConnects = 0;
root.btDevice = {address: root.targetAddress, connect() {nativeConnects++;}};
context.reconnectDevice();
assert.equal(nativeConnects, 1);
assert.equal(dispatches.length, 0, 'Native connect must not launch a competing helper');
context.reconnectDevice(); assert.equal(nativeConnects,1,'Busy guard');
root.isConnecting=false; root.sleeping=true; context.reconnectDevice(); assert.equal(nativeConnects,1,'Sleep guard');
console.log('PASS: I18n and production model commands, tilt mappings and reconnect guards.');

for (const tag of ['zh-TW','zh-HK','zh-Hant','zh_Hant_TW']) assert.equal(I18n.resolveLanguage('system',tag),'en');
assert.equal(I18n.resolveLanguage('zh-Hans-CN','ru'),'zh');
assert.equal(I18n.resolveLanguage('de-CH','ru'),'de');
assert.equal(I18n.resolveLanguage('unknown','ru'),'en');
