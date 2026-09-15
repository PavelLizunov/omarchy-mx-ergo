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

// Test 2: Discrete 3-Segment Battery Contract (hardware truth)
function calculateBatteryTier(connected, driverCapacity, driverFound, btBattery, btAvailable, upPercentage, upPresent, upIcon) {
  if (!connected) return "";

  if (driverFound && driverCapacity) {
    const c = String(driverCapacity).toLowerCase();
    if (c === "full") return "full";
    if (c === "normal" || c === "high") return "normal";
    if (c === "low") return "low";
    if (c === "critical") return "critical";
  }

  if (upPresent && upIcon) {
    const icon = String(upIcon).toLowerCase();
    if (icon.includes("full")) return "full";
    if (icon.includes("good")) return "normal";
    if (icon.includes("low")) return "low";
    if (icon.includes("caution") || icon.includes("empty")) return "critical";
  }

  let raw = -1;
  if (upPresent && typeof upPercentage === 'number' && upPercentage >= 0) {
    raw = upPercentage * 100;
  } else if (btAvailable && typeof btBattery === 'number' && btBattery >= 0) {
    raw = btBattery * 100;
  }
  if (raw < 0) return "";
  if (raw >= 80) return "full";
  if (raw >= 30) return "normal";
  if (raw >= 10) return "low";
  return "critical";
}

function calculateBatterySegments(connected, tier) {
  if (!connected || tier === "") return null;
  if (tier === "full") return 3;
  if (tier === "normal") return 2;
  if (tier === "low") return 1;
  return 0;
}

function calculateBatteryFraction(connected, tier) {
  const segs = calculateBatterySegments(connected, tier);
  return segs === null ? null : segs / 3.0;
}

function calculateTierText(connected, isCharging, tier, lang) {
  if (!connected) return I18n.t('disconnected', lang);
  if (isCharging) return I18n.t('battery_charging', lang) + " (3/3)";
  const segs = calculateBatterySegments(connected, tier);
  if (segs === 0) return "! 0/3";
  return segs + "/3";
}

function calculateBarBatteryText(connected, isCharging, tier) {
  if (!connected || tier === "") return "";
  if (isCharging) return "󰂄";
  const segs = calculateBatterySegments(connected, tier);
  if (segs === 3) return "●●●";
  if (segs === 2) return "●●○";
  if (segs === 1) return "●○○";
  return "○○○";
}

// Disconnected device MUST return empty tier and null fraction, NEVER 0!
assert.equal(calculateBatteryTier(false, "Full", true, 1.0, true, 1.0, true, "battery-full"), "");
assert.equal(calculateBatteryFraction(false, ""), null);
assert.equal(calculateTierText(false, false, "", 'ru'), 'Ожидание / Сон');
assert.equal(calculateTierText(false, false, "", 'en'), 'Disconnected / Sleep');
assert.equal(calculateBarBatteryText(false, false, ""), "");

// Full tier (3/3 segments, ●●●)
const tierFull = calculateBatteryTier(true, "Full", true, null, false, null, false, "");
assert.equal(tierFull, "full");
assert.equal(calculateBatterySegments(true, tierFull), 3);
assert.equal(calculateBatteryFraction(true, tierFull), 1.0);
assert.equal(calculateTierText(true, false, tierFull, 'ru'), '3/3');
assert.equal(calculateBarBatteryText(true, false, tierFull), '●●●');

// Normal tier (2/3 segments, ●●○)
const tierNorm = calculateBatteryTier(true, "Normal", true, null, false, null, false, "");
assert.equal(tierNorm, "normal");
assert.equal(calculateBatterySegments(true, tierNorm), 2);
assert.equal(calculateBatteryFraction(true, tierNorm), 2 / 3);
assert.equal(calculateTierText(true, false, tierNorm, 'ru'), '2/3');
assert.equal(calculateBarBatteryText(true, false, tierNorm), '●●○');

// Low tier (1/3 segments, ●○○)
const tierLow = calculateBatteryTier(true, "Low", true, null, false, null, false, "");
assert.equal(tierLow, "low");
assert.equal(calculateBatterySegments(true, tierLow), 1);
assert.equal(calculateBatteryFraction(true, tierLow), 1 / 3);
assert.equal(calculateTierText(true, false, tierLow, 'ru'), '1/3');
assert.equal(calculateBarBatteryText(true, false, tierLow), '●○○');

