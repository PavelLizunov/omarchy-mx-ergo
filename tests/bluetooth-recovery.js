#!/usr/bin/env node

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const source = fs.readFileSync(path.join(__dirname, '..', 'ErgoModel.qml'), 'utf8');
const targetAddress = 'C2:B5:BB:BB:65:01';
const otherAddress = 'C2:B5:BB:BB:65:02';
const functionNames = [
  'scheduleStartupRecovery', 'startStartupRecovery',
  'recoverySelectionValid', 'recoverDevice', 'cancelRecovery', 'startRecoveryScan',
  'beginRecoveryScanWindow', 'startRecoveryConnect', 'updateRecoveryOtherState',
  'noteRecoveryOtherAddress', 'handleRecoveryScanLine', 'abortRecoveryConnect',
  'settleRecoveryAbort', 'finishRecovery'
];

function handler(section, name) {
  const block = source.match(new RegExp('property Connections ' + section + ': Connections \\{([\\s\\S]*?)\\n  \\}'));
  assert.ok(block, section);
  const body = block[1].match(new RegExp('function ' + name + '\\(\\) \\{([\\s\\S]*?)\\n    \\}'));
  assert.ok(body, name);
  return body[1];
}

function harness(initialConnected = true) {
  const calls = { disconnect: 0, connect: 0, otherDisconnect: 0, otherConnect: 0,
    scanStart: 0, scanStop: 0, cancelStart: 0, cancelStop: 0 };
  const timer = () => ({ interval: 0, restarts: 0, stops: 0, running: false,
    restart() { this.restarts++; this.running = true; },
    stop() { this.stops++; this.running = false; } });
  const adapter = { enabled: true, adapterId: 'hci0' };
  const device = {
    address: targetAddress, name: 'MX Ergo', connected: initialConnected,
    paired: true, bonded: true, adapter, state: initialConnected ? 1 : 0,
    disconnect() { calls.disconnect++; }, connect() { calls.connect++; this.state = 2; },
    pair() { throw new Error('Recovery must not pair'); },
    forget() { throw new Error('Recovery must not forget'); }
  };
  const other = {
    address: otherAddress, name: 'MX Ergo', connected: false,
    paired: false, bonded: false, adapter,
    disconnect() { calls.otherDisconnect++; }, connect() { calls.otherConnect++; }
  };
  const root = {
    targetAddress: '', btDevice: device, btDevicesList: [device, other],
    btAdaptersList: [adapter], observedBtAddress: '', recoveryStage: '',
    recoveryResult: '', recoveryDevice: null, recoveryAdapter: null,
    recoveryTargetAddress: '', recoveryScanStarted: false, recoverySeenTarget: false,
    recoveryOtherAddress: '', recoveryOtherMultiple: false,
    recoveryOtherPaired: null, recoveryOtherBonded: null,
    recoveryStopping: false, recoveryAbortResult: '', isConnecting: false,
    sleeping: false, shuttingDown: false, wakeRetryDevice: null,
    startupRecoveryAttempted: false, startupRecoveryDevice: null,
    configReadComplete: true, autoReconnect: true, connected: initialConnected
  };
  Object.defineProperty(root, 'canRecover', { get() {
    return !!root.btDevice && root.btDevice.paired && root.btDevice.bonded
      && root.btDevice.adapter.enabled && root.btAdaptersList.length === 1
      && root.btDevice.adapter === root.btAdaptersList[0];
  } });
  Object.defineProperty(root, 'canStartRecovery', { get() {
    return root.canRecover && root.btDevice.state !== 2 && root.btDevice.state !== 3;
  } });
  Object.defineProperty(root, 'recoveryBusy', { get() {
    return root.recoveryStage !== '' || root.recoveryStopping;
  } });
  let scanRunning = false;
  const process = {};
  Object.defineProperty(process, 'running', {
    get() { return scanRunning; },
    set(value) {
      if (value && !scanRunning) calls.scanStart++;
      if (!value && scanRunning) calls.scanStop++;
      scanRunning = value;
    }
  });
  let cancelRunning = false;
  const cancelProcess = { command: [] };
  Object.defineProperty(cancelProcess, 'running', {
    get() { return cancelRunning; },
    set(value) {
      if (value && !cancelRunning) calls.cancelStart++;
      if (!value && cancelRunning) calls.cancelStop++;
      cancelRunning = value;
    }
  });
  const context = vm.createContext({
    root, recoveryScanProcess: process, recoveryCancelProcess: cancelProcess,
    console: { info() {} },
    recoveryStepTimer: timer(),
    recoveryCleanupTimer: timer(), wakeReconnectTimer: timer(),
    wakeStage2Timer: timer(), wakeRetryDeadline: timer(), startupRecoveryTimer: timer(),
    BluetoothDeviceState: { Connected: 1, Disconnected: 0, Connecting: 2, Disconnecting: 3 }
  });
  for (const name of functionNames) {
    const match = source.match(new RegExp('^  function ' + name + '\\([^]*?^  \\}', 'm'));
    assert.ok(match, name);
    vm.runInContext(match[0], context);
    root[name] = context[name];
  }
  const eventBlock = source.match(/property Timer recoveryStepTimer: Timer \{[\s\S]*?onTriggered: \{([\s\S]*?)\n    \}/);
  assert.ok(eventBlock);
  vm.runInContext('function stepTriggered() {' + eventBlock[1] + '}', context);
  vm.runInContext('function connectedChanged() {' + handler('recoveryDeviceEvents', 'onConnectedChanged') + '}', context);
  vm.runInContext('function stateChanged() {' + handler('recoveryDeviceEvents', 'onStateChanged') + '}', context);
  const cancelExitBlock = source.match(/property Process recoveryCancelProcess: Process \{[\s\S]*?onExited: function\(exitCode\) \{([\s\S]*?)\n    \}/);
  assert.ok(cancelExitBlock);
  vm.runInContext('function cancelExited(exitCode) {' + cancelExitBlock[1] + '}', context);
  return { root, device, other, adapter, calls, process, cancelProcess, context };
}

{
  const h = harness();
  h.root.recoverDevice();
  assert.equal(h.calls.disconnect, 1, 'Only the clicked bonded mouse is disconnected');
  assert.equal(h.calls.otherDisconnect, 0);
  assert.equal(h.calls.scanStart, 0, 'Discovery waits for confirmed disconnection');
  assert.equal(h.root.observedBtAddress, targetAddress, 'Keep the captured selection');
  h.device.connected = false;
  h.context.connectedChanged();
  assert.equal(h.calls.scanStart, 1);
  assert.equal(h.root.recoveryStage, 'startingScan');
  h.root.handleRecoveryScanLine('[NEW] Device ' + targetAddress + ' MX Ergo');
  assert.equal(h.root.recoverySeenTarget, false, 'Initial cached objects are not fresh reports');
  h.root.handleRecoveryScanLine('Discovery started');
  assert.equal(h.root.recoveryStage, 'scanning');
  h.root.handleRecoveryScanLine('[NEW] Device ' + otherAddress + ' MX Ergo');
  assert.equal(h.root.recoveryOtherAddress, otherAddress);
  assert.equal(h.calls.otherConnect, 0, 'Other same-name records remain untouched');
  h.root.handleRecoveryScanLine('[CHG] Device ' + targetAddress + ' Connected: yes');
  assert.equal(h.root.recoverySeenTarget, false, 'A link property is not an advertisement');
  h.root.handleRecoveryScanLine('[CHG] Device ' + targetAddress + ' RSSI: -55');
  assert.equal(h.root.recoverySeenTarget, true);
  assert.equal(h.calls.connect, 1, 'Fresh target report initiates one connection');
  h.device.state = 0;
  h.context.stateChanged();
  assert.equal(h.root.recoveryResult, 'recovery_connect_failed');
  assert.equal(h.calls.scanStop, 1, 'Failure closes only the attempt-owned scanner');
  assert.equal(h.calls.otherConnect, 0);
}

{
  const h = harness(false);
  h.root.recoverDevice();
  assert.equal(h.calls.disconnect, 0, 'Disconnected bond is not disconnected again');
  h.root.handleRecoveryScanLine('Discovery started');
  h.context.stepTriggered();
  assert.equal(h.calls.connect, 1, 'Warm-up allows one connect without a client-visible report');
  assert.equal(h.root.recoverySeenTarget, false);
  h.device.connected = true;
  h.context.connectedChanged();
  assert.equal(h.root.recoveryResult, 'recovery_link_reported');
  assert.equal(h.calls.scanStop, 1);
}

{
  const h = harness();
  h.root.recoverDevice();
  h.context.stepTriggered();
  assert.equal(h.root.recoveryResult, 'recovery_disconnect_timeout');
  assert.equal(h.calls.scanStart, 0, 'A failed disconnect must not scan or connect');
  assert.equal(h.calls.connect, 0);
}

{
  const h = harness(false);
  h.root.recoverDevice();
  h.root.handleRecoveryScanLine('Failed to start discovery: org.bluez.Error.Failed');
  assert.equal(h.root.recoveryResult, 'recovery_scan_start_failed');
  assert.equal(h.calls.connect, 0);
  assert.equal(h.calls.scanStop, 1);
}

{
  const h = harness(false);
  h.root.recoverDevice();
  h.root.handleRecoveryScanLine('Discovery started');
  h.root.cancelRecovery();
  assert.equal(h.root.recoveryResult, 'recovery_cancelled');
  assert.equal(h.calls.connect, 0);
  assert.equal(h.calls.scanStop, 1);
}

{
  const h = harness(false);
  h.root.recoverDevice();
  h.root.handleRecoveryScanLine('Discovery started');
  h.context.stepTriggered();
  h.root.cancelRecovery();
  assert.equal(h.root.recoveryStage, 'cancellingConnect');
  assert.equal(h.root.recoveryResult, '', 'Cancellation is not reported before the pending Connect settles');
  assert.equal(h.calls.cancelStart, 1);
  assert.deepEqual(Array.from(h.cancelProcess.command),
    ['/usr/bin/bluetoothctl', '--timeout', '10', 'disconnect', targetAddress]);
  assert.equal(h.calls.scanStop, 1);
  h.device.state = 0;
  h.context.stateChanged();
  assert.equal(h.root.recoveryStage, 'cancellingConnect', 'Wait for target-only cancellation command');
  h.cancelProcess.running = false;
  h.context.cancelExited(0);
  assert.equal(h.root.recoveryResult, 'recovery_cancelled');
  assert.equal(h.calls.otherDisconnect, 0);
}

{
  const h = harness(false);
  h.root.recoverDevice();
  h.root.handleRecoveryScanLine('Discovery started');
  h.context.stepTriggered();
  h.context.stepTriggered();
  assert.equal(h.root.recoveryStage, 'cancellingConnect');
  assert.equal(h.root.recoveryResult, '', 'Connect timeout first cancels the BlueZ operation');
  h.cancelProcess.running = false;
  h.context.cancelExited(0);
  assert.equal(h.root.recoveryStage, 'cancellingConnect', 'A still-pending Quickshell call blocks another attempt');
  h.device.state = 0;
  h.context.stateChanged();
  assert.equal(h.root.recoveryResult, 'recovery_connect_timeout');
}

{
  const h = harness(false);
  h.root.recoverDevice();
  h.root.handleRecoveryScanLine('Discovery started');
  h.context.stepTriggered();
  h.root.cancelRecovery();
  h.cancelProcess.running = false;
  h.context.cancelExited(1);
  assert.equal(h.root.recoveryResult, 'recovery_cancel_unconfirmed');
  assert.equal(h.root.canStartRecovery, false, 'An unresolved Quickshell Connect blocks a fresh attempt');
}

{
  const h = harness(false);
  h.root.recoverDevice();
  h.root.handleRecoveryScanLine('Discovery started');
  h.context.stepTriggered();
  h.root.cancelRecovery();
  h.cancelProcess.running = false;
  h.context.cancelExited(0);
  h.context.stepTriggered();
  assert.equal(h.root.recoveryResult, 'recovery_cancel_unconfirmed', 'An unresolved Connect has a bounded outcome');
  assert.equal(h.root.canStartRecovery, false);
}

{
  const h = harness(false);
  h.root.recoverDevice();
  h.root.handleRecoveryScanLine('Discovery started');
  h.context.stepTriggered();
  h.device.connected = true;
  h.device.state = 1;
  h.root.cancelRecovery();
  assert.equal(h.calls.cancelStart, 1, 'A cancel click also covers a Connect completion race');
  h.device.connected = false;
  h.device.state = 0;
  h.cancelProcess.running = false;
  h.context.cancelExited(0);
  assert.equal(h.root.recoveryResult, 'recovery_cancelled');
}

{
  const h = harness(false);
  h.root.recoverDevice();
  h.root.handleRecoveryScanLine('Discovery started');
  h.context.stepTriggered();
  h.root.cancelRecovery();
  h.root.btDevice = h.other;
  h.cancelProcess.running = false;
  h.context.cancelExited(0);
  assert.equal(h.root.recoveryResult, 'recovery_cancel_unconfirmed', 'A replaced object cannot prove cancellation');
  assert.equal(h.calls.otherDisconnect, 0);
}

{
  const h = harness();
  h.device.bonded = false;
  h.root.recoverDevice();
  assert.equal(h.calls.disconnect, 0, 'Unbonded link cannot enter bonded recovery');
  h.device.bonded = true;
  h.root.btAdaptersList.push({ enabled: true, adapterId: 'hci1' });
  h.root.recoverDevice();
  assert.equal(h.calls.disconnect, 0, 'Ambiguous CLI adapter cannot enter recovery');
}

{
  const h = harness(false);
  h.root.scheduleStartupRecovery();
  assert.equal(h.context.startupRecoveryTimer.running, true);
  assert.equal(h.root.startupRecoveryDevice, h.device);
  h.root.startStartupRecovery();
  assert.equal(h.calls.scanStart, 1, 'Startup uses the owned bounded discovery path');
  assert.equal(h.calls.disconnect, 0, 'Startup must never disconnect a reported link');
  assert.equal(h.root.startupRecoveryAttempted, true);
  h.root.startStartupRecovery();
  assert.equal(h.calls.scanStart, 1, 'Only one startup attempt per model lifetime');
}

{
  const h = harness(true);
  h.root.scheduleStartupRecovery();
  h.root.startStartupRecovery();
  assert.equal(h.calls.scanStart, 0, 'Connected mouse is not touched at startup');
  assert.equal(h.calls.disconnect, 0);
}

{
  const h = harness(false);
  h.root.autoReconnect = false;
  h.root.scheduleStartupRecovery();
  h.root.startStartupRecovery();
  assert.equal(h.calls.scanStart, 0, 'Preference disables automatic startup discovery');
  h.root.autoReconnect = true;
  h.device.bonded = false;
  h.root.scheduleStartupRecovery();
  h.root.startStartupRecovery();
  assert.equal(h.calls.scanStart, 0, 'Incomplete bond is never auto-recovered');
  h.device.bonded = true;
  h.root.btAdaptersList.push({ enabled: true, adapterId: 'hci1' });
  h.root.scheduleStartupRecovery();
  h.root.startStartupRecovery();
  assert.equal(h.calls.scanStart, 0, 'Ambiguous default adapter blocks automatic scan');
}

{
  const h = harness(false);
  h.root.scheduleStartupRecovery();
  h.device.connected = true;
  h.root.startStartupRecovery();
  assert.equal(h.calls.disconnect, 0, 'Last-moment link cannot be disconnected by startup');
  assert.equal(h.calls.scanStart, 0);
}

{
  const h = harness(false);
  let reads = 0;
  Object.defineProperty(h.device, 'connected', { get() { return ++reads >= 3; } });
  h.root.recoverDevice(false);
  assert.equal(h.calls.disconnect, 0, 'A link appearing during startup admission is never disconnected');
  assert.equal(h.calls.scanStart, 0);
}

{
  const h = harness(false);
  h.root.scheduleStartupRecovery();
  h.root.btDevice = h.other;
  h.root.startStartupRecovery();
  assert.equal(h.calls.scanStart, 0, 'Startup does not follow a changed selection');
  assert.equal(h.calls.otherConnect, 0);
}

{
  const h = harness(false);
  h.root.scheduleStartupRecovery();
  h.root.recoverDevice();
  h.root.startStartupRecovery();
  assert.equal(h.calls.scanStart, 1, 'Manual recovery consumes the startup opportunity');
}

// A BlueZ link is deliberately not presented as verified pointer input.
const linkedExpr = source.match(/readonly property bool bleLinked: ([\s\S]*?)\n\n  readonly property string transport:/);
const statusExpr = source.match(/readonly property string connectionStatusText: \{([\s\S]*?)\n  \}/);
assert.ok(linkedExpr && statusExpr);
function connectionStatus(device, targetAddress = '') {
  const root = {
    btDevice: device, targetAddress, transport: '', bleLinked: false,
    t: key => key, transportText: 'Bluetooth'
  };
  root.bleLinked = vm.runInNewContext(linkedExpr[1], { btDevice: device });
  return {
    linked: root.bleLinked,
    text: vm.runInNewContext('(function(){' + statusExpr[1] + '\n})()', { root })
  };
}
assert.deepEqual(connectionStatus({ connected: true, paired: false, bonded: false }),
  { linked: true, text: 'status_pairing_incomplete' });
assert.deepEqual(connectionStatus({ connected: true, paired: true, bonded: true }),
  { linked: true, text: 'status_link_reported' });
assert.deepEqual(connectionStatus({ connected: false, paired: true, bonded: true }),
  { linked: false, text: 'status_bonded_disconnected' });
assert.deepEqual(connectionStatus(null, targetAddress),
  { linked: false, text: 'status_record_missing' });

console.log('PASS: Production recovery flow: target isolation, discovery, connect, failure, timeout, cancellation and admission.');
