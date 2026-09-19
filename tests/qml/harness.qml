import QtQuick
import "../../Eliza.js" as E

// Proves the engine runs under the Qt QML JavaScript engine, not only Node.
Item {
    function run(text) {
        try { runInner(text) } catch (e) { console.log("QML harness: EXCEPTION " + e + " at " + e.fileName + ":" + e.lineNumber); Qt.exit(1) }
    }
    function runInner(text) {
        var parsed = E.api.readScript(text)
        if (parsed[0] !== "success") { console.log("FAIL parse: " + parsed[0]); Qt.exit(1); return }
        var script = parsed[1]
        var eliza = new E.api.Eliza(script.rules, script.memoryRule, new E.api.Tracer())
        var r1 = eliza.response("Men are all alike.")
        var r2 = eliza.response("They're always bugging us about something or other.")
        console.log("R1: " + r1); console.log("R2: " + r2)
        console.log("TRACE:\n" + eliza.tracer.text())
        var t0 = Date.now(); E.api.elizaTest(); console.log("elizaTest ms: " + (Date.now() - t0))
        var ok = r1 === "IN WHAT WAY" && r2 === "CAN YOU THINK OF A SPECIFIC EXAMPLE"
        console.log(ok ? "QML harness: ok" : "QML harness: FAIL")
        Qt.exit(ok ? 0 : 1)
    }
    Component.onCompleted: {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() { if (xhr.readyState === XMLHttpRequest.DONE) run(xhr.responseText) }
        xhr.open("GET", Qt.resolvedUrl("../../scripts/doctor-1966.txt"))
        xhr.send()
    }
}
