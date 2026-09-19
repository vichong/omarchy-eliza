const {loadModule, equal, assert, done} = require('./helpers')
const M = loadModule('Model.js')
for (const era of ['1966', '1985']) equal(M.eraFor(era), era, 'valid era')
for (const era of [null, undefined, '', 'wrong', 'omarchy', 1966]) equal(M.eraFor(era), '1966', 'default era')
const list = [{role: 'eliza', text: 'hello'}], entry = {role: 'user', text: 'test', trace: '', at: 42}
const appended = M.transcriptAppend(list, entry)
equal(list.length, 1, 'append does not mutate input list')
equal(appended[1], entry, 'append preserves entry')
entry.text = 'changed'
equal(appended[1].text, 'test', 'append copies entry')
assert(M.isQuitReply({finished: true}), 'Hayden finished flag')
for (const value of [null, 'GOODBYE', {text: 'Goodbye'}, {finished: false}, {finished: 'true'}]) assert(!M.isQuitReply(value), 'no guessed quits')
equal(M.contrast({r: 0, g: 0, b: 0}, {r: 1, g: 1, b: 1}), 21, 'contrast ratio')
equal(M.bootValues('\n\n\n'), {user: 'USER', host: 'OMARCHY', version: '4', kernel: 'linux'}, 'generic boot fallbacks')
const values = M.bootValues('alice\nmy-host\n4.2\n6.12\n')
const date = new Date(2026, 8, 9, 10, 42, 18)
const tty = M.bootLines('1966', values, date, 'mdy').join('\n')
assert(tty.includes('login alice\nW 1042.3') && tty.includes('LOGGED IN 09/09/26') && tty.includes('MY-HOST'), 'CTSS login uses the real date and host')
assert(tty.includes('LOGGED IN 09/09/26 1042.3 FROM 200000\n LAST LOGOUT WAS 01/08/66 1915.9 FROM 200000') && !tty.includes('BUILT'), 'last logout stays in 1966, month first')
equal(M.bootLines('1966', values, date, 'dmy')[4], ' LAST LOGOUT WAS 08/01/66 1915.9 FROM 200000', 'last logout follows the regional order')
assert(!tty.includes('2026') && tty.endsWith('100'), 'CTSS two-digit year and script prompt')
equal(M.bootLines('1985', values, date, 'mdy'), [], '1985 boots with a splash, not text')
equal(M.bootValues('  bob  \n\n5').user, 'bob', 'trim live values')
for (const [clock, locale, expected] of [
  ['ddd d MMM h:mm AP', 'MM/dd/yyyy', 'dmy'],
  ['MM/dd/yyyy', 'dd/MM/yyyy', 'mdy'],
  ['HH:mm', 'dd/MM/yyyy', 'dmy'], ['HH:mm', 'MM/dd/yyyy', 'mdy'],
  ['', 'd/M/yy', 'dmy'], [null, 'M/d/yy', 'mdy'],
  ["'dd MM' MM/dd/yyyy", 'd/M/yy', 'mdy'],
  ['ddd MMM d', '', 'mdy'], ['dddd HH:mm', 'dd/MM/yyyy', 'dmy'],
  ['dd MMMM yyyy', '', 'dmy'], ['', '', 'mdy']
]) equal(M.dateOrder(clock, locale), expected, 'regional date order')
for (const [d, dmy, mdy] of [
  [new Date(2026, 8, 9), '09/09/26', '09/09/26'],
  [new Date(2031, 0, 2), '02/01/31', '01/02/31'],
  [new Date(2004, 10, 23), '23/11/04', '11/23/04']
]) {
  equal(M.bootDate(d, 'dmy'), dmy, 'day first, real year')
  equal(M.bootDate(d, 'mdy'), mdy, 'month first, real year')
}
for (const section of ['left', 'center', 'right']) {
  equal(M.clockFormatFromShellConfig(JSON.stringify({bar: {layout: {[section]: [{id: 'other'}, {id: 'omarchy.clock', format: 'd MMM'}]}}})), 'd MMM', 'clock lookup in each section')
}
for (const config of ['', 'bad json', 'null', '{}', '{"bar":{"layout":{"left":[null, {"id":"omarchy.clock"}]}}}']) equal(M.clockFormatFromShellConfig(config), '', 'missing clock falls back')
equal(M.bootLines('1966', values, new Date(2031, 0, 2), 'dmy')[3], ' ALICE  6 LOGGED IN 02/01/31 0000.0 FROM 200000', 'compact regional login line')
for (let i = 0; i < 18; i++) equal(M.bootLineTyped('1966', i), [0, 13, 17].includes(i), 'only user commands typed')
assert(!M.bootLineTyped('1985', 0), 'the Mac splash types nothing')
done('model')
