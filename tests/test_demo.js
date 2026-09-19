// The demo must reproduce the conversation printed in the 1966 CACM paper.
const fs = require('fs')
const path = require('path')
const {loadModule, equal, assert, done} = require('./helpers')
const D = loadModule('Demo.js'), E = loadModule('Eliza.js').api
const published = [
  'IN WHAT WAY', 'CAN YOU THINK OF A SPECIFIC EXAMPLE', 'YOUR BOYFRIEND MADE YOU COME HERE',
  'I AM SORRY TO HEAR YOU ARE DEPRESSED', 'DO YOU THINK COMING HERE WILL HELP YOU NOT TO BE UNHAPPY',
  'WHAT WOULD IT MEAN TO YOU IF YOU GOT SOME HELP', 'TELL ME MORE ABOUT YOUR FAMILY',
  'WHO ELSE IN YOUR FAMILY TAKES CARE OF YOU', 'YOUR FATHER', 'WHAT RESEMBLANCE DO YOU SEE',
  'WHAT MAKES YOU THINK I AM NOT VERY AGGRESSIVE', "WHY DO YOU THINK I DON'T ARGUE WITH YOU",
  'DOES IT PLEASE YOU TO BELIEVE I AM AFRAID OF YOU', 'WHAT ELSE COMES TO MIND WHEN YOU THINK OF YOUR FATHER',
  'DOES THAT HAVE ANYTHING TO DO WITH THE FACT THAT YOUR BOYFRIEND MADE YOU COME HERE'
]
const script = E.readScript(fs.readFileSync(path.join(__dirname, '../scripts/doctor-1966.txt'), 'utf8'))[1]
const engine = new E.Eliza(script.rules, script.memoryRule, new E.Tracer())
equal(D.INPUTS.length, published.length, 'fifteen exchanges')
D.INPUTS.forEach((line, i) => equal(engine.response(line), published[i], 'published reply ' + (i + 1)))
assert(D.INPUTS.every(line => line.length <= 500), 'demo lines fit the input limit')
done('demo')