// Critical tier (0/3 segments, ○○○)
const tierCrit = calculateBatteryTier(true, "Critical", true, null, false, null, false, "");
assert.equal(tierCrit, "critical");
assert.equal(calculateBatterySegments(true, tierCrit), 0);
assert.equal(calculateBatteryFraction(true, tierCrit), 0.0);
assert.equal(calculateTierText(true, false, tierCrit, 'ru'), '! 0/3');
assert.equal(calculateBarBatteryText(true, false, tierCrit), '○○○');

// Charging state
assert.equal(calculateTierText(true, true, tierNorm, 'ru'), 'Заряжается (3/3)');
assert.equal(calculateTierText(true, true, tierNorm, 'en'), 'Charging (3/3)');
assert.equal(calculateBarBatteryText(true, true, tierNorm), '󰂄');

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

function shortcutToWtype(shortcutStr) {
  if (!shortcutStr) return "";
  var raw = String(shortcutStr).replace(/,/g, " ").replace(/\+/g, " ");
  var tokens = raw.trim().split(/\s+/);
  if (tokens.length === 0) return "";
  var mods = [];
  var releaseMods = [];
  var keys = [];
  for (var i = 0; i < tokens.length; i++) {
    var t = tokens[i].toUpperCase();
    if (t === "CTRL" || t === "CONTROL") {
      mods.push("-M ctrl");
      releaseMods.unshift("-m ctrl");
    } else if (t === "SHIFT") {
      mods.push("-M shift");
      releaseMods.unshift("-m shift");
    } else if (t === "ALT") {
      mods.push("-M alt");
      releaseMods.unshift("-m alt");
    } else if (t === "SUPER" || t === "WIN" || t === "LOGO" || t === "META") {
      mods.push("-M logo");
      releaseMods.unshift("-m logo");
    } else {
      keys.push(tokens[i]);
    }
  }
  var cmd = "wtype -s 25 -d 20";
  for (var m = 0; m < mods.length; m++) cmd += " " + mods[m];
  for (var k = 0; k < keys.length; k++) {
    var key = keys[k];
    var uKey = key.toUpperCase();
    if (key.length === 1) {
      cmd += " -k " + key.toLowerCase();
    } else if (uKey === "SPACE") {
      cmd += " -k space";
    } else if (uKey === "ENTER" || uKey === "RETURN") {
      cmd += " -k Return";
    } else if (uKey === "TAB") {
      cmd += " -k Tab";
    } else if (uKey === "ESCAPE" || uKey === "ESC") {
      cmd += " -k Escape";
    } else if (uKey === "BACKSPACE") {
      cmd += " -k BackSpace";
    } else if (uKey === "DELETE" || uKey === "DEL") {
      cmd += " -k Delete";
    } else if (uKey === "INSERT" || uKey === "INS") {
      cmd += " -k Insert";
    } else if (uKey === "HOME") {
      cmd += " -k Home";
    } else if (uKey === "END") {
      cmd += " -k End";
    } else if (uKey === "PAGEUP" || uKey === "PGUP" || uKey === "PAGE_UP" || uKey === "PRIOR") {
      cmd += " -k Prior";
    } else if (uKey === "PAGEDOWN" || uKey === "PGDN" || uKey === "PAGE_DOWN" || uKey === "NEXT") {
      cmd += " -k Next";
    } else if (uKey === "LEFT") {
      cmd += " -k Left";
    } else if (uKey === "RIGHT") {
      cmd += " -k Right";
    } else if (uKey === "UP") {
      cmd += " -k Up";
    } else if (uKey === "DOWN") {
      cmd += " -k Down";
    } else if (uKey === "PRINT" || uKey === "PRINTSCREEN") {
      cmd += " -k Print";
    } else if (uKey === "PAUSE") {
      cmd += " -k Pause";
    } else if (uKey === "MENU") {
      cmd += " -k Menu";
    } else {
      cmd += " -k " + key;
    }
  }
  for (var r = 0; r < releaseMods.length; r++) cmd += " " + releaseMods[r];
  return cmd;
}

