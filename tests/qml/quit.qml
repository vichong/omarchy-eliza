import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import Quickshell.Io
import qs.Ui as Ui
import "." as Eliza
import "ConfigStore.js" as ConfigStore

// Run with tests/test_quit.js: real Console, shell buttons/panel lifecycle,
// and Service/engines, but an offscreen window and an isolated HOME.
Window {
  id: window
  property bool transientDestroyed: false
  visible: true
  width: 400; height: 500
  Eliza.Service { id: service }
  Component {
    id: transientService
    Eliza.Service { Component.onDestruction: window.transientDestroyed = true }
  }
  FileView { id: cliCalls; path: Quickshell.env("ELIZA_QUIT_CLI_CALLS"); blockLoading: true; blockAllReads: true; blockWrites: true }
  FileView { id: ipcCalls; path: Quickshell.env("ELIZA_QUIT_IPC_CALLS"); blockLoading: true; blockAllReads: true; blockWrites: true }
  FileView { id: notices; path: Quickshell.env("ELIZA_QUIT_NOTICES"); blockLoading: true; blockAllReads: true; blockWrites: true }
  FileView { id: failureFlag; path: Quickshell.env("ELIZA_QUIT_FAILURE_FLAG"); blockLoading: true; blockAllReads: true; blockWrites: true }
  Ui.Panel {
    id: host
    anchors.fill: parent
    manageIpc: false
    onOpenedChanged: service.overlayOpen = opened
    Eliza.Console {
      id: elizaConsole
      anchors.fill: parent
      service: service
      opened: host.opened
      onCloseRequested: host.close()
    }
  }
  TestCase {
    name: "Quit"
    when: true
    property string beforeCli: ""
    property string beforeIpc: ""
    property string beforeNotices: ""

    function captureBefore() {
      cliCalls.reload(); ipcCalls.reload(); notices.reload()
      beforeCli = cliCalls.text(); beforeIpc = ipcCalls.text(); beforeNotices = notices.text()
    }
    function cleanup() { failureFlag.setText("") }

    function expect(actual, expected, label) {
      if (actual !== expected)
        console.error("FAIL Quit " + qtest_results.functionName + "/" + qtest_results.dataTag + ": " + label + ": expected " + expected + ", got " + actual)
      compare(actual, expected, label)
    }
    function initTestCase() {
      tryCompare(service, "ready", true, 3000)
      // Pin startup data and timers; no live environment affects test verdicts.
      service.bootProbe.running = false
      service.probeDeadline.running = false
      service.shellConfigRead.running = false
    }
    function prepare(era, mode, tab) {
      captureBefore()
      failureFlag.setText("")
      host.close()
      service.config = ConfigStore.merge(ConfigStore.defaults(), {era: era, boot: true, demoIdle: false})
      service.liveReady = mode !== "waiting"
      service.clockReady = true
      elizaConsole.show(tab)
      host.open()
      if (mode === "idle") { service.newConversation(); service.say("hello") }
      else service.reboot()
      service.bootTimer.stop()
      expect(service.bootState, mode, "pinned boot state")
      service.turns = 3
      service.history = ["hello"]
      elizaConsole.activeInput.text = "unfinished input"
      elizaConsole.draft = "old draft"
      elizaConsole.historyIndex = 0
      wait(20)
    }
    function findButton(item, label) {
      if (item.text === label && item.clicked) return item
      for (var i = 0; i < item.children.length; i++) {
        var found = findButton(item.children[i], label)
        if (found) return found
      }
      return null
    }
    function quitButton() {
      var button = findButton(elizaConsole, "Quit ELIZA")
      verify(button !== null, "real Quit button exists")
      var row = button.parent
      var column = row.parent
      var view = column.parent.parent
      view.contentY = Math.max(0, row.y + row.height - view.height)
      wait(20)
      return button
    }
    function verifyQuit() {
      ipcCalls.reload()
      for (var i = 0; i < 150 && ipcCalls.text() === beforeIpc; i++) { wait(10); ipcCalls.reload() }
      // Allow a late duplicate to arrive before checking cumulative captures.
      wait(100)
      ipcCalls.reload(); cliCalls.reload()
      expect(ipcCalls.text(), beforeIpc + "shell\nsetPluginEnabled\nio.github.vichong.eliza\nfalse\n", "same IPC as Disable Plugin menu")
      expect(cliCalls.text(), beforeCli + "plugin\ndisable\nio.github.vichong.eliza\n", "supported disable command, exactly once")
      // IPC is intercepted, so no actual plugin unloading/config change occurs.
    }
    function test_settingsClick_data() {
      var rows = []
      for (var era of ["1966", "1985"])
        for (var mode of ["idle", "waiting", "playing"])
          rows.push({tag: era + "-" + mode, era: era, mode: mode})
      return rows
    }
    function test_settingsClick(data) {
      prepare(data.era, data.mode, "settings")
      var button = quitButton()
      mouseClick(button, button.width / 2, button.height / 2)
      verifyQuit()
    }
    function test_shortcut_data() {
      var rows = []
      for (var row of test_settingsClick_data())
        for (var tab of ["chat", "settings"])
          rows.push({tag: row.tag + "-" + tab, era: row.era, mode: row.mode, tab: tab})
      return rows
    }
    function test_shortcut(data) {
      prepare(data.era, data.mode, data.tab)
      // Model Q arriving with Ctrl already held. QtTest keyClick synthesizes
      // a preceding Ctrl press, which skips boot and would mask this bug.
      var event = {key: Qt.Key_Q, modifiers: Qt.ControlModifier, accepted: false}
      elizaConsole.handleKey(event)
      expect(event.accepted, true, "shortcut consumed")
      verifyQuit()
    }
    function test_shortcutDelivery() {
      prepare("1966", "idle", "settings")
      keyClick(Qt.Key_Q, Qt.ControlModifier)
      verifyQuit()
    }
    function test_failedDisable_data() { return [{tag: "unknown", failure: "unknown"}, {tag: "launch", failure: "launch"}] }
    function test_failedDisable(data) {
      prepare("1966", "idle", "settings")
      failureFlag.setText(data.failure)
      var button = quitButton()
      mouseClick(button, button.width / 2, button.height / 2)
      notices.reload()
      for (var i = 0; i < 150 && notices.text() === beforeNotices; i++) { wait(10); notices.reload() }
      expect(notices.text(), beforeNotices + "Could not disable ELIZA\nTry Omarchy's Disable Plugin menu.\n", "failed Quit must notify, not silently do nothing")
      failureFlag.setText("")
    }
    function test_disableSurvivesServiceUnload() {
      captureBefore()
      window.transientDestroyed = false
      var temporary = transientService.createObject(window)
      temporary.quit()
      temporary.destroy()
      tryCompare(window, "transientDestroyed", true, 500)
      // The test CLI delays its IPC until after this destruction.
      verifyQuit()
    }
    function test_chatClickStillSkipsBoot() {
      prepare("1966", "playing", "chat")
      mouseClick(elizaConsole, 200, 200)
      expect(service.booting, false, "chat click skips boot")
      expect(host.opened, true, "chat skip does not quit")
    }
    function cleanupTestCase() {
      console.log("QUIT REGRESSION: " + qtest_results.failCount + " failures, " + qtest_results.passCount + " passed")
      Qt.exit(qtest_results.failCount ? 1 : 0)
    }
  }
}
