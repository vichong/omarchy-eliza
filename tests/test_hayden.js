const fs = require('fs')
const path = require('path')
const { loadModule, fixture, assert, equal, done } = require('./helpers')
const moduleScope = loadModule('Hayden.js')
const { api } = moduleScope
const read = name => fs.readFileSync(path.join(__dirname, '..', name), 'utf8')
const inputLines = name => read('tests/fixtures/' + name).trimEnd().split(/\r?\n/)
const source = read('scripts/hayden-1985.txt')
const parsed = api.readScript(source)
assert(parsed.ok, 'script loads')
const script = parsed.script
for (const [name, count] of Object.entries({ keys: 42, syns: 8, pre: 18, post: 9, quit: 4 })) {
  equal(script[name].length, count, name + ' count')
}
equal(script.initial, 'How do you do.  Please tell me your problem.', 'initial text')
equal(script.final, 'Goodbye.  It was nice talking to you.', 'final text')
equal(new api.Hayden(script).initial(), script.initial, 'initial method')
assert(!api.readScript(null).ok, 'non-text parse error')
assert(!api.readScript('decomp: *').ok, 'orphan decomposition parse error')
assert(!api.readScript('reasmb: hello').ok, 'orphan reassembly parse error')

// Decomp.stepRule randomizes memory rules. Pin only the test's random source;
// zero selects the second memory rule because Java increments after randomizing.
const originalRandom = Math.random
try {
  Math.random = () => 0
  const classic = new api.Hayden(script)
  const inputs = inputLines('classic-inputs.txt')
  equal(inputs.length, 15, 'classic input count')
  const actual = inputs.map(input => ({ input, ...classic.response(input) }))
  equal(actual, fixture('hayden-classic.json'), 'classic golden replies (Math.random = 0)')
  for (const row of actual) assert(row.text && row.text !== 'I am at a loss for words.', row.input)

  const smoke = new api.Hayden(script)
  for (const input of inputLines('hayden-test-inputs.txt')) {
    const result = smoke.response(input)
    assert(result.text && result.text !== 'I am at a loss for words.', 'smoke: ' + input)
  }
  const memory = new api.Hayden(script)
  for (let i = 0; i < 3; i++) memory.response('my x' + i)
  for (let i = 0; i < 3; i++) {
    equal(memory.response('xyzzy').text, 'Earlier you said your x' + i + '  .', 'FIFO memory ' + i)
  }
  equal(memory.response('xyzzy').text, script.keys[0].decomp[0].reasemb[0], 'xnone after memory exhausted')
  for (let i = 0; i < 21; i++) memory.response('my x' + i)
  equal(memory.memory.length, 20, 'memory capacity')
} finally { Math.random = originalRandom }

for (const quit of ['bye', 'done', 'exit', 'quit']) {
  equal(new api.Hayden(script).response(quit.toUpperCase() + '!'),
    { text: script.final, finished: true }, 'quit: ' + quit)
}
const apologies = new api.Hayden(script)
for (let i = 0; i < 5; i++) {
  equal(apologies.response('apologise').text, script.keys[1].decomp[0].reasemb[i % 4], 'goto and cycling ' + i)
}
const engineFor = text => new api.Hayden(api.readScript(text).script)
const chain = engineFor('key: a\ndecomp: *\nreasmb: goto b\nkey: b\ndecomp: *\nreasmb: goto c\nkey: c\ndecomp: *\nreasmb: reached')
equal(chain.response('a').text, 'reached', 'multiple goto hops')
const ranked = engineFor('key: a 1\ndecomp: *\nreasmb: A\nkey: b 1\ndecomp: *\nreasmb: B\nkey: c 2\ndecomp: *\nreasmb: C')
equal(ranked.response('b a').text, 'B', 'equal ranks follow input order')
equal(ranked.response('a b').text, 'A', 'reversed equal ranks')
equal(ranked.response('a c b').text, 'C', 'higher rank wins')
equal(ranked.response('unknown. b! c').text, 'B', 'sentences tried in order')
equal(engineFor('').response('unknown').text, 'I am at a loss for words.', 'last fallback')
const post = engineFor('pre: im i amxyz\npost: i you\npost: you I\nsynon: sad unhappy\nkey: i\ndecomp: * i am* @sad *\nreasmb: i (3) (4) (4)')
equal(post.response('IM unhappy you').text, 'i unhappy I  I ', 'substring star, synonym numbering, captured post only')
const pieces = new Array(4)
assert(!moduleScope.match('aa1b', '*a#b', pieces), 'matcher does not backtrack')
equal(moduleScope.amatch('ab', 'abc'), 2, 'partial literal match at end')
assert(moduleScope.match('', '#', pieces), 'number wildcard accepts zero digits')
equal(moduleScope.compress(' a   b .'), ' a b.', 'compress exact spaces')
equal(moduleScope.trim('  a  '), 'a  ', 'leading-only trim')
const traceLines = []
const traced = new api.Hayden(script, line => traceLines.push(line))
traced.response('apologise')
assert(traced.trace.includes('key: sorry'), 'trace follows goto')
equal(traced.trace, traceLines.join('\n') + '\n', 'trace callback')
traced.response('quit')
equal(traced.trace, '', 'trace resets each response')
equal(apologies.trace, '', 'trace empty without tracer')
equal(new api.Hayden(script).response('sorry').text, "Please don't apologise.", 'instances have independent cycles')
done('test_hayden')