assert.equal(shortcutToWtype("CTRL + C"), "wtype -s 25 -d 20 -M ctrl -k c -m ctrl");
assert.equal(shortcutToWtype("CTRL + SHIFT + T"), "wtype -s 25 -d 20 -M ctrl -M shift -k t -m shift -m ctrl");
assert.equal(shortcutToWtype("SUPER + Return"), "wtype -s 25 -d 20 -M logo -k Return -m logo");
assert.equal(shortcutToWtype("ALT + F4"), "wtype -s 25 -d 20 -M alt -k F4 -m alt");
assert.equal(shortcutToWtype("Super P+8"), "wtype -s 25 -d 20 -M logo -k p -k 8 -m logo");
assert.equal(shortcutToWtype("CTRL + INSERT"), "wtype -s 25 -d 20 -M ctrl -k Insert -m ctrl");
assert.equal(shortcutToWtype("SHIFT + PAGEUP"), "wtype -s 25 -d 20 -M shift -k Prior -m shift");

// Test 4: Button bind Lua formatting (including dual tilt bindings and custom shortcuts)
function buildBindSnippet(code, action, param = "") {
  let lua = `pcall(function() hl.unbind("${code}") end)\n`;
  if (action === "default") {
    return lua;
  } else if (action === "workspace_next") {
    lua += `o.bind("${code}", "MX Ergo: Next Workspace", hl.dsp.focus({ workspace = "e+1" }))\n`;
  } else if (action === "workspace_prev") {
    lua += `o.bind("${code}", "MX Ergo: Prev Workspace", hl.dsp.focus({ workspace = "e-1" }))\n`;
  } else if (action === "window_close") {
    lua += `o.bind("${code}", "MX Ergo: Close Window", hl.dsp.window.close())\n`;
  } else if (action === "window_float") {
    lua += `o.bind("${code}", "MX Ergo: Toggle Floating", hl.dsp.window.float({ action = "toggle" }))\n`;
  } else if (action === "window_fullscreen") {
    lua += `o.bind("${code}", "MX Ergo: Fullscreen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))\n`;
  } else if (action === "window_next") {
    lua += `o.bind("${code}", "MX Ergo: Next Window", hl.dsp.window.cycle_next())\n`;
  } else if (action === "overview") {
    lua += `o.bind("${code}", "MX Ergo: Overview", "omarchy-shell moorgrove.overview toggle")\n`;
  } else if (action === "screenshot") {
    lua += `o.bind("${code}", "MX Ergo: Screenshot", "omarchy-capture-screenshot")\n`;
  } else if (action === "media_play_pause") {
    lua += `o.bind("${code}", "MX Ergo: Play/Pause", "playerctl play-pause")\n`;
  } else if (action === "media_next") {
    lua += `o.bind("${code}", "MX Ergo: Next Track", "playerctl next")\n`;
  } else if (action === "media_prev") {
    lua += `o.bind("${code}", "MX Ergo: Prev Track", "playerctl previous")\n`;
  } else if (action === "mute") {
    lua += `o.bind("${code}", "MX Ergo: Toggle Mute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")\n`;
  } else if (action === "tab_next") {
    lua += `o.bind("${code}", "MX Ergo: Next Tab", "wtype -M ctrl -k Tab")\n`;
  } else if (action === "tab_prev") {
    lua += `o.bind("${code}", "MX Ergo: Prev Tab", "wtype -M ctrl -M shift -k Tab")\n`;
  } else if (action === "browser_back") {
    lua += `o.bind("${code}", "MX Ergo: Browser Back", "wtype -M alt -k Left")\n`;
  } else if (action === "browser_forward") {
    lua += `o.bind("${code}", "MX Ergo: Browser Forward", "wtype -M alt -k Right")\n`;
  } else if (action === "custom_shortcut" && param) {
    const norm = String(param).toUpperCase().replace(/,/g, " ").replace(/\+/g, " ").trim().replace(/\s+/g, " ");
    const wsMatch = norm.match(/^(SUPER|WIN|LOGO)\s+([0-9]+)$/);
    if (wsMatch) {
      lua += "o.bind(" + JSON.stringify(code) + ", " + JSON.stringify("MX Ergo: Workspace " + wsMatch[2]) + ", hl.dsp.focus({ workspace = \"" + wsMatch[2] + "\" }))\n";
    } else if (norm === "SUPER CTRL TAB" || norm === "SUPER CONTROL TAB" || norm === "WIN CTRL TAB" || norm === "WIN CONTROL TAB") {
      lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Former Workspace\", hl.dsp.focus({ workspace = \"previous\" }))\n";
    } else if (norm === "SUPER SHIFT TAB" || norm === "WIN SHIFT TAB") {
      lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Prev Workspace\", hl.dsp.focus({ workspace = \"e-1\" }))\n";
    } else if (norm === "SUPER TAB" || norm === "WIN TAB") {
      lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Next Workspace\", hl.dsp.focus({ workspace = \"e+1\" }))\n";
    } else if (norm === "SUPER W" || norm === "SUPER Q" || norm === "WIN W" || norm === "WIN Q") {
      lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Close Window\", hl.dsp.window.close())\n";
    } else if (norm === "SUPER F" || norm === "WIN F") {
      lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Fullscreen\", hl.dsp.window.fullscreen({ mode = \"fullscreen\" }))\n";
    } else if (norm === "SUPER T" || norm === "WIN T") {
      lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Toggle Float\", hl.dsp.window.float({ action = \"toggle\" }))\n";
    } else if (norm === "SUPER SPACE" || norm === "WIN SPACE") {
      lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Menu\", \"omarchy-menu toggle\")\n";
    } else if (norm === "SUPER S" || norm === "WIN S") {
      lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Scratchpad\", hl.dsp.workspace.toggle_special(\"scratchpad\"))\n";
    } else if (norm === "INSERT" || norm === "INS") {
      lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Voxtype Dictation\", \"voxtype record toggle\")\n";
    } else if (norm === "SUPER INSERT" || norm === "WIN INSERT") {
      lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Voice Agent\", \"omarchy-voice-agent toggle || omarchy-voice-agent start\")\n";
    } else if (norm === "SUPER ALT A" || norm === "WIN ALT A") {
      lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: TTS Clipboard\", \"/home/slovn/.config/omarchy/plugins/io.github.hikari112.tts/bin/speak --clipboard\")\n";
    } else if (norm === "SUPER ALT E" || norm === "WIN ALT E") {
      lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: TTS Selection\", \"/home/slovn/.config/omarchy/plugins/io.github.hikari112.tts/bin/speak --toggle\")\n";
    } else if (norm === "SUPER ALT X" || norm === "WIN ALT X") {
      lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: TTS Stop\", \"/home/slovn/.config/omarchy/plugins/io.github.hikari112.tts/bin/speak --stop\")\n";
    } else {
      const wcmd = shortcutToWtype(param);
      if (wcmd !== "") {
        lua += "o.bind(" + JSON.stringify(code) + ", " + JSON.stringify("MX Ergo: " + param) + ", " + JSON.stringify(wcmd) + ")\n";
      }
    }
  } else if (action === "custom_command" && param) {
    lua += "o.bind(" + JSON.stringify(code) + ", \"MX Ergo: Command\", " + JSON.stringify(param) + ")\n";
  }
  return lua;
}

