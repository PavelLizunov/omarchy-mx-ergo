#!/usr/bin/env node
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const directory = path.join(__dirname, '..');
const Profiles = {};
vm.runInNewContext(fs.readFileSync(path.join(directory, 'ButtonProfiles.js'), 'utf8').replace(/^\.pragma library\s*/, ''), Profiles);
const json = value => JSON.parse(JSON.stringify(value));

assert.equal(Profiles.shortcut(''), null);
assert.deepEqual(json(Profiles.shortcut('WIN + CONTROL + SHIFT + F12')), {key: 'F12', modmask: 69, keys: 'SUPER + CTRL + SHIFT + F12'});
assert.equal(Profiles.shortcut('ALT + PAGEUP').key, 'Prior');
for (const value of ['CTRL', 'CTRL + A + B', '$(id)', 'F25', 'mouse:275', 'A;id', 'CTRL + "']) {
  assert.throws(() => Profiles.shortcut(value), undefined, value);
}
const legacy = {buttons: {back: 'custom_command', forward: 'custom_shortcut', middle: 'mute',
  tiltLeft: 'workspace_prev', tiltRight: 'workspace_next'},
  customShortcuts: {forward: 'CTRL + "', back: ''}, customCommands: {back: 'printf "Привет"'}};
const migrated = Profiles.fromConfig(legacy, 'Основной');
assert.equal(migrated.profiles[0].name, 'Основной');
assert.equal(migrated.profiles[0].customCommands.back, legacy.customCommands.back);
assert.equal(migrated.profiles[0].customShortcuts.forward, legacy.customShortcuts.forward);
assert.deepEqual(json(migrated.profiles[0].buttons), legacy.buttons);
const independent = Profiles.profile('copy', 'Copy', migrated.profiles[0]);
independent.buttons.back = 'mute';
assert.equal(migrated.profiles[0].buttons.back, 'custom_command');

const source = fs.readFileSync(path.join(directory, 'ErgoModel.qml'), 'utf8');
function harness() {
  const root = {configReadComplete: true, configLoadFailed: false, configSaveFailed: false,
    buttonProfiles: [], activeProfileId: 'main', profileShortcut: '', profileTransaction: null,
    profileError: '', profileRetryId: '', profileLastSwitchAt: 0,
    sensitivity: 0, accelProfile: 'adaptive', naturalScroll: false, autoReconnect: true,
    hyprDeviceName: 'mx-test', configHome: '/test', configPath: '/test/mx-ergo.json',
    configHelper: '/plugin/config-store.py', settingsHelper: '/plugin/apply-settings.py',
    pendingSettingsRequest: null, settingsApplying: false, settingsGeneration: 0,
    pendingConfig: '', availableActions: ['default', 'mute', 'profile_next'], t: key => key};
  Object.defineProperties(root, {
    profileBusy: {get: () => root.profileTransaction !== null},
    activeProfileName: {get: () => Profiles.find(root.buttonProfiles, root.activeProfileId)?.name || 'Main'},
  });
  const later = new Set(), applier = {running: false}, writer = {running: false};
  const timer = () => ({running: false, restart(){this.running = true}, stop(){this.running = false}});
  const c = {root, Profiles, I18n: {t: key => key}, console: {info(){}, warn(){}},
    Qt: {callLater: fn => later.add(fn)}, settingsApplier: applier, configWriter: writer,
    settingsDeadline: timer(), settingsStartCheck: timer(), saveDebounce: timer(), applyDebounce: timer(),
    configWriteStartCheck: timer(), profileWheelLatch: timer()};
  // QML's unqualified properties use the root object, not a captured copy.
  for (const name of ['pendingSettingsRequest', 'settingsApplying', 'settingsGeneration', 'settingsCapturedGeneration',
    'settingsRecoveryFailed', 'settingsStopping', 'settingsExitCode', 'settingsOutput']) {
    Object.defineProperty(c, name, {get: () => root[name], set: value => root[name] = value});
  }
  vm.createContext(c);
  const names = ['getButtonAction', 'getCustomShortcut', 'getCustomCommand', 'captureButtonProfile',
    'storeActiveProfile', 'loadButtonProfile', 'loadProfileConfig', 'validProfileName', 'createProfile',
    'renameProfile', 'deleteProfile', 'selectProfile', 'nextProfile', 'nextProfileFromWheel', 'setProfileShortcut',
    'setProfileSwitchForAll', 'finishProfileApply', 'setButtonAction', 'setCustomShortcut', 'setCustomCommand',
    'resetButtonToDefault', 'shellQuote', 'shortcutToWtype', 'buildBindSnippet', 'buildSettingsRequest',
    'applyButtonBind', 'applyAllSettings', 'drainSettingsRequest', 'finishSettingsApply', 'saveConfig',
    'drainConfigWrite', 'finishConfigWrite', 'retrySettings'];
  for (const name of names) {
    const short = source.match(new RegExp('^  function ' + name + '\\([^\\n]+\\}\\s*$', 'm'));
    const block = source.match(new RegExp('^  function ' + name + '\\([^]*?^  \\}', 'm'));
    assert.ok(short || block, name);
    vm.runInContext((short || block)[0], c);
    root[name] = c[name];
  }
  const flush = () => {while (later.size) {const batch = [...later]; later.clear(); batch.forEach(fn => fn())}};
  const finish = (ok, error = '') => {
    applier.running = false; root.settingsExitCode = ok ? 0 : 1;
    root.settingsOutput = JSON.stringify({ok, error}); root.finishSettingsApply(); flush();
  };
  root.loadProfileConfig(legacy);
  return {root, c, applier, writer, flush, finish};
}

