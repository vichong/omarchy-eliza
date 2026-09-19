const fs = require('fs')
const {loadModule, assert, equal, done} = require('./helpers')
const E = loadModule('Eliza.js'), H = loadModule('Hayden.js')
const script = E.api.readScript(fs.readFileSync('scripts/doctor-1966.txt', 'utf8'))[1]
const engine = new E.api.Eliza(script.rules, script.memoryRule, new E.api.Tracer())
const start = Date.now()
const reply = engine.response('I ' + 'BELIEVE '.repeat(2400) + 'Z')
const elapsed = Date.now() - start
assert(typeof reply === 'string' && reply.length > 0, 'adversarial BELIEVE returns without throwing')
assert(elapsed < 500, 'matcher completes well under one second: ' + elapsed + 'ms')
assert(engine.matchBudgetExceeded, 'BELIEVE exhausts operation budget')
equal(engine.matchSteps, 10000, 'keyword matching capped at 10000 steps')
equal(reply, 'I AM NOT SURE I UNDERSTAND YOU FULLY', 'budget exhaustion uses script NONE')
// The tracer is rebuilt per response and production input is sliced to 500
// characters, so the transient trace is bounded; Service caps what it keeps.
const M = loadModule('Model.js')
engine.response(('I ' + 'BELIEVE '.repeat(2400) + 'Z').slice(0, M.MAX_INPUT_CHARS))
assert(engine.tracer.text().length <= 65536, 'transient trace bounded for a full-length input: ' + engine.tracer.text().length)
assert(M.capTrace(engine.tracer.text()).length <= M.MAX_TRACE_CHARS, 'kept trace capped')
for (let i = 0; i < 100; i++) engine.response('My token' + i)
equal(engine.memoryRule.memories.length, 64, 'Hay memory capped at 64')
assert(!engine.memoryRule.memories[0].includes('TOKEN0'), 'oldest Hay memory dropped')
const hayden = new H.api.Hayden(H.api.readScript(fs.readFileSync('scripts/hayden-1985.txt', 'utf8')).script)
assert(hayden.response('sorry '.repeat(21)).text.length > 0, 'Hayden ignores excess keywords')
equal(hayden.trace, '', 'Hayden omits trace without callback')
// A repeating literal prefix makes findPat retry many partial matches.
H.matchBudget = {remaining: 100, exhausted: false}
equal(H.match('a'.repeat(500), '*' + 'a'.repeat(100) + 'b', new Array(10)), false, 'Hayden pathological literal stops matching')
assert(H.matchBudget.exhausted, 'Hayden character operations enforce budget')
H.matchBudget = null
console.log('BELIEVE budget: ' + elapsed + 'ms')
done('bounds')