function formatButtonBindLua(btnKey, action, param = "") {
  let lua = "";
  if (btnKey === "tiltLeft") {
    lua += buildBindSnippet("mouse_left", action, param);
    lua += buildBindSnippet("mouse:278", action, param);
  } else if (btnKey === "tiltRight") {
    lua += buildBindSnippet("mouse_right", action, param);
    lua += buildBindSnippet("mouse:279", action, param);
  } else {
    const codes = { "back": "mouse:275", "forward": "mouse:276", "middle": "mouse:274" };
    const code = codes[btnKey];
    if (code) lua += buildBindSnippet(code, action, param);
  }
  return lua;
}

const backLua = formatButtonBindLua("back", "workspace_next");
assert.ok(backLua.includes('hl.unbind("mouse:275")'));
assert.ok(backLua.includes('o.bind("mouse:275"'));
assert.ok(backLua.includes('hl.dsp.focus'));

const defLua = formatButtonBindLua("forward", "default");
assert.ok(defLua.includes('hl.unbind("mouse:276")'));
assert.ok(!defLua.includes('o.bind'));

// Tilt Left binds BOTH mouse_left (REL_HWHEEL) and mouse:278 (discrete)
const tiltLLua = formatButtonBindLua("tiltLeft", "workspace_prev");
assert.ok(tiltLLua.includes('hl.unbind("mouse_left")'));
assert.ok(tiltLLua.includes('hl.unbind("mouse:278")'));
assert.ok(tiltLLua.includes('o.bind("mouse_left"'));
assert.ok(tiltLLua.includes('o.bind("mouse:278"'));