const h = harness(), {root: r, flush, finish} = h;
assert.equal(r.deleteProfile(), false, 'last profile retained');
assert.equal(r.createProfile(' '), false);
assert.equal(r.createProfile('Work'), true);
flush();
assert.equal(r.activeProfileId, 'main', 'no premature selection before verification');
const work = r.profileTransaction.toId;
assert.equal(r.setProfileShortcut('CTRL + F12'), false, 'busy guard');
r.setCustomCommand('back', 'should not write');
assert.equal(r.buttonCustomCmdBack, legacy.customCommands.back, 'busy edit guard');
finish(true);
assert.equal(r.activeProfileId, work);
r.setButtonAction('back', 'mute'); flush(); finish(true);
assert.equal(Profiles.find(r.buttonProfiles, 'main').buttons.back, 'custom_command');
assert.equal(Profiles.find(r.buttonProfiles, work).buttons.back, 'mute');
r.selectProfile('main'); flush(); finish(true);
assert.equal(r.buttonBack, 'custom_command');
assert.equal(r.buttonCustomCmdBack, legacy.customCommands.back);
r.saveConfig();
const saved = JSON.parse(h.writer.command[5]);
assert.equal(saved.version, 2);
assert.equal(saved.activeProfileId, 'main');
assert.equal(saved.profiles.length, 2);
const reload = harness(); reload.root.loadProfileConfig(saved);
assert.deepEqual(json(reload.root.buttonProfiles), saved.profiles);
assert.equal(reload.root.activeProfileId, saved.activeProfileId);

r.selectProfile(work); flush(); finish(false);
assert.equal(r.profileBusy, true, 'rollback is a bounded second transaction');
assert.equal(r.activeProfileId, 'main');
finish(true);
assert.equal(r.profileBusy, false);
assert.equal(r.profileError, 'profile_switch_restored');
assert.equal(r.profileRetryId, work);
r.retrySettings(); flush(); finish(true);
assert.equal(r.activeProfileId, work);
assert.equal(r.profileRetryId, '');
r.selectProfile('main'); flush(); finish(false); finish(false);
assert.equal(r.activeProfileId, work);
assert.equal(r.profileError, 'profile_rollback_failed');
assert.equal(r.settingsRecoveryFailed, true);
assert.equal(h.applier.running, false, 'no unbounded retries after rollback failure');

r.setProfileShortcut('CTRL + SHIFT + F12'); flush();
assert.equal(r.profileShortcut, '');
assert.equal(JSON.parse(h.applier.command[3]).profileShortcut.keys, 'CTRL + SHIFT + F12');
finish(true);
assert.equal(r.profileShortcut, 'CTRL + SHIFT + F12');
r.setProfileShortcut('CTRL + F11'); flush(); finish(false, 'shortcut_conflict'); finish(true);
assert.equal(r.profileShortcut, 'CTRL + SHIFT + F12');
assert.equal(r.profileError, 'profile_shortcut_conflict');
assert.equal(r.setProfileShortcut('CTRL + A + B'), false);
r.setProfileShortcut(''); flush(); finish(true); assert.equal(r.profileShortcut, '');

r.setProfileSwitchForAll('tiltLeft'); flush(); finish(true);
assert.ok(r.buttonProfiles.every(p => p.buttons.tiltLeft === 'profile_next'));
const request = r.buildSettingsRequest();
assert.equal(request.expected.mouse_left.release, false, 'axis events have no release');
assert.equal(request.expected['mouse:278'].release, true);
assert.ok(request.lua.includes('nextProfileFromWheel'));
assert.ok(request.lua.includes('release = true'));
r.profileLastSwitchAt = 0;
assert.equal(r.nextProfileFromWheel(), true); flush(); finish(true);
assert.equal(r.nextProfileFromWheel(), false, 'held wheel pulse must not switch twice');
r.profileLastSwitchAt = 0;
assert.equal(r.nextProfile(), false, 'physical tilt alias must not switch again during the wheel latch');
h.c.profileWheelLatch.stop(); r.profileLastSwitchAt = 0;
assert.equal(r.nextProfile(), true); flush(); finish(true);
assert.equal(r.nextProfile(), false, 'duplicate alias/cooldown');

const count = r.buttonProfiles.length;
r.deleteProfile(); flush(); finish(false); finish(true);
assert.equal(r.buttonProfiles.length, count, 'failed neighbor application must not delete active profile');
r.deleteProfile(); flush(); finish(true);
assert.equal(r.buttonProfiles.length, count - 1);
assert.equal(r.deleteProfile(), false);

const queued = harness();
queued.root.applyAllSettings(); queued.flush();
queued.root.createProfile('Queued'); queued.flush();
const target = queued.root.profileTransaction.toId;
queued.finish(true);
assert.equal(queued.root.activeProfileId, 'main', 'stale helper cannot commit new transaction');
assert.equal(queued.applier.running, true);
queued.finish(true);
assert.equal(queued.root.activeProfileId, target);

const guarded = harness();
guarded.root.configLoadFailed = true; guarded.root.saveConfig();
assert.equal(guarded.writer.running, false, 'corrupt preferences are never overwritten');
guarded.root.configReadComplete = false;
assert.equal(guarded.root.createProfile('Early'), false);
assert.equal(guarded.root.setProfileShortcut('F12'), false);
console.log('PASS: production profile migration, isolation, transactions, rollback, queue, persistence, wheel latch and shortcut parsing.');
