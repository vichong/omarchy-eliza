import QtQuick
import "../../Hayden.js" as H

Item {
    function run(text) {
        try {
            var parsed = H.api.readScript(text)
            if (!parsed.ok) throw new Error(parsed.error)
            var engine = new H.api.Hayden(parsed.script)
            var inputs = ["Men are all alike.", "They're always bugging us about something or other.", "Well, my boyfriend made me come here."]
            var expected = ["In what way ?", "Can you think of a specific example ?", "Your boyfriend made you come here  ?"]
            for (var i = 0; i < inputs.length; i++) {
                var result = engine.response(inputs[i])
                console.log("R" + (i + 1) + ": " + result.text)
                if (result.text !== expected[i] || result.finished) throw new Error("Reply mismatch " + (i + 1))
            }
            console.log("QML Hayden harness: ok")
            Qt.exit(0)
        } catch (e) {
            console.log("QML Hayden harness: EXCEPTION " + e + " at " + e.fileName + ":" + e.lineNumber)
            Qt.exit(1)
        }
    }
    Component.onCompleted: {
        try {
            var xhr = new XMLHttpRequest()
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) run(xhr.responseText)
            }
            xhr.open("GET", Qt.resolvedUrl("../../scripts/hayden-1985.txt"))
            xhr.send()
        } catch (e) {
            console.log("QML Hayden harness: EXCEPTION " + e)
            Qt.exit(1)
        }
    }
}