// Tilt Right binds BOTH mouse_right and mouse:279
const tiltRLua = formatButtonBindLua("tiltRight", "window_fullscreen");
assert.ok(tiltRLua.includes('hl.unbind("mouse_right")'));
assert.ok(tiltRLua.includes('hl.unbind("mouse:279")'));
assert.ok(tiltRLua.includes('o.bind("mouse_right"'));
assert.ok(tiltRLua.includes('o.bind("mouse:279"'));
assert.ok(tiltRLua.includes('fullscreen'));

// Custom recorded shortcut test
const customScLua = formatButtonBindLua("middle", "custom_shortcut", "CTRL + SHIFT + T");
assert.ok(customScLua.includes('o.bind("mouse:274"'));
assert.ok(customScLua.includes('wtype -s 25 -d 20 -M ctrl -M shift -k t'));

// Custom workspace shortcut (e.g. SUPER + 8)
const wsLua = formatButtonBindLua("back", "custom_shortcut", "SUPER + 8");
assert.ok(wsLua.includes('hl.dsp.focus({ workspace = "8" })'));

// Custom former workspace shortcut (SUPER + CTRL + Tab)
const formerWsLua = formatButtonBindLua("tiltLeft", "custom_shortcut", "SUPER + CTRL + Tab");
assert.ok(formerWsLua.includes('hl.dsp.focus({ workspace = "previous" })'));

// Custom Voxtype dictation shortcut test (Insert)
const insertLua = formatButtonBindLua("forward", "custom_shortcut", "Insert");
assert.ok(insertLua.includes('voxtype record toggle'));

// Custom TTS speak clipboard test (SUPER + ALT + A)
const ttsLua = formatButtonBindLua("back", "custom_shortcut", "SUPER + ALT + A");
assert.ok(ttsLua.includes('speak --clipboard'));

// Custom multi-key combo test (e.g. Super P+8)
const p8Lua = formatButtonBindLua("forward", "custom_shortcut", "Super P+8");
assert.ok(p8Lua.includes('wtype -s 25 -d 20 -M logo -k p -k 8'));

// Custom command test
const customCmdLua = formatButtonBindLua("middle", "custom_command", "alacritty -e btop");
assert.ok(customCmdLua.includes('o.bind("mouse:274"'));
assert.ok(customCmdLua.includes('alacritty -e btop'));

// Test 5: MAC address validation
function isValidMac(addr) {
  return /^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/.test(addr);
}

assert.equal(isValidMac("C2:B5:BB:BB:64:FF"), true);
assert.equal(isValidMac("c2:b5:bb:bb:64:ff"), true);
assert.equal(isValidMac("046D:B01D"), false);
assert.equal(isValidMac("C2:B5:BB:BB:64:FF; rm -rf /"), false);

// Test 6: Low Latency & High Polling Rate Setup
assert.equal(I18n.t('polling_rate', 'ru'), 'Плавность курсора');
assert.equal(I18n.t('rate_low_latency', 'ru'), '125 Гц (7.5–11 мс)');
assert.equal(I18n.t('enable_low_latency', 'ru'), 'Включить 125 Гц');
assert.equal(I18n.t('revert_low_latency', 'ru'), 'Вернуть стандарт');
const scriptFile = path.join(__dirname, '..', 'scripts', 'low-latency.sh');
assert.ok(fs.existsSync(scriptFile), 'scripts/low-latency.sh must exist');
const stats = fs.statSync(scriptFile);
assert.ok((stats.mode & 0o111) !== 0, 'scripts/low-latency.sh must be executable');
const scriptContent = fs.readFileSync(scriptFile, 'utf8');
assert.ok(scriptContent.includes('--disable'), 'scripts/low-latency.sh must support rollback via --disable');

console.log('PASS: Model contract tests passed successfully.');
