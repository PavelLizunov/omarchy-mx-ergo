#!/usr/bin/env node
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const base = path.join(__dirname, '..');
const battery = {};
vm.runInNewContext(fs.readFileSync(path.join(base, 'Battery.js'), 'utf8').replace(/^\.pragma library\s*/, ''), battery);
const i18n = {};
vm.runInNewContext(fs.readFileSync(path.join(base, 'I18n.js'), 'utf8').replace(/^\.pragma library\s*/, ''), i18n);
const t = key => i18n.t(key, 'ru');

assert.equal(battery.tier(false, false, 'battery-full-charged-symbolic', true, 1), '');
assert.equal(battery.label(true, false, "", t), 'Заряд неизвестен');
assert.equal(battery.label(true, true, "full", t), 'Заряжается');
assert.equal(battery.tier(true, true, 'battery-full-charging-symbolic', true, 1), '');
assert.equal(battery.tier(true, null, 'battery-full-charging-symbolic', true, 1), '', 'Unknown state with charging icon must not become Full');
assert.equal(battery.tier(true, false, 'battery-full-charged-symbolic', false, null), 'full');
assert.equal(battery.label(true, false, "", t), 'Заряд неизвестен');
assert.equal(battery.tier(true, false, 'battery-low-symbolic', true, 1), 'low');
assert.equal(battery.tier(true, false, 'battery-full-symbolic', true, 0.05), 'critical');
for (const value of [undefined, null, NaN, Infinity, -1, 1.01, '1', false]) {
  assert.equal(battery.tier(true, false, '', true, value), '');
}
assert.equal(battery.tier(true, false, '', true, 0), 'critical');
assert.equal(battery.tier(true, false, 'battery-missing-symbolic', false, null), '');
assert.equal(battery.tier(true, false, 'battery-level-100-symbolic', false, null), '', 'Do not invent a category for unknown icons');

const metadata = 'DRIVER=logitech-hidpp-device\nHID_ID=0005:0000046D:0000B01D\nHID_UNIQ=aa:bb:cc:dd:ee:ff\n';
const identity = battery.identity(metadata);
assert.equal(identity.transport, 'ble');
assert.equal(battery.matches(identity, 'AA:BB:CC:DD:EE:FF'), true);
assert.equal(battery.matches(identity, '11:22:33:44:55:66'), false);
assert.equal(battery.matches(battery.identity(''), ''), false);
assert.equal(battery.identity(metadata.replace('B01D', 'B012')).transport, '');
assert.equal(battery.identity('HID_ID=0003:0000046D:0000406F\nHID_UNIQ=ABCD1234').transport, 'unifying');

// Exercise production QML selection/connection bindings, not copies of their logic.
const source = fs.readFileSync(path.join(base, 'ErgoModel.qml'), 'utf8');
function evaluate(name, root) {
  const match = source.match(new RegExp('readonly property (?:var|string) ' + name + ': \\{([\\s\\S]*?)^  \\}', 'm'));
  assert.ok(match, name);
  return vm.runInNewContext('(function(){' + match[1] + '\n})()', { root, Battery: battery, ...root });
}
const selected = { identity, device: { ready: true, isPresent: true, iconName: 'battery-low-symbolic' } };
const foreign = { identity: battery.identity(metadata.replace('aa:bb:cc:dd:ee:ff', '11:22:33:44:55:66')), device: { ready: true, isPresent: true } };
const root = { btDevice: { address: 'AA:BB:CC:DD:EE:FF', connected: true }, targetAddress: '', powerCandidates: [foreign, selected] };
assert.equal(evaluate('matchedPower', root), selected);
root.powerCandidates.push(selected);
assert.equal(evaluate('matchedPower', root), null, 'Ambiguous matches must not choose the first one');
root.powerCandidates = [selected];
selected.device.isPresent = false;
assert.equal(evaluate('matchedPower', root), null);
selected.device.isPresent = true;
selected.device.ready = false;
assert.equal(evaluate('matchedPower', root), null);
selected.device.ready = true;
root.matchedPower = selected;
root.btDevice.connected = false;
assert.equal(evaluate('transport', root), '', 'Cached BLE battery must not become a Unifying connection');
root.btDevice.connected = true;
assert.equal(evaluate('transport', root), 'ble');
assert.doesNotMatch(source, /driverReader|driverPollTimer|upDevice\.percentage/);
assert.match(source, /Battery\.tier\(root\.connected, root\.isCharging/);
console.log('PASS: Production battery logic: approximate levels, charging, unknowns, identity, disconnect, conflicts.');

const receiver = { identity: battery.identity('HID_ID=0003:0000046D:0000406F\nHID_UNIQ=ABCD1234'), device: {ready: true, isPresent: true} };
root.btDevice.connected = false;
root.powerCandidates = [receiver, selected];
assert.equal(evaluate('matchedPower', root), receiver, 'Paired but disconnected Bluetooth must not exclude a sole MX Ergo receiver');
root.powerCandidates.push({ ...receiver });
assert.equal(evaluate('matchedPower', root), null, 'Do not guess among multiple receivers');
root.btDevice.connected = true;
root.powerCandidates = [receiver];
assert.equal(evaluate('matchedPower', root), null, 'Active Bluetooth must not use another receiver battery');

for (const file of ['ErgoModel.qml', 'ErgoPanel.qml', 'BarWidget.qml']) {
  const qml = fs.readFileSync(path.join(base, file), 'utf8');
  assert.doesNotMatch(qml, /batterySegments|batteryFraction|batTrack|segNumber/, file + ': no gauge from unverified reports');
}
assert.equal(battery.label(false, false, "full", t), i18n.t('disconnected', 'ru'));
assert.equal(battery.label(true, null, "", t), 'Заряд неизвестен');
assert.match(source, /Battery\.label\(root\.connected, root\.isCharging, root\.batteryTier,\s*function/);
assert.match(source, /root\.t\("battery_reported"\)/, 'Keep reports explicitly qualified');
console.log('PASS: Reported categories are visible without a synthetic percentage or filled gauge.');

for (const level of ["full", "normal", "low", "critical"]) {
  assert.equal(battery.label(true, false, level, t), t("battery_" + level));
  assert.equal(battery.label(true, null, level, t), t("battery_" + level));
}
assert.equal(battery.label(true, false, "garbage", t), t("battery_unverified"));
