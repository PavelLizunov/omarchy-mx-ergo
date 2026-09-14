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

// Test 2: Discrete Battery Tier Contract (Hardware Truth)
function calculateBatteryTier(connected, btBattery, btAvailable, upPercentage, upPresent) {
  if (!connected) return "";
  let raw = -1;
  if (btAvailable && typeof btBattery === 'number' && btBattery >= 0) {
    raw = btBattery * 100;
  } else if (upPresent && typeof upPercentage === 'number' && upPercentage >= 0) {
    raw = upPercentage * 100;
  }
  if (raw < 0) return "";
  if (raw >= 80) return "full";
  if (raw >= 30) return "normal";
  if (raw >= 10) return "low";
  return "critical";
}

function calculateBatteryFraction(connected, tier) {
  if (!connected || tier === "") return null;
  if (tier === "full") return 1.0;
  if (tier === "normal") return 0.60;
  if (tier === "low") return 0.25;
  return 0.08;
}

function calculateTierText(connected, tier, lang) {
  if (!connected) return I18n.t('disconnected', lang);
  if (tier === "full") return I18n.t('battery_full', lang);
  if (tier === "normal") return I18n.t('battery_normal', lang);
  if (tier === "low") return I18n.t('battery_low', lang);
  if (tier === "critical") return I18n.t('battery_critical', lang);
  return I18n.t('battery_unknown', lang);
}

function calculateBarBatteryText(connected, tier) {
  if (!connected || tier === "") return "";
  if (tier === "full") return "Full";
  if (tier === "normal") return "Norm";
  if (tier === "low") return "Low";
  return "Crit";
}

// Disconnected device MUST return empty tier and null fraction, NEVER 0!
assert.equal(calculateBatteryTier(false, 1.0, true, 1.0, true), "");
assert.equal(calculateBatteryFraction(false, ""), null);
assert.equal(calculateTierText(false, "", 'ru'), 'Ожидание / Сон');
assert.equal(calculateTierText(false, "", 'en'), 'Disconnected / Sleep');
assert.equal(calculateBarBatteryText(false, ""), "");

// Full tier (100% or >= 80%)
const tierFull = calculateBatteryTier(true, 1.0, true, null, false);
assert.equal(tierFull, "full");
assert.equal(calculateBatteryFraction(true, tierFull), 1.0);
assert.equal(calculateTierText(true, tierFull, 'ru'), 'Заряжен (Full)');
assert.equal(calculateBarBatteryText(true, tierFull), 'Full');

// Normal tier (50% or 30-79%)
const tierNorm = calculateBatteryTier(true, 0.5, true, null, false);
assert.equal(tierNorm, "normal");
assert.equal(calculateBatteryFraction(true, tierNorm), 0.60);
assert.equal(calculateTierText(true, tierNorm, 'ru'), 'В норме (Normal)');
assert.equal(calculateBarBatteryText(true, tierNorm), 'Norm');

// Low tier (20% or 10-29%)
const tierLow = calculateBatteryTier(true, 0.2, true, null, false);
assert.equal(tierLow, "low");
assert.equal(calculateBatteryFraction(true, tierLow), 0.25);
assert.equal(calculateTierText(true, tierLow, 'ru'), 'Низкий (Low)');
assert.equal(calculateBarBatteryText(true, tierLow), 'Low');

// Critical tier (< 10%)
const tierCrit = calculateBatteryTier(true, 0.05, true, null, false);
assert.equal(tierCrit, "critical");
assert.equal(calculateBatteryFraction(true, tierCrit), 0.08);
assert.equal(calculateTierText(true, tierCrit, 'ru'), 'Критический (Critical)');
assert.equal(calculateBarBatteryText(true, tierCrit), 'Crit');

// Test 3: Hyprland Lua command formatting
function formatSensitivityCmd(deviceName, val) {
  const clamped = Math.max(-1.0, Math.min(1.0, Number(val)));
  return `hl.device({ name = "${deviceName}", sensitivity = ${clamped.toFixed(2)} })`;
}

function formatAccelProfileCmd(deviceName, profile) {
  const p = (profile === 'flat' || profile === 'adaptive') ? profile : 'adaptive';
  return `hl.device({ name = "${deviceName}", accel_profile = "${p}" })`;
}

function formatNaturalScrollCmd(deviceName, enabled) {
  return `hl.device({ name = "${deviceName}", natural_scroll = ${enabled ? 'true' : 'false'} })`;
}

const dev = 'logitech-mx-ergo-multi-device-trackball-';
assert.equal(formatSensitivityCmd(dev, 0.25), 'hl.device({ name = "logitech-mx-ergo-multi-device-trackball-", sensitivity = 0.25 })');
assert.equal(formatSensitivityCmd(dev, 5.0), 'hl.device({ name = "logitech-mx-ergo-multi-device-trackball-", sensitivity = 1.00 })');
assert.equal(formatSensitivityCmd(dev, -3.0), 'hl.device({ name = "logitech-mx-ergo-multi-device-trackball-", sensitivity = -1.00 })');

assert.equal(formatAccelProfileCmd(dev, 'flat'), 'hl.device({ name = "logitech-mx-ergo-multi-device-trackball-", accel_profile = "flat" })');
assert.equal(formatAccelProfileCmd(dev, 'invalid'), 'hl.device({ name = "logitech-mx-ergo-multi-device-trackball-", accel_profile = "adaptive" })');

assert.equal(formatNaturalScrollCmd(dev, true), 'hl.device({ name = "logitech-mx-ergo-multi-device-trackball-", natural_scroll = true })');
assert.equal(formatNaturalScrollCmd(dev, false), 'hl.device({ name = "logitech-mx-ergo-multi-device-trackball-", natural_scroll = false })');

console.log('PASS: Model contract tests passed successfully.');
