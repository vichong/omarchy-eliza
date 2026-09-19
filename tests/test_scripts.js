// Golden transcript: the 1966 CACM conversation, run through the script file we ship.
const { loadModule, equal, done } = require("./helpers.js")
const fs = require("fs"), path = require("path")
const E = loadModule("Eliza.js")
const text = fs.readFileSync(path.join(__dirname, "..", "scripts", "doctor-1966.txt"), "utf8")
const [status, script] = E.api.readScript(text)
equal(status, "success", "doctor-1966.txt parses")
const eliza = new E.api.Eliza(script.rules, script.memoryRule, new E.api.nullTracer())
const conversation = E.api.CACM_1966_CONVERSATION
for (let i = 0; i < conversation.length; i += 2)
  equal(eliza.response(conversation[i]), conversation[i + 1], "reply to: " + conversation[i])
equal(script.helloMessage.join(" "), "HOW DO YOU DO. PLEASE TELL ME YOUR PROBLEM", "hello message")
done("test_scripts")
