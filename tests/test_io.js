const fs = require('fs'), vm = require('vm'), os = require('os'), path = require('path')
const {spawnSync} = require('child_process')
const {loadModule, assert, equal, done} = require('./helpers')
const M = loadModule('Model.js')
const source = fs.readFileSync('Service.qml', 'utf8')
const block = name => source.match(new RegExp('  property (?:Process|FileView) ' + name + ': [^\\n]+\\n([\\s\\S]*?)^  }', 'm'))[1]
const command = (name, root) => vm.runInNewContext(block(name).match(/command: (.+)/)[1], {root})
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'eliza-io-'))
try {
  const file = path.join(dir, 'foreign.json')
  for (const [reader, watcher, cap] of [['shellConfigRead', 'shellConfigFile', 1048576], ['configRead', 'configFile', 65536]]) {
    const root = {}; root[watcher] = {path: file}
    const args = command(reader, root)
    equal(Array.from(args), ['head', '-c', String(cap), '--', file], reader + ' uses explicit byte ceiling')
    for (const size of [cap - 1, cap, cap + 4000]) {
      fs.writeFileSync(file, Buffer.alloc(size, 97))
      const result = spawnSync(args[0], args.slice(1))
      equal(result.stdout.length, Math.min(size, cap), reader + ' output bytes ' + size)
      equal(M.utf8Bytes(result.stdout.toString()) >= cap, size >= cap, 'hit-cap rejection')
    }
    const view = block(watcher)
    assert(view.includes('preload: false') && view.includes('blockLoading: false'), watcher + ' cannot preload')
    assert(!/\b(?:text|data|reload)\(/.test(view), watcher + ' never reads foreign content')
  }
  for (const name of ['hostname', 'omarchy-version', 'uname']) {
    fs.writeFileSync(path.join(dir, name), '#!/bin/sh\nhead -c 100000 /dev/zero | tr "\\000" x\n', {mode: 0o755})
  }
  const args = command('bootProbe', {})
  const result = spawnSync(args[0], args.slice(1), {env: {...process.env, PATH: dir + ':' + process.env.PATH, USER: 'u'.repeat(4000)}})
  equal(result.stdout.length, 2048, 'boot total stdout byte cap with oversized USER')
  const normal = spawnSync(args[0], args.slice(1), {env: {...process.env, PATH: dir + ':' + process.env.PATH, USER: 'u'}})
  equal(normal.stdout.toString().trim().split('\n').map(s => s.length), [1, 256, 256, 256], 'each boot substitution capped')
  const clipboard = block('clipboard')
  equal(Array.from(command('clipboard', {})), ['wl-copy'], 'clipboard argv contains no transcript')
  let data = ''
  const state = {root: {copyText: 'private conversation'}, stdinEnabled: true, write: text => { data += text }}
  vm.runInNewContext(clipboard.match(/onStarted: \{ (.*) \}/)[1], state)
  equal(data, 'private conversation', 'clipboard writes payload to stdin')
  assert(!state.stdinEnabled && state.root.copyText === '', 'clipboard closes stdin and releases payload')
} finally { fs.rmSync(dir, {recursive: true, force: true}) }
done('io')
