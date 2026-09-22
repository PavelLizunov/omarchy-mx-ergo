const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '..', 'ErgoPanel.qml'), 'utf8');
const functionSource = name => source.match(new RegExp(`  function ${name}\\([^)]*\\) \\{[\\s\\S]*?\\n  \\}`))[0];
let resets = 0;
const calls = [];
const c = {
  panelPage: 'device', editingButton: false, selectedButton: 'back', cursorActive: false,
  forceActiveFocus() {}, languageCodes: ['system','en','zh','es','ru','pt','fr','de','ja','ko','it'], profileAction: {enabled:true},
  retrySettingsButton: {visible:false,enabled:true},
  isRecording: true, languageExpanded: true, buttonList: ['back','forward','middle','tiltLeft','tiltRight'].map(key => ({key})),
  model: {getButtonAction: () => 'custom_shortcut', getCustomShortcut: key => 'CTRL + ' + key,
    getCustomCommand: () => 'example command', setCustomShortcut: (...args) => calls.push(args)},
  shortcutInput: {text: ''}, cmdField: {text: ''},
  resetViewport: () => ++resets,
};
c.root = c;
vm.createContext(c);
for (const name of ['showPage','editButton','finishButtonEdit','syncActiveButton','addTokenToShortcut','stepFocus','collectEditorControls','handleActivate']) {
  vm.runInContext(functionSource(name), c);
}
c.editButton('forward');
assert.equal(c.panelPage, 'buttons');
assert.equal(c.editingButton, true);
assert.equal(c.selectedButton, 'forward');
assert.equal(c.setupMode, 'shortcut');
assert.equal(c.shortcutInput.text, 'CTRL + forward');
assert.equal(c.isRecording, false);
c.shortcutInput.text = 'ALT + F4';
c.addTokenToShortcut('SHIFT');
assert.equal(c.shortcutInput.text, 'SHIFT + ALT + F4');
assert.equal(calls.length, 0, 'editing a draft must not change the model');
c.showPage('pointer');
assert.equal(c.editingButton, false);
assert.equal(c.focusIndex, 0);
c.editButton('forward');
assert.equal(c.shortcutInput.text, 'CTRL + forward', 're-entry discards unapplied edits, even on the same button');
const before = resets;
c.showPage('invalid');
c.editButton('invalid');
assert.equal(resets, before);
assert.equal(c.selectedButton, 'forward');
assert.equal(calls.length, 0, 'page transitions must not apply assignments');
for (const [page, expected] of [['buttons',[-2,-1,4]],['pointer',[-2,-1,0,1,2,3]],['device',[-2,-1,5,6]]]) {
  c.showPage(page); c.focusIndex = -2;
  for (const next of [...expected.slice(1), expected[0]]) {
    c.stepFocus(1); assert.equal(c.focusIndex, next);
  }
  c.stepFocus(-1); assert.equal(c.focusIndex, expected.at(-1));
}
c.showPage('buttons'); c.languageExpanded=true; c.focusIndex=-2;
for (let index=0; index<11; index++) {c.stepFocus(1); assert.equal(c.focusIndex,10+index);}
let chosen=''; c.model.setLocale=code=>chosen=code;
c.focusIndex=14; c.handleActivate();
assert.equal(chosen,'ru'); assert.equal(c.languageExpanded,false); assert.equal(c.focusIndex,-2);
c.model.connected=false; c.model.canReconnect=true; c.focusIndex=-2; c.stepFocus(1);
assert.equal(c.focusIndex,-3,'Disconnected known trackball is keyboard reachable');
c.model.isConnecting=true; c.focusIndex=-2; c.stepFocus(1);
assert.equal(c.focusIndex,-1,'Skip busy connection');
c.model.canReconnect=false; c.model.isConnecting=false;
c.retrySettingsButton.visible=true; c.focusIndex=-2; c.stepFocus(1);
assert.equal(c.focusIndex,-4,'Failed settings can be retried from the keyboard');
c.retrySettingsButton.enabled=false; c.focusIndex=-2; c.stepFocus(1);
assert.equal(c.focusIndex,-1,'Skip busy retry');
c.retrySettingsButton.visible=false;
c.showPage('device'); c.profileAction.enabled=false; c.focusIndex=5; c.stepFocus(1);
assert.equal(c.focusIndex,-2,'Skip unavailable administrative action');
// Editor traversal must skip hidden/disabled branches and visit each visible control.
const control = () => ({visible:true,enabled:true,activeFocusOnTab:true,activeFocus:false,
  height:30,children:[],mapToItem:()=>({y:500}),forceActiveFocus(){c.focused=this;}});
const back = control(), apply = control(), disabled = control(), hidden = control();
disabled.enabled = false; hidden.visible = false;
c.editorBackButton = back;
c.contentColumn = {visible:true,enabled:true,children:[back,hidden,disabled,apply]};
c.viewport = {contentItem:{},contentY:0,contentHeight:700,height:300};
c.editingButton = true;
back.activeFocus = true;
c.stepFocus(1);
assert.equal(c.focused, apply);
assert.equal(c.viewport.contentY, 230);
back.activeFocus = false; apply.activeFocus = true;
c.stepFocus(1);
assert.equal(c.focused, back);
// Focus loss, clearing, and recording must not retain the old implicit-apply path.
assert.doesNotMatch(source, /onEditingFinished/);
assert.equal((source.match(/setCustomShortcut\(/g) || []).length, 2, 'only Enter and Apply persist shortcuts');
assert.equal((source.match(/setCustomCommand\(/g) || []).length, 2, 'only Enter and Apply persist commands');
// Execute the actual QML commit handlers: every explicit choice returns to the map,
// after the setter, preserving the selected physical key for continued navigation.
const commitHandlers = [...source.matchAll(/on(?:Clicked|Accepted): \{\s*(root\.model\.(?:setButtonAction|setCustomShortcut|setCustomCommand|resetButtonToDefault)\([\s\S]*?)\n\s*\}/g)];
assert.equal(commitHandlers.length, 6, 'preset, reset, and both Apply/Enter paths must be covered');
for (const [, handler] of commitHandlers) {
  const saved = [];
  for (const setter of ['setButtonAction','setCustomShortcut','setCustomCommand','resetButtonToDefault']) {
    c.model[setter] = (...args) => {
      assert.equal(c.editingButton, true, 'save before leaving the editor');
      saved.push({setter,args});
    };
  }
  c.editButton('tiltRight');
  c.isRecording = true;
  c.modelData = {id:'workspace_next'};
  c.text = 'CTRL + F2';
  c.shortcutInput.text = ' CTRL + F2 ';
  c.cmdField.text = 'example command';
  vm.runInContext(handler, c);
  assert.equal(saved.length, 1, 'one explicit choice writes once');
  assert.equal(saved[0].args[0], 'tiltRight');
  assert.equal(c.editingButton, false);
  assert.equal(c.panelPage, 'buttons');
  assert.equal(c.selectedButton, 'tiltRight', 'keep the edited button highlighted');
  assert.equal(c.focusIndex, 4, 'keyboard navigation resumes on the diagram');
  assert.equal(c.isRecording, false);
}
console.log('PASS: production page/editor navigation, draft isolation, focus and return after explicit choices.');
