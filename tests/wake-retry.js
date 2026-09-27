#!/usr/bin/env node

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const source = fs.readFileSync(path.join(__dirname, '..', 'ErgoModel.qml'), 'utf8');
const state = { Disconnected: 0, Connected: 1, Connecting: 2 };
const timer = () => ({ running: false, restart() { this.running = true; }, stop() { this.running = false; } });

function body(pattern, label) {
  const match = source.match(pattern);
  assert.ok(match, label);
  return match[1];
}

function harness() {
  let connects = 0;
  const device = {
    address: 'C2:B5:BB:BB:65:03', state: state.Disconnected,
    connect() { connects++; this.state = state.Connecting; }
  };
  const root = {
    btDevice: device, connected: false, isConnecting: false, recoveryBusy: false,
    sleeping: false, shuttingDown: false, canReconnect: true, autoReconnect: true,
    wakeRetryDevice: null
  };
  const c = vm.createContext({
    root, BluetoothDeviceState: state, connectingResetTimer: timer(),
    wakeReconnectTimer: timer(), wakeStage2Timer: timer(), wakeRetryDeadline: timer()
  });
  for (const name of ['reconnectDevice', 'finishWakeRetry']) {
    const match = source.match(new RegExp('^  function ' + name + '\\([^]*?^  \\}', 'm'));
    assert.ok(match, name);
    vm.runInContext(match[0], c);
    root[name] = c[name];
  }
  vm.runInContext('function firstStage() {' + body(/property Timer wakeReconnectTimer: Timer \{[\s\S]*?onTriggered: \{([\s\S]*?)\n    \}/, 'first stage') + '}', c);
  vm.runInContext('function secondStage() {' + body(/property Timer wakeStage2Timer: Timer \{[\s\S]*?onTriggered: \{([\s\S]*?)\n    \}/, 'second stage') + '}', c);
  vm.runInContext('function deviceStateChanged() {' + body(/property Connections wakeDeviceEvents: Connections \{[\s\S]*?function onStateChanged\(\) \{([\s\S]*?)\n    \}/, 'state change') + '}', c);
  return { root, device, c, get connects() { return connects; } };
}

{
  const h = harness();
  h.c.firstStage();
  assert.equal(h.connects, 1);
  assert.equal(h.root.wakeRetryDevice, h.device);
  h.c.wakeStage2Timer.running = false;
  h.c.secondStage();
  assert.equal(h.connects, 1, 'No duplicate Connect while Quickshell is still Connecting');
  h.root.isConnecting = false;
  h.device.state = state.Disconnected;
  h.c.deviceStateChanged();
  assert.equal(h.connects, 2, 'Retry after the first Connect has actually settled');
  assert.equal(h.root.wakeRetryDevice, null);
}

{
  const h = harness();
  h.c.firstStage();
  h.root.isConnecting = false;
  h.device.state = state.Disconnected;
  h.c.deviceStateChanged();
  assert.equal(h.connects, 1, 'An early failure waits until the second-stage delay');
  h.c.wakeStage2Timer.running = false;
  h.c.secondStage();
  assert.equal(h.connects, 2);
}

{
  const h = harness();
  h.c.firstStage();
  h.c.wakeStage2Timer.running = false;
  h.c.secondStage();
  h.root.btDevice = { address: 'C2:B5:BB:BB:65:02' };
  h.root.isConnecting = false;
  h.device.state = state.Disconnected;
  h.c.deviceStateChanged();
  assert.equal(h.connects, 1, 'A late reply cannot retry a newly selected device');
}

console.log('PASS: Wake retry waits for Quickshell Connect settlement and preserves device identity.');
