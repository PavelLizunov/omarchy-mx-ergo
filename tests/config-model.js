#!/usr/bin/env node
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.join(__dirname, '..', 'ErgoModel.qml'), 'utf8');
const Profiles = {};
vm.runInNewContext(fs.readFileSync(path.join(__dirname, '..', 'ButtonProfiles.js'), 'utf8').replace(/^\.pragma library\s*/, ''), Profiles);
const root = {sensitivity: 0, accelProfile: 'flat', naturalScroll: false, autoReconnect: true,
  configHelper: '/plugin path/config-store.py', configPath: '/tmp/config/mx-ergo.json', pendingConfig: '', configStored: false, configReadComplete: true, configWriting: false, buttonProfiles: [], activeProfileId: 'main', activeProfileName: 'Main', profileShortcut: ''};
for (const key of ['Back','Forward','Middle','TiltLeft','TiltRight']) {
  root['button'+key] = 'default'; root['buttonCustomShortcut'+key] = ''; root['buttonCustomCmd'+key] = '';
}
const writer = {running: false};
const later=[];
const context = vm.createContext({root, Profiles, configWriter: writer, configWriteStartCheck:{restart(){},stop(){}}, console:{warn(){}}, Qt:{callLater:fn=>later.push(fn)}, saveDebounce:{running:false}});
for (const name of ['getButtonAction', 'getCustomShortcut', 'getCustomCommand', 'captureButtonProfile', 'storeActiveProfile', 'saveConfig', 'drainConfigWrite', 'finishConfigWrite', 'retrySettings']) {
  vm.runInContext(source.match(new RegExp('^  function ' + name + '\\([^]*?^  \\}', 'm'))[0], context);
  root[name] = context[name];
}
assert.equal(root.configStored, false, 'No storage receipt before reading/writing preferences');
for (const name of ['configWriting', 'pendingConfig']) {
  Object.defineProperty(context, name, {get: () => root[name]});
}
const pendingBinding = source.match(/^  readonly property bool configPending: (.*)$/m)[1];
Object.defineProperty(root, 'configPending', {get: () => vm.runInContext(pendingBinding, context)});
assert.equal(root.configPending, false);
context.saveDebounce.running = true;
assert.equal(root.configPending, true, 'Debounce prevents a premature saved status');
context.saveDebounce.running = false;
root.saveConfig();
assert.equal(root.configStored, false, 'Starting a write is not confirmation');
assert.equal(writer.running, true);
assert.deepEqual(Array.from(writer.command.slice(0,5)), ['/usr/bin/python3','-I',root.configHelper,'write',root.configPath]);
assert.equal(JSON.parse(writer.command[5]).sensitivity, 0);
root.sensitivity = .25; root.saveConfig();
root.sensitivity = .75; root.saveConfig();
assert.equal(JSON.parse(writer.command[5]).sensitivity, 0, 'No overlapping writers');
assert.equal(JSON.parse(root.pendingConfig).sensitivity, .75, 'Only latest queued value retained');
assert.equal(root.configPending, true);
writer.running = false; root.finishConfigWrite(0);
assert.equal(root.configPending, true, 'Queued newer preferences keep old successful write from appearing settled');
later.splice(0).forEach(fn=>fn());
assert.equal(JSON.parse(writer.command[5]).sensitivity, .75);
assert.equal(root.pendingConfig, '');
writer.running = false; root.finishConfigWrite(0); later.splice(0).forEach(fn=>fn());
assert.equal(writer.running, false);
assert.equal(root.configStored, true, 'Successful write confirms storage');
assert.equal(root.configPending, false);
console.log('PASS: production preference serialization and single-writer latest-value queue.');

root.configLoadFailed=true; root.finishConfigWrite(1);
assert.equal(root.configSaveFailed,true);
assert.equal(root.configStored,false, 'Failed write cannot confirm storage');
assert.equal(root.configLoadFailed,true);
root.finishConfigWrite(0);
assert.equal(root.configSaveFailed,false);
assert.equal(root.configStored,true, 'Successful retry restores storage confirmation');
assert.equal(root.configLoadFailed,false);
