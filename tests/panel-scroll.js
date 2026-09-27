const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

// Exercise the production cursor-to-viewport calculation, without a device model.
const source = fs.readFileSync(path.join(__dirname, '..', 'ErgoPanel.qml'), 'utf8');
const body = source.match(/function ensureCursorVisible\(\) \{([\s\S]*?)\n  \}/)[1];
const target = y => ({ height: 30, mapToItem: () => ({ y }) });
const context = {
  cursorActive: true, focusIndex: 7, editingButton: false,
  profilesSection: target(100), profileRow: target(100), sensitivityColumn: target(150),
  naturalRow: target(200), btnSelectorRow: target(500),
  viewport: { contentItem: {}, contentY: 300, contentHeight: 800, height: 360 },
};
context.root = context;
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
context.settingsViewport = {contentItem:{},contentY:200,contentHeight:500,height:100};
context.focusIndex=2;context.cursorActive=true;context.viewport.contentY=17;
run();assert.equal(context.settingsViewport.contentY,150);assert.equal(context.viewport.contentY,17);
console.log('PASS: production cursor scrolling targets the correct column and respects bounds.');

// Use the actual host positioning body, not a copied formula. Constant consumer
// width must yield the same origin even when host fitting/clamping is active.
const host = fs.readFileSync('/usr/share/omarchy/shell/Ui/KeyboardPanel.qml', 'utf8');
const preferred = source.match(/^  readonly property real preferredWidth: (.+)$/m)[1];
const origin = host.match(/readonly property point cardOrigin: (\{[^]*?^  \})/m)[1];
const preferredHeight = source.match(/^  readonly property real contentHeight: (.+)$/m)[1];
const fittingHeight = host.match(/function fittedContentHeight\(implicitHeight, cap\) \{[^]*?^  \}/m)[0];
const fitting = host.match(/function fittedContentWidth\(width, cap\) \{[^]*?^  \}/m)[0];
function consumerWidth(editingButton, panelPage = 'buttons') {
  return vm.runInNewContext(preferred, {root:{editingButton,panelPage}, Style:{space:x=>x}});
}
assert.equal(consumerWidth(false), consumerWidth(true), 'Editor does not change requested card width');
assert.equal(consumerWidth(false,'pointer'),736);
assert.equal(consumerWidth(false,'device'),736);
for (const screenW of [620,1536]) for (const barPos of ['top','bottom','left','right']) {
  for (const anchorX of [0,screenW/2,screenW-20]) for (const centerOnBar of [false,true]) {
    const geometry = {anchorItem:{}, bar:{}, margin:12, gap:8, screenW, screenH:864,
      barW:['left','right'].includes(barPos)?26:screenW, barH:['top','bottom'].includes(barPos)?26:864,
      barPos, centerOnBar, anchorScreenPos:{x:anchorX,y:420}, anchorW:20, anchorH:20,
      verticalContentInset:64, availableCardHeight:768, availableCardWidth:screenW-48, Qt:{point:(x,y)=>({x,y})}};
    geometry.root=geometry;
    const ctx=vm.createContext(geometry);
    vm.runInContext(fitting,ctx);
    vm.runInContext(fittingHeight,ctx);
    const positions=["buttons", "pointer", "device", "editing", "closed"].map(page=>{
      ctx.contentWidth=ctx.fittedContentWidth(consumerWidth(page === "editing",page === "editing" || page === "closed" ? "buttons" : page));
      const height=vm.runInNewContext(preferredHeight,{Style:{space:x=>x}});
      ctx.contentHeight=ctx.fittedContentHeight(height,ctx.availableCardHeight*0.95);
      const point=vm.runInContext('(function() '+origin+')()',ctx);
      return [point.x,point.y];
    });
    for (const position of positions) assert.deepEqual(positions[0],position,screenW+' '+barPos+' '+anchorX);
  }
}
console.log('PASS: real host origin stays stable across all pages and editor open/close across edges, fitting and four bar positions.');
