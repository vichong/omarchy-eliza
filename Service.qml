import QtQuick
import Quickshell
import Quickshell.Io
import "Eliza.js" as E
import "Hayden.js" as H
import "Model.js" as Model
import "ConfigStore.js" as ConfigStore
import "Demo.js" as Demo

QtObject {
  id: root
  property var shell: null
  property var manifest: null
  property var config: ConfigStore.defaults()
  readonly property string era: config.era
  readonly property string scriptId: era === "1985" ? "hayden-1985" : "doctor-1966"
  readonly property bool usesHayden: scriptId === "hayden-1985"
  readonly property bool thoughts: config.thoughts
  readonly property bool blink: config.blink
  readonly property bool showLabel: config.showLabel
  readonly property bool macPaper: config.macPaper
  readonly property string phosphor: config.phosphor
  readonly property bool boot: config.boot
  readonly property bool demoIdle: config.demoIdle
  readonly property int teletypeCps: config.teletypeCps
  property string error: ""
  property string configError: ""
  property string copyStatus: ""
  property string copyText: ""
  property string doctorSource: ""
  property string haydenSource: ""
  property bool doctorLoaded: false
  property bool haydenLoaded: false
  property bool configDirty: false
  property bool ready: false
  property bool configLoaded: false
  property bool directoryReady: false
  property bool overlayOpen: false
  property var engine: null
  property bool finished: false
  property int memoryCount: 0
  property int turns: 0
  property string lastReply: ""
  property string pendingReply: ""
  property int revealed: 0
  readonly property bool typing: pendingReply !== ""
  property var history: []
  property ListModel conversation: ListModel {}
  readonly property string configDir: Quickshell.env("HOME") + "/.config/omarchy/eliza"
  property var liveValues: Model.bootValues("")
  property bool liveReady: false
  property int keywordCount: 0
  // idle -> waiting (startup data) -> playing -> idle; greeting is appended once.
  property string bootState: "idle"
  readonly property bool booting: bootState !== "idle"
  property var bootLines: []
  property string bootText: ""
  property int bootPosition: 0
  property int bootCharacters: 0
  property int bootBeat: 0
  property string clockFormat: ""
  property bool clockReady: false
  property FileView shellConfigFile: FileView {
    path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
    watchChanges: true
    printErrors: false
    preload: false
    blockLoading: false
    onFileChanged: root.shellConfigRead.running = true
  }
  // Installed Quickshell metadata omits QProcess::ExitStatus.
  // qmllint disable signal-handler-parameters
  property Process shellConfigRead: Process {
    command: ["head", "-c", "1048576", "--", root.shellConfigFile.path]
    running: true
    stdout: StdioCollector { onStreamFinished: root.applyClockFormat(text) }
    onExited: function(code) { if (code !== 0) root.applyClockFormat("") }
  }
  // qmllint enable signal-handler-parameters
  function applyClockFormat(text) {
    clockFormat = Model.utf8Bytes(text) >= 1048576 ? "" : Model.clockFormatFromShellConfig(text)
    clockReady = true
    if (bootState === "waiting" && liveReady) playBoot()
  }
  property bool bootRequested: false
  property Process bootProbe: Process {
    // timeout bounds the whole process group, including command substitutions.
    command: ["timeout", "-s", "KILL", "5s", "sh", "-c", "printf '%s\\n' \"$USER\" \"$(hostname | head -c 256)\" \"$(omarchy-version 2>/dev/null | head -c 256)\" \"$(uname -r | head -c 256)\" | head -c 2048"]
    running: true
    stdout: StdioCollector { onStreamFinished: root.liveValues = Model.bootValues(text) }
    onExited: { root.liveReady = true; if (root.bootState === "waiting" && root.clockReady) root.playBoot() }
  }
  property Timer probeDeadline: Timer {
    interval: 5000; running: !root.liveReady
    onTriggered: {
      root.bootProbe.running = false
      root.liveReady = true
      if (root.bootState === "waiting" && root.clockReady) root.playBoot()
    }
  }
  property Timer bootTimer: Timer {
    // Slow enough to be enjoyed: Mac beats hold about two seconds each, system
    // output lands four lines a second, and typed commands keep the teletype pace.
    interval: root.era === "1985" ? [2200, 1800, 2600][root.bootBeat]
      : Model.bootLineTyped(root.era, root.bootPosition) ? Math.max(1, Math.round(1000 / root.teletypeCps)) : 260
    repeat: true
    running: root.bootState === "playing"
    onTriggered: {
      if (root.era === "1985") {
        if (root.bootBeat === 2) root.finishBoot()
        else root.bootBeat++
      } else if (root.bootPosition >= root.bootLines.length) root.finishBoot()
      else {
        var line = root.bootLines[root.bootPosition]
        var typed = Model.bootLineTyped(root.era, root.bootPosition)
        root.bootCharacters = typed ? root.bootCharacters + 1 : line.length
        root.bootText = root.bootLines.slice(0, root.bootPosition).concat([line.slice(0, root.bootCharacters)]).join("\n")
        if (root.bootCharacters >= line.length) { root.bootPosition++; root.bootCharacters = 0 }
      }
    }
  }

  // The demo is a real conversation: the patient's lines from the 1966 paper are
  // typed into the live engine, which answers for itself.
  property bool demo: false
  property int demoIndex: 0
  property int demoPause: 0
  property string demoDraft: ""
  property Timer demoTimer: Timer {
    interval: Demo.KEY_MS; repeat: true
    running: root.demo
    onTriggered: root.demoTick()
  }
  function startDemo() {
    if (!ready) return
    newConversation(true)
    demoIndex = 0; demoDraft = ""; demoPause = Math.ceil(Demo.THINK_MS / Demo.KEY_MS)
    demo = true
  }
  function stopDemo() { demo = false; demoDraft = "" }
  function demoTick() {
    if (!overlayOpen || demoIndex >= Demo.INPUTS.length) { stopDemo(); return }
    if (booting || typing) { demoPause = Math.ceil(Demo.THINK_MS / Demo.KEY_MS); return }
    if (demoPause > 0) { demoPause--; return }
    var line = Demo.INPUTS[demoIndex]
    if (demoDraft.length < line.length) { demoDraft = line.slice(0, demoDraft.length + 1); return }
    demoDraft = ""; demoIndex++
    say(line)
    demoPause = Math.ceil(Demo.THINK_MS / Demo.KEY_MS)
  }
  onOverlayOpenChanged: {
    if (overlayOpen && ready && conversation.count === 0) startBoot()
    else if (!overlayOpen && booting) finishBoot()
  }
  function startBoot() {
    bootRequested = true
    if (!ready) return
    if (!boot) { finishBoot(); return }
    // An era switch while the overlay is closed leaves the transcript empty so
    // the boot plays on the next open, where someone can actually watch it.
    if (!overlayOpen) return
    bootState = "waiting"
    if (liveReady && clockReady) playBoot()
  }
  function playBoot() {
    bootLines = Model.bootLines(era, liveValues, new Date(), Model.dateOrder(clockFormat, Qt.locale().dateFormat(Locale.ShortFormat)))
    bootText = ""; bootPosition = 0; bootCharacters = 0; bootBeat = 0
    bootState = "playing"
    bootTimer.restart()
  }
  function finishBoot() {
    bootState = "idle"; bootRequested = false
    // The login stays at the top of the transcript, whole even when skipped.
    if (ready && conversation.count === 0 && bootLines.length) append("boot", bootLines.join("\n"), "", 0)
    bootText = ""; bootLines = []
    if (ready && (conversation.count === 0 || conversation.get(conversation.count - 1).role === "boot")) append("eliza", lastReply, "", 0)
  }
  property FileView configFile: FileView {
    path: root.configDir + "/config.json"
    atomicWrites: true
    printErrors: false
    watchChanges: true
    preload: false
    blockLoading: false
    onFileChanged: root.configRead.running = true
    onSaveFailed: root.configError = "Could not save config.json"
  }
  // qmllint disable signal-handler-parameters
  property Process configRead: Process {
    command: ["head", "-c", "65536", "--", root.configFile.path]
    running: true
    stdout: StdioCollector { onStreamFinished: root.applyConfig(text) }
    onExited: function(code) { if (code !== 0) root.applyConfig("") }
  }
  property Process clipboard: Process {
    command: ["wl-copy"]
    onStarted: { write(root.copyText); stdinEnabled = false; root.copyText = "" }
    onExited: function(code) { root.copyStatus = code === 0 ? "Conversation copied" : "Could not copy conversation" }
    onRunningChanged: if (!running && root.copyStatus === "Copying…") { root.copyStatus = "Could not copy conversation"; root.copyText = "" }
  }
  // qmllint enable signal-handler-parameters
  function copyTranscript() {
    if (clipboard.running) return
    copyText = transcriptText()
    copyStatus = "Copying…"
    clipboard.stdinEnabled = true
    clipboard.running = true
  }
  property Process prepareDir: Process {
    command: ["mkdir", "-p", root.configDir]
    running: true
    onExited: function(code) {
      root.directoryReady = code === 0
      if (code === 0 && root.configDirty) { root.configFile.setText(ConfigStore.serialize(root.config)); root.configDirty = false }
      if (code !== 0) root.configError = "Could not create config directory"
    }
  }
  property FileView doctorFile: FileView {
    path: Qt.resolvedUrl("scripts/doctor-1966.txt")
    onLoaded: { root.doctorSource = text(); root.doctorLoaded = true; root.initialize() }
    onLoadFailed: root.error = "Could not load doctor-1966.txt"
  }
  property FileView haydenFile: FileView {
    path: Qt.resolvedUrl("scripts/hayden-1985.txt")
    onLoaded: { root.haydenSource = text(); root.haydenLoaded = true; root.initialize() }
    onLoadFailed: root.error = "Could not load hayden-1985.txt"
  }
  property Timer typeTimer: Timer {
    interval: Math.max(1, Math.round(1000 / root.teletypeCps))
    repeat: true
    running: root.typing
    onTriggered: {
      root.revealed++
      root.conversation.setProperty(root.conversation.count - 1, "text", root.pendingReply.slice(0, root.revealed))
      if (root.revealed >= root.pendingReply.length) root.finishTyping()
    }
  }
  function applyConfig(text) {
    var tooLarge = Model.utf8Bytes(text) >= 65536
    var parsed = ConfigStore.parse(tooLarge ? "" : text), oldEra = era
    config = parsed.config
    configError = tooLarge ? "config.json is too large (limit 65536 bytes)" : parsed.error
    configLoaded = true
    if (!boot && booting) finishBoot()
    if (ready && oldEra !== era) newConversation(true)
    else initialize()
  }
  function initialize() {
    if (ready || !configLoaded || !doctorLoaded || !haydenLoaded) return
    if (doctorSource.length > 262144 || haydenSource.length > 262144) { error = "Bundled script is too large (limit 262144 characters)"; return }
    var d = E.api.readScript(doctorSource), h = H.api.readScript(haydenSource)
    if (d[0] !== "success" || !h.ok) { error = d[0] !== "success" ? d[0] : h.error; return }
    error = ""
    ready = true
    newConversation(overlayOpen || bootRequested)
  }
  function setSetting(key, value) {
    var patch = {}; patch[key] = value
    config = ConfigStore.merge(config, patch)
    if (directoryReady) configFile.setText(ConfigStore.serialize(config))
    else configDirty = true
    if (key === "boot" && !boot && booting) finishBoot()
  }
  function setEra(id) {
    var next = Model.eraFor(id)
    if (next === era) return
    stopDemo(); setSetting("era", next); newConversation(true)
  }
  function toggleThoughts() { setSetting("thoughts", !thoughts) }
  function append(role, text, trace, elapsed) {
    while (conversation.count >= Model.MAX_ROWS) {
      var oldest = 0
      while (oldest < conversation.count && conversation.get(oldest).role === "boot") oldest++
      if (oldest === conversation.count) return
      conversation.remove(oldest)
    }
    conversation.append({role: role, text: text, trace: Model.capTrace(trace || ""), at: Date.now(), elapsed: Math.max(0.1, elapsed || 0)})
  }
  function newConversation(withBoot) {
    bootState = "idle"; bootText = ""; bootLines = []; bootRequested = !!withBoot
    pendingReply = ""; finished = false; memoryCount = 0; turns = 0; history = []
    conversation.clear()
    if (!ready) return
    // Hay's script rules contain reassembly cursors and memory: parse afresh.
    if (usesHayden) {
      var haydenScript = H.api.readScript(haydenSource).script
      keywordCount = haydenScript.keys.length
      engine = new H.api.Hayden(haydenScript)
      lastReply = engine.initial()
    } else {
      var script = E.api.readScript(doctorSource)[1]
      // NONE is the fallback rule, not a keyword matched against input.
      keywordCount = script.rules.size - (script.rules.has("zNONE") ? 1 : 0)
      engine = new E.api.Eliza(script.rules, script.memoryRule, new E.api.Tracer())
      lastReply = script.helloMessage.join(" ")
    }
    if (withBoot) startBoot()
    else if (overlayOpen || !boot) append("eliza", lastReply, "", 0)
  }
  function say(text) {
    text = String(text).slice(0, Model.MAX_INPUT_CHARS)
    if (!ready || typing || booting) return ""
    if (finished) { newConversation(); return lastReply }
    if (!String(text).trim()) return ""
    if (conversation.count === 0) append("eliza", lastReply, "", 0)
    history = history.concat([text]).slice(-20)
    append("user", era === "1966" ? text.toUpperCase() : text, "", 0)
    var start = Date.now(), response, trace = ""
    try {
      response = engine.response(text)
      if (!usesHayden) trace = Model.capTrace(engine.tracer.text())
    } catch (e) {
      response = usesHayden ? {text: "Please go on.", finished: false} : "PLEASE GO ON"
    }
    var elapsed = Date.now() - start
    finished = usesHayden && Model.isQuitReply(response)
    lastReply = usesHayden ? response.text : response
    memoryCount = usesHayden && engine.memory ? engine.memory.length : 0
    turns++
    append("eliza", era === "1966" ? "" : lastReply, trace, elapsed)
    if (era === "1966") { revealed = 0; pendingReply = lastReply }
    return lastReply
  }
  function finishTyping() {
    if (!typing) return
    conversation.setProperty(conversation.count - 1, "text", pendingReply)
    pendingReply = ""
  }
  function transcriptText() {
    var lines = []
    for (var i = 0; i < conversation.count; i++) {
      var entry = conversation.get(i)
      if (entry.role === "boot") continue
      lines.push(entry.role + ": " + (typing && i === conversation.count - 1 ? pendingReply : entry.text))
    }
    return lines.join("\n")
  }
  function statusLine() {
    return "era=" + era + ", script=" + scriptId + ", turns=" + turns + (demo ? ", demo=" + demoIndex + "/" + Demo.INPUTS.length : "") + ", thoughts=" + thoughts + ", showLabel=" + showLabel + ", blink=" + blink + ", engine=" + (usesHayden ? "Hayden Eliza 1.3" : "Hay 1.00") + (error || configError ? ", error=" + (error || configError) : "")
  }
}
