// Exercise the actual Service methods with real engines and in-memory QML I/O.
const fs = require('fs')
const path = require('path')
const vm = require('vm')
const {loadModule, equal, assert, done} = require('./helpers')
const source = fs.readFileSync(path.join(__dirname, '../Service.qml'), 'utf8')
const C = loadModule('ConfigStore.js'), M = loadModule('Model.js')
const entries = [], saves = []
const s = {
  ConfigStore: C, Model: M, Demo: loadModule('Demo.js'), E: loadModule('Eliza.js'), H: loadModule('Hayden.js'),
  config: C.merge(C.defaults(), {boot: false}), ready: true, overlayOpen: true,
  directoryReady: true, configFile: {setText: text => saves.push(text)},
  doctorSource: fs.readFileSync(path.join(__dirname, '../scripts/doctor-1966.txt'), 'utf8'),
  haydenSource: fs.readFileSync(path.join(__dirname, '../scripts/hayden-1985.txt'), 'utf8'),
  error: '', configError: '', liveReady: false, clockReady: false,
  conversation: {
    get count() { return entries.length },
    append: entry => entries.push(entry), clear: () => { entries.length = 0 },
    remove: index => entries.splice(index, 1),
    get: index => entries[index], setProperty: (index, key, value) => { entries[index][key] = value }
  }
}
// Hayden randomly chooses memory reassemblies; use a deterministic RNG for comparison.
s.H.Math = Object.create(Math)
s.H.Math.random = () => 0
s.root = s
vm.createContext(s)
// Evaluate readonly bindings as getters so config changes behave like QML.
for (const match of source.matchAll(/^  readonly property (?:string|bool|int) (\w+): (.+)$/gm)) {
  if (match[1] === 'configDir') continue
  Object.defineProperty(s, match[1], {get: () => vm.runInContext(match[2], s)})
}
const methods = source.match(/^  function \w+\([^\n]*\)(?: \{[^\n]*\}| \{\n[\s\S]*?^  \})/gm)
vm.runInContext(methods.join('\n'), s)
s.newConversation()
equal(s.scriptId, 'doctor-1966', 'default era is 1966 with Hay')
equal(s.say('Men are all alike.'), 'IN WHAT WAY', '1966 preserves uppercase')
assert(entries.at(-1).trace.includes('selected keyword:'), 'Hay trace captured')
assert(s.typing, '1966 reveal remains active')
s.finishTyping()
s.setEra('1985')
equal(JSON.parse(saves.at(-1)).era, '1985', 'era persisted')
equal([s.scriptId, s.turns, s.history.length, entries.length], ['hayden-1985', 0, 0, 1], 'era switch rebinds the engine and clears state')
equal(s.keywordCount, 42, 'Hayden keyword count')
const expected = new s.H.api.Hayden(s.H.api.readScript(s.haydenSource).script, () => {})
equal(s.lastReply, expected.initial(), 'Hayden greeting verbatim')
for (const input of ['My mother worries about me', 'xyzzy', 'I remember IBM', 'bye']) {
  equal(s.say(input), expected.response(input).text, 'Hayden response verbatim')
  equal(entries.at(-1).trace, '', 'Mac trace stays hidden')
  equal(s.memoryCount, expected.memory.length, 'Hayden memory count')
}
assert(s.finished, 'Hayden quit ends the conversation')
const engine = s.engine, saveCount = saves.length
s.setEra('1985')
assert(s.engine === engine && saves.length === saveCount, 'unchanged era is a no-op')
s.setEra('omarchy')
equal(s.scriptId, 'doctor-1966', 'retired era falls back to 1966')
s.applyConfig(C.serialize(C.merge(s.config, {era: '1985'})))
equal([s.scriptId, s.turns, entries.length], ['hayden-1985', 0, 1], 'external era change resets conversation')
assert(s.statusLine().includes('script=hayden-1985'), 'status reflects active script')
// A finished or skipped 1966 login stays at the top of the transcript, out of the copy.
s.setEra('1966')
s.bootLines = ['login alice', '100']
s.conversation.clear()
s.finishBoot()
equal(entries.map(e => e.role), ['boot', 'eliza'], 'login kept above the greeting')
equal(entries[0].text, 'login alice\n100', 'kept login is whole')
s.finishBoot()
equal(entries.length, 2, 'greeting appended once')
assert(!s.transcriptText().includes('login'), 'copied transcript leaves the login out')
s.newConversation()
let received = ''
s.engine = {response: input => { received = input; return 'OK' }, tracer: {text: () => 'x'.repeat(20000)}}
s.say('a'.repeat(800))
equal(received.length, 500, 'central input cap reaches engine')
equal(s.history[0].length, 500, 'history uses truncated input')
equal(entries.at(-2).text.length, 500, 'user row uses truncated input')
equal(entries.at(-1).trace.length, 8192, 'trace capped')
assert(entries.at(-1).trace.endsWith('\n… trace truncated'), 'trace has final truncation line')
s.finishTyping()
s.conversation.clear()
s.append('boot', 'login', '', 0)
for (let i = 0; i < 500; i++) s.append('user', String(i), '', 0)
equal(entries.length, 400, 'conversation row cap')
equal([entries[0].role, entries[1].text], ['boot', '101'], 'oldest non-boot rows dropped')
s.setEra('1985')
assert(s.say('sorry '.repeat(21)).length > 0, '21 Hayden keywords return a reply')
equal([s.turns, s.history.length, entries.length, s.finished, s.pendingReply], [1, 1, 3, false, ''], 'overflow turn remains coherent')
for (const era of ['1966', '1985']) {
  s.setEra(era)
  s.newConversation()
  s.engine = {response: () => { throw new Error('broken engine') }}
  const reply = era === '1966' ? 'PLEASE GO ON' : 'Please go on.'
  equal(s.say('hello'), reply, 'engine exception fallback ' + era)
  equal([s.turns, s.history.length, entries.length, s.finished], [1, 1, 3, false], 'exception turn coherent ' + era)
  equal(s.pendingReply, era === '1966' ? reply : '', 'fallback typing state ' + era)
  s.finishTyping()
  equal(entries.at(-1).text, reply, 'fallback row completed ' + era)
}
s.applyConfig(' '.repeat(65536))
assert(s.configError.includes('too large'), 'config cap reported')
s.applyConfig('é'.repeat(32768))
assert(s.configError.includes('too large'), 'config cap counts bytes')
s.applyClockFormat(' '.repeat(1048576))
equal(s.clockFormat, '', 'shell config cap defaults')
s.ready = false
s.configLoaded = s.doctorLoaded = s.haydenLoaded = true
s.doctorSource = 'x'.repeat(262145)
s.initialize()
assert(!s.ready && s.error.includes('too large'), 'oversized bundled script rejected before parsing')
let copied = ''
s.clipboard = {running: false, stdinEnabled: false}
s.copyTranscript()
equal(s.copyText, s.transcriptText(), 'clipboard payload held for stdin')
assert(s.clipboard.stdinEnabled && s.clipboard.running, 'managed clipboard process started with stdin')
// The demo types the paper's patient lines into the live engine, one tick at a time.
s.doctorSource = fs.readFileSync(path.join(__dirname, '../scripts/doctor-1966.txt'), 'utf8')
Object.assign(s, {demo: false, demoIndex: 0, demoPause: 0, demoDraft: '', ready: true, error: '', config: C.merge(s.config, {boot: false})})
s.setEra('1966')
s.overlayOpen = true
s.startDemo()
assert(s.demo && entries.length === 1, 'demo starts on a fresh conversation')
let ticks = 0
while (s.demo && ticks++ < 5000) { if (s.typing) s.finishTyping(); s.demoTick() }
assert(!s.demo && s.demoDraft === '', 'demo ends by itself')
equal(s.turns, s.Demo.INPUTS.length, 'every patient line was said')
equal(s.lastReply, 'DOES THAT HAVE ANYTHING TO DO WITH THE FACT THAT YOUR BOYFRIEND MADE YOU COME HERE', 'demo ends on the published last reply')
s.startDemo(); s.demoTick(); s.overlayOpen = false; s.demoTick()
assert(!s.demo, 'closing the panel stops the demo')
s.overlayOpen = true; s.startDemo(); s.setEra('1985')
assert(!s.demo, 'an era switch stops the demo')
done('service')
