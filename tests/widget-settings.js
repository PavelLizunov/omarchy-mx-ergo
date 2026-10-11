#!/usr/bin/env node
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '..', 'BarWidget.qml'), 'utf8');
const root = {moduleName: 'io.github.pavellizunov.mx-ergo'};
const context = vm.createContext({root, currentSettings: null});
for (const name of ['resolveSettings', 'currentSetting']) {
  const match = source.match(new RegExp('^  function ' + name + '\\([^]*?^  \\}', 'm'));
  assert.ok(match, name);
  vm.runInContext(match[0], context);
}
const stale = {id: root.moduleName, deviceAddress: 'C2:B5:BB:BB:65:03', locale: 'en'};
const live = {id: root.moduleName, deviceAddress: '', locale: 'ru'};
const config = entry => ({layout: {left: [], center: [], right: [entry]}});
assert.equal(context.resolveSettings(config(live), stale), live,
  'A recreated widget must not restore stale Loader settings');
context.currentSettings = context.resolveSettings(config(live), stale);
assert.equal(context.currentSetting('deviceAddress', 'fallback'), '', 'Explicit automatic selection survives reload');
assert.equal(context.currentSetting('locale', 'system'), 'ru');
assert.equal(context.currentSetting('hideWhenDisconnected', false), false);
assert.equal(context.resolveSettings(null, stale), stale, 'Older hosts retain injected settings');
assert.equal(context.resolveSettings(config({id: 'another.plugin'}), stale), stale);
const duplicate = config(live); duplicate.layout.left.push({...live});
assert.equal(context.resolveSettings(duplicate, stale), stale, 'Ambiguous entries are not silently selected');
const pinned = {...live, deviceAddress: 'C2:B5:BB:BB:65:06'};
context.currentSettings = context.resolveSettings(config(pinned), stale);
assert.equal(context.currentSetting('deviceAddress', ''), pinned.deviceAddress, 'Explicit current pin is preserved');
for (const setting of ['deviceAddress', 'hyprDeviceName', 'sensitivity', 'accelProfile', 'naturalScroll', 'locale']) {
  assert.ok(source.includes('root.currentSetting("' + setting + '"'), setting + ': actual model consumes live settings');
}
assert.ok(source.includes('root.currentSettings || {}'), 'Locale writes cannot restore a stale address');
console.log('PASS: current scoped settings override stale Loader entries; automatic and explicit selection survive recreation.');
