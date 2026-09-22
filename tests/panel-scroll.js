const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

// Exercise the production cursor-to-viewport calculation, without a device model.
const source = fs.readFileSync(path.join(__dirname, '..', 'ErgoPanel.qml'), 'utf8');
const body = source.match(/function ensureCursorVisible\(\) \{([\s\S]*?)\n  \}/)[1];
const target = y => ({ height: 30, mapToItem: () => ({ y }) });
const context = {
  cursorActive: true, focusIndex: 0, editingButton: false,
  profileRow: target(100), sensitivityColumn: target(150),
  naturalRow: target(200), btnSelectorRow: target(500),
  viewport: { contentItem: {}, contentY: 300, contentHeight: 800, height: 360 },
};
vm.createContext(context);
const run = () => vm.runInContext(`(function () {${body}})()`, context);
run();
assert.equal(context.viewport.contentY, 100, 'scroll back to a control above the viewport');
context.focusIndex = 4;
run();
assert.equal(context.viewport.contentY, 170, 'show the full control below the viewport');
run();
assert.equal(context.viewport.contentY, 170, 'leave an already-visible control in place');
context.cursorActive = false;
context.viewport.contentY = 400;
run();
assert.equal(context.viewport.contentY, 400, 'pointer browsing must not force keyboard scrolling');
context.cursorActive = true;
context.viewport.contentHeight = 200;
run();
assert.equal(context.viewport.contentY, 0, 'short content must never scroll to a negative offset');
console.log('PASS: production panel cursor scrolling and viewport bounds.');
