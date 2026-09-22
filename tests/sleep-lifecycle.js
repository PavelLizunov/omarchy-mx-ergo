const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');
const source=fs.readFileSync(path.join(__dirname,'..','ErgoModel.qml'),'utf8');
const timer=()=>({stops:0,restarts:0,stop(){this.stops++},restart(){this.restarts++}});
const root={sleeping:false,shuttingDown:false,autoReconnect:true,settingsConfigured:true,sleepMonitorRestarts:0,applies:0,applyAllSettings(){this.applies++}};
const signals=[];
const c={root,wakeReconnectTimer:timer(),wakeStage2Timer:timer(),sleepRetry:timer(),sleepMonitor:{running:false},sleepStartCheck:timer(),settingsApplier:{running:true,signal:n=>signals.push(n)}};
vm.createContext(c);
for(const name of ['prepareForSleep','scheduleSleepMonitorRetry']) {
 vm.runInContext(source.match(new RegExp('^  function '+name+'\\([^]*?^  \\}','m'))[0],c);root[name]=c[name];
}
root.prepareForSleep(true);
assert.equal(root.sleeping,true);assert.deepEqual(signals,[15]);
assert.equal(c.wakeReconnectTimer.stops,1);assert.equal(c.wakeStage2Timer.stops,1);
root.prepareForSleep(false);
assert.equal(root.sleeping,false);assert.equal(root.applies,1);assert.equal(c.wakeReconnectTimer.restarts,1);
root.autoReconnect=false;root.prepareForSleep(false);assert.equal(c.wakeReconnectTimer.restarts,1);
root.scheduleSleepMonitorRetry();assert.equal(root.sleepMonitorFailed,true);assert.equal(c.sleepRetry.restarts,1);
root.sleepMonitorRestarts=3;root.scheduleSleepMonitorRetry();assert.equal(c.sleepRetry.restarts,1);
root.sleepMonitorRestarts=0;root.shuttingDown=true;root.scheduleSleepMonitorRetry();assert.equal(c.sleepRetry.restarts,1);
// Execute the real startup check: a recovered process clears the error without
// resetting its finite retry budget; a failed start takes the same failure path.
const startup=source.match(/property Timer sleepStartCheck: Timer \{[^]*?onTriggered: \{([^]*?)\n    \}/)[1];
root.shuttingDown=false;root.sleepMonitorRestarts=2;c.sleepMonitor.running=true;
vm.runInContext(startup,c);
assert.equal(root.sleepMonitorFailed,false);assert.equal(root.sleepMonitorRestarts,2);
c.sleepMonitor.running=false;vm.runInContext(startup,c);
assert.equal(root.sleepMonitorFailed,true);assert.equal(c.sleepRetry.restarts,2);
assert.ok(source.includes("sender='org.freedesktop.login1',path='/org/freedesktop/login1'"));
assert.ok(source.includes('value === "boolean true"'));
assert.ok(source.includes('value === "boolean false"'));
console.log('PASS: production sleep gate, cancellation, wake restoration and bounded listener recovery.');
