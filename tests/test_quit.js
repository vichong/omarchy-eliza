// Quickshell plugins are statically linked, so qmltestrunner cannot load them.
// Run QtTest in Quickshell itself, using real installed controls read-only.
const fs = require('fs')
const os = require('os')
const path = require('path')
const {spawnSync} = require('child_process')
const {assert, done} = require('./helpers')
const root = path.resolve(__dirname, '..')
const shell = '/usr/share/omarchy/shell'
if (!fs.existsSync(path.join(shell, 'Ui/Panel.qml')) || !fs.existsSync(path.join(shell, 'Commons/qmldir'))
  || !fs.existsSync('/usr/share/omarchy/bin/omarchy') || !fs.existsSync('/usr/share/omarchy/bin/omarchy-plugin-disable')) {
  console.log('quit: SKIP (runtime integration test requires the installed Omarchy shell and CLI)')
  process.exit(0)
}
const quickshell = spawnSync('quickshell', ['--version'], {encoding: 'utf8', timeout: 5000})
if (quickshell.error && quickshell.error.code === 'ENOENT') {
  console.log('quit: SKIP (runtime integration test requires quickshell on PATH)')
  process.exit(0)
}
const sandbox = fs.mkdtempSync(path.join(os.tmpdir(), 'eliza-quit-'))
try {
  for (const dir of ['Ui', 'Commons']) fs.symlinkSync(path.join(shell, dir), path.join(sandbox, dir))
  // Quickshell's qs import scanner requires sources inside the config root.
  for (const file of ['Console.qml', 'EraMac.qml', 'EraTeletype.qml', 'Service.qml',
    'Model.js', 'ConfigStore.js', 'Eliza.js', 'Hayden.js', 'Demo.js', 'scripts', 'fonts']) {
    fs.symlinkSync(path.join(root, file), path.join(sandbox, file))
  }
  fs.copyFileSync(path.join(__dirname, 'qml/quit.qml'), path.join(sandbox, 'shell.qml'))
  for (const dir of ['home', 'r', 'bin']) fs.mkdirSync(path.join(sandbox, dir), {mode: 0o700})
  // Run the installed dispatcher/disable script, but never the live IPC client.
  // Both launch argv and the final IPC request are captured in the sandbox.
  const cliCalls = path.join(sandbox, 'cli-calls')
  const ipcCalls = path.join(sandbox, 'ipc-calls')
  const notices = path.join(sandbox, 'notices')
  const failureFlag = path.join(sandbox, 'failure-flag')
  for (const file of [cliCalls, ipcCalls, notices, failureFlag]) fs.writeFileSync(file, '')
  fs.writeFileSync(path.join(sandbox, 'bin/omarchy'), '#!/bin/sh\nprintf "%s\\n" "$@" >> "$ELIZA_QUIT_CLI_CALLS"\n[ "$(cat "$ELIZA_QUIT_FAILURE_FLAG")" = launch ] && exit 127\nsleep 0.05\nexec /usr/share/omarchy/bin/omarchy "$@"\n', {mode: 0o700})
  fs.writeFileSync(path.join(sandbox, 'bin/omarchy-shell'), '#!/bin/sh\nprintf "%s\\n" "$@" >> "$ELIZA_QUIT_IPC_CALLS"\nif [ -s "$ELIZA_QUIT_FAILURE_FLAG" ]; then printf "unknown\\n"; else printf "ok\\n"; fi\n', {mode: 0o700})
  fs.writeFileSync(path.join(sandbox, 'bin/omarchy-notification-send'), '#!/bin/sh\nprintf "%s\\n" "$@" >> "$ELIZA_QUIT_NOTICES"\n', {mode: 0o700})
  const env = {...process.env, QT_QPA_PLATFORM: 'offscreen', QT_QPA_PLATFORMTHEME: '', HOME: path.join(sandbox, 'home'),
    XDG_CONFIG_HOME: path.join(sandbox, 'home/.config'), XDG_STATE_HOME: path.join(sandbox, 'home/.local/state'),
    XDG_CACHE_HOME: path.join(sandbox, 'home/.cache'), XDG_RUNTIME_DIR: path.join(sandbox, 'r'),
    PATH: path.join(sandbox, 'bin') + path.delimiter + process.env.PATH,
    ELIZA_QUIT_CLI_CALLS: cliCalls, ELIZA_QUIT_IPC_CALLS: ipcCalls,
    ELIZA_QUIT_NOTICES: notices, ELIZA_QUIT_FAILURE_FLAG: failureFlag}
  delete env.WAYLAND_DISPLAY
  delete env.DISPLAY
  const result = spawnSync('quickshell', ['--no-color', '-p', path.join(sandbox, 'shell.qml')],
    {env, encoding: 'utf8', timeout: 45000})
  const output = (result.stdout || '') + (result.stderr || '')
  console.log(output.trim())
  assert(!result.error, 'Quickshell harness starts and completes: ' + (result.error || ''))
  assert(result.status === 0, 'Quickshell quit regression exits successfully')
  assert(/QUIT REGRESSION: 0 failures, 24 passed/.test(output), 'all 23 regression cases plus init actually ran')
} finally {
  fs.rmSync(sandbox, {recursive: true, force: true})
}
done('quit')
