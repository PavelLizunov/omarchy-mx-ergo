#!/usr/bin/env node

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const runtime = {};
vm.runInNewContext(fs.readFileSync(path.join(__dirname, '..', 'I18n.js'), 'utf8').replace(/^\.pragma library\s*/, ''), runtime);

const localesDir = path.join(__dirname, '..', 'locales');
const indexPath = path.join(localesDir, 'index.json');

assert.ok(fs.existsSync(indexPath), 'locales/index.json must exist');
const index = JSON.parse(fs.readFileSync(indexPath, 'utf8'));

const requiredLocales = ['en', 'ru', 'de', 'fr', 'es', 'it', 'pt', 'zh', 'ja', 'ko'];
for (const loc of requiredLocales) {
  assert.ok(index[loc], `Locale '${loc}' must be listed in index.json`);
  assert.ok(index[loc].file, `Locale '${loc}' must define a file`);
  const filePath = path.join(localesDir, index[loc].file);
  assert.ok(fs.existsSync(filePath), `Locale file '${index[loc].file}' must exist on disk`);
}

const enJson = JSON.parse(fs.readFileSync(path.join(localesDir, 'en.json'), 'utf8'));
const enKeys = Object.keys(enJson).sort();

assert.ok(enKeys.length >= 15, `Expected at least 15 translation keys, got ${enKeys.length}`);

for (const loc of requiredLocales) {
  const locFile = path.join(localesDir, index[loc].file);
  const locJson = JSON.parse(fs.readFileSync(locFile, 'utf8'));
  assert.deepEqual(Object.keys(locJson).sort(), enKeys, `Catalog key set differs: ${loc}`);
  assert.deepEqual(Object.keys(runtime.strings[loc]).sort(), enKeys, `Runtime key set differs: ${loc}`);
  for (const key of enKeys) {
    assert.equal(runtime.strings[loc][key], locJson[key], `Runtime/catalog mismatch: ${loc}.${key}`);
    assert.ok(locJson[key] !== undefined, `Locale '${loc}' is missing key '${key}'`);
    assert.ok(!/[\u0000\uFFFD]/.test(locJson[key]), `Invalid Unicode in ${loc}.${key}`);
    const sourceArgs = (enJson[key].match(/%[1-9][0-9]*/g) || []).sort();
    const targetArgs = (locJson[key].match(/%[1-9][0-9]*/g) || []).sort();
    assert.deepEqual(targetArgs, sourceArgs, `Substitution mismatch: ${loc}.${key}`);
    assert.ok(typeof locJson[key] === 'string' && locJson[key].trim().length > 0,
      `Locale '${loc}' has empty translation for key '${key}'`);
  }
}

console.log(`PASS: All ${requiredLocales.length} locales are complete (${enKeys.length} keys each).`);

// Static single-key lookups and declared label keys must not leak a missing key.
for (const file of fs.readdirSync(path.join(__dirname,'..')).filter(name=>/\.(qml|js)$/.test(name))) {
  const text = fs.readFileSync(path.join(__dirname,'..',file),'utf8');
  const lookups = [...text.matchAll(/\.t\(\s*["']([^"']+)["']\s*\)/g), ...text.matchAll(/labelKey:\s*["']([^"']+)["']/g)];
  for (const match of lookups) assert.ok(enJson[match[1]], `${file}: missing static key ${match[1]}`);
}
// Both profile messages use one first-occurrence .replace("%1", value) in QML.
for (const loc of requiredLocales) for (const key of ['profile_editing','profile_delete_confirm']) {
  assert.equal((runtime.t(key,loc).match(/%1/g)||[]).length,1);
  assert.ok(runtime.t(key,loc).replace('%1','Example profile').includes('Example profile'));
}
assert.equal(runtime.resolveLanguage('system','ru_RU'),'ru');
assert.equal(runtime.resolveLanguage('fr-CA','en'),'fr');
assert.equal(runtime.resolveLanguage('zh-TW','en'),'en','Traditional Chinese must not silently select Simplified Chinese');
assert.equal(runtime.resolveLanguage('unknown','en'),'en');
const frenchMethod=runtime.strings.fr.assignment_method;
delete runtime.strings.fr.assignment_method;
assert.equal(runtime.t('assignment_method','fr'),enJson.assignment_method,'Missing key uses source fallback');
runtime.strings.fr.assignment_method=frenchMethod;
for (const key of ['tab_presets','tab_shortcut','action_media_play_pause','action_workspace_prev','action_workspace_next','close_editor']) {
  assert.ok(!/[a-z]/i.test(runtime.t(key,'ru')), `English text leaked into Russian control ${key}`);
}
console.log('PASS: key sets, static lookups, positional substitutions, fallback and Russian action/control labels.');
