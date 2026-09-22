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
  for (const key of enKeys) {
    assert.equal(runtime.strings[loc][key], locJson[key], `Runtime/catalog mismatch: ${loc}.${key}`);
    assert.ok(locJson[key] !== undefined, `Locale '${loc}' is missing key '${key}'`);
    assert.ok(typeof locJson[key] === 'string' && locJson[key].trim().length > 0,
      `Locale '${loc}' has empty translation for key '${key}'`);
  }
}

console.log(`PASS: All ${requiredLocales.length} locales are complete (${enKeys.length} keys each).`);
