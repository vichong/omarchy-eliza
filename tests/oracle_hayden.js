// Prints a transcript in the exact format of Hayden's ElizaApp (headless):
// ">> input" then the reply, starting with the implicit "Hello." the Java sends.
const { loadModule } = require("./helpers.js")
const fs = require("fs"), path = require("path")
const H = loadModule("Hayden.js")
const script = H.api.readScript(fs.readFileSync(path.join(__dirname, "..", "scripts", "hayden-1985.txt"), "utf8")).script
const inputs = fs.readFileSync(process.argv[2], "utf8").replace(/\r/g, "").split("\n")
if (inputs.length && inputs[inputs.length - 1] === "") inputs.pop()
Math.random = () => 0 // Java's memory pick is random; pin ours so a diff points at the rule, not the dice
const engine = new H.api.Hayden(script)
let s = "Hello."
let i = 0
for (;;) {
  console.log(">> " + s)
  const r = engine.response(s)
  console.log(r.text)
  if (r.finished || i >= inputs.length) break
  s = inputs[i++]
}
