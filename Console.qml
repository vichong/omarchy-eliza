pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Ui as Ui
import qs.Commons
import "Model.js" as Model

// Everything inside the drop-down: header, era screen, input line and footer.
FocusScope {
  id: root
  property var service: null
  property bool opened: false
  property string tab: "chat"
  signal closeRequested()
  readonly property bool mac: !!service && service.era === "1985"
  readonly property color ink: Color.popups.text
  readonly property color paper: Color.popups.background
  readonly property color muted: Model.contrast(Color.muted, paper) >= 3 ? Color.muted : Qt.rgba(ink.r, ink.g, ink.b, 0.55)
  readonly property color screenBorder: Qt.rgba(ink.r, ink.g, ink.b, 0.4)
  readonly property var activeInput: input
  property int historyIndex: -1
  property string draft: ""
  function focusInput() { Qt.callLater(function() { if (root.opened) { if (root.tab === "chat" && root.activeInput.enabled) root.activeInput.forceActiveFocus(); else catcher.forceActiveFocus() } }) }
  function show(name) { tab = name === "settings" || name === "about" ? name : "chat"; focusInput() }
  function dismiss() { closeRequested() }
  // Quit ends the session: the next open starts over, boot sequence included.
  function quit() {
    dismiss()
    input.text = ""; draft = ""; historyIndex = -1
    // Closed first, so the boot waits for the next open instead of playing unseen.
    if (service) { service.overlayOpen = false; service.newConversation(true) }
  }
  function reboot() { tab = "chat"; input.text = ""; draft = ""; historyIndex = -1; if (service) service.reboot(); focusInput() }
  onOpenedChanged: focusInput()
  onTabChanged: focusInput()
  function setEra(id) { if (service) service.setEra(id); root.activeInput.text = ""; historyIndex = -1; focusInput() }
  function recall(delta) {
    if (!service || !service.history.length) return
    if (historyIndex < 0) { draft = root.activeInput.text; historyIndex = service.history.length }
    historyIndex = Math.max(0, Math.min(service.history.length, historyIndex + delta))
    root.activeInput.text = historyIndex === service.history.length ? draft : service.history[historyIndex]
    root.activeInput.cursorPosition = root.activeInput.text.length
  }
  function handleKey(event) {
    var ctrl = (event.modifiers & Qt.ControlModifier) !== 0
    if (idle.running) idle.restart()
    // Any key takes the conversation over from the demo, and is not typed into it.
    if (service && service.demo) { service.stopDemo(); root.activeInput.text = "" }
    else if (service && service.booting) { service.finishBoot() }
    else if (event.key === Qt.Key_Escape) { if (service && service.typing) service.finishTyping(); else dismiss() }
    else if (ctrl && event.key === Qt.Key_Q) quit()
    else if (ctrl && event.key === Qt.Key_R) reboot()
    else if (ctrl && event.key === Qt.Key_T && service) service.toggleThoughts()
    else if (ctrl && event.key === Qt.Key_N && service) { service.newConversation(); root.activeInput.text = ""; historyIndex = -1 }
    else if (ctrl && event.key === Qt.Key_1) setEra("1966")
    else if (ctrl && event.key === Qt.Key_2) setEra("1985")
    else if (ctrl && event.key === Qt.Key_Comma) tab = tab === "settings" ? "chat" : "settings"
    else if (event.key === Qt.Key_F1) tab = tab === "about" ? "chat" : "about"
    else if (tab === "chat" && (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown)) {
      var delta = event.key === Qt.Key_PageUp ? -1 : 1
      if (eraLoader.item as EraMac) (eraLoader.item as EraMac).page(delta)
      else if (eraLoader.item as EraTeletype) (eraLoader.item as EraTeletype).page(delta)
    }
    else if (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown) {
      var step = (event.key === Qt.Key_PageUp ? -1 : 1) * settingsView.height * 0.8
      settingsView.contentY = Math.max(0, Math.min(Math.max(0, settingsView.contentHeight - settingsView.height), settingsView.contentY + step))
    }
    else if (tab === "chat" && event.key === Qt.Key_Up) recall(-1)
    else if (tab === "chat" && event.key === Qt.Key_Down) recall(1)
    else return
    event.accepted = true
    if (tab === "chat") focusInput()
  }
  Connections {
    target: root.service
    function onTypingChanged() { root.focusInput() }
    function onBootingChanged() { root.focusInput() }
    function onDemoDraftChanged() { if (root.service.demo) root.activeInput.text = root.service.demoDraft }
    function onDemoChanged() { root.activeInput.text = "" }
    function onEraChanged() { root.activeInput.text = ""; root.historyIndex = -1; root.focusInput() }
  }
  // Attract mode: an untouched, empty conversation starts playing the 1966 paper.
  Timer {
    id: idle
    interval: 30000
    running: root.opened && root.tab === "chat" && !!root.service && root.service.demoIdle && !root.service.demo
      && root.service.turns === 0 && !root.service.booting && root.activeInput.text === ""
    onTriggered: root.service.startDemo()
  }
  MouseArea { anchors.fill: parent; onClicked: root.focusInput() }
  FocusScope {
    id: catcher
    anchors.fill: parent
    focus: true
    Keys.onPressed: function(event) { root.handleKey(event) }
    ColumnLayout {
      anchors.fill: parent
      spacing: Style.space(8)
      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Style.space(28)
        RowLayout {
          anchors.fill: parent
          spacing: Style.space(4)
          Text { text: "ELIZA"; color: root.ink; font.family: Style.font.family; font.pixelSize: Style.font.heading; font.bold: true }
          Item { Layout.fillWidth: true }
          EraSwitch {}
          Ui.Button {
            Layout.preferredWidth: Style.space(22); Layout.preferredHeight: Style.space(22)
            iconText: "\uf011"; tooltipText: "Restart (Ctrl+R)"
            foreground: hot || activeFocus ? root.ink : root.muted
            horizontalPadding: 0; verticalPadding: 0; focusable: true
            onClicked: root.reboot()
          }
          Ui.Button {
            Layout.preferredWidth: Style.space(22); Layout.preferredHeight: Style.space(22)
            iconText: root.tab === "chat" ? "" : ""
            foreground: hot || activeFocus ? root.ink : root.muted
            horizontalPadding: 0; verticalPadding: 0; focusable: true
            onClicked: root.tab = root.tab === "chat" ? "settings" : "chat"
          }
        }
      }
      // This fixed middle region keeps the input and footer still across tabs.
      Item {
        Layout.fillWidth: true; Layout.fillHeight: true
        Item {
          id: screen
          anchors.fill: parent
          Loader {
            id: eraLoader
            anchors.fill: parent; visible: root.tab === "chat"
            active: !!root.service && root.service.ready && !root.service.error
            sourceComponent: root.mac ? macEra : ttyEra
          }
          Rectangle {
            anchors.fill: parent
            visible: root.tab !== "chat" || !eraLoader.active
            color: Qt.darker(root.paper, 1.25); border.color: root.screenBorder; border.width: 1
          }
          Text {
            anchors.fill: parent; anchors.margins: 12
            visible: root.tab === "chat" && !eraLoader.active
            text: root.service ? root.service.error || "Loading ELIZA…" : "Waiting for ELIZA service…"
            color: root.ink; font.family: Style.font.family; font.pixelSize: Style.font.body
            wrapMode: Text.Wrap; textFormat: Text.PlainText
          }
          ColumnLayout {
            anchors.fill: parent; anchors.margins: 12
            visible: root.tab !== "chat"
            spacing: Style.space(8)
            Segments {
              options: [{value: "chat", label: "Chat"}, {value: "settings", label: "Settings"}, {value: "about", label: "About"}]
              value: root.tab
              onChanged: function(value) { root.tab = value }
            }
            Flickable {
              id: settingsView
              Layout.fillWidth: true; Layout.fillHeight: true
              clip: true; boundsBehavior: Flickable.StopAtBounds
              contentWidth: width
              contentHeight: root.tab === "settings" ? settingsColumn.implicitHeight : aboutColumn.implicitHeight
              Connections { target: root; function onTabChanged() { settingsView.contentY = 0 } }
              Column {
                id: settingsColumn
                visible: root.tab === "settings"
                width: settingsView.width; spacing: Style.spacing.md
                Caption { text: "Switching starts a new conversation." }
                SettingRow {
                  FieldLabel { text: "Era"; Layout.fillWidth: true }
                  EraSwitch {}
                }
                Repeater {
                  model: [{key: "boot", label: "Play boot sequences"}, {key: "demoIdle", label: "Play demo when idle"}, {key: "blink", label: "Blink bar mark"}, {key: "showLabel", label: "Show ELIZA label"}, {key: "macPaper", label: "1985 black on white"}]
                  Ui.Toggle {
                    required property var modelData
                    width: settingsColumn.width; height: Style.space(30)
                    label: modelData.label; titleSize: Style.font.body
                    foreground: root.ink
                    checked: !!root.service && !!root.service.config[modelData.key]
                    onClicked: if (root.service) root.service.setSetting(modelData.key, !checked)
                  }
                }
                SettingRow {
                  FieldLabel { text: "Phosphor"; Layout.fillWidth: true }
                  Segments {
                    options: [{value: "green", label: "Green"}, {value: "amber", label: "Amber"}, {value: "theme", label: "Theme"}]
                    value: root.service ? root.service.phosphor : "green"
                    onChanged: function(value) { if (root.service) root.service.setSetting("phosphor", value) }
                  }
                }
                SettingRow {
                  FieldLabel { text: "Teletype speed (chars/s)"; Layout.fillWidth: true }
                  Ui.NumberField {
                    from: 5; to: 60; value: root.service ? root.service.teletypeCps : 15
                    foreground: root.ink; fieldWidth: Style.space(90)
                    field.height: Style.space(30)
                    onModified: function(value) { if (root.service) root.service.setSetting("teletypeCps", value) }
                  }
                }
                Row {
                  spacing: Style.spacing.md
                  Ui.Button { text: "New conversation"; fontSize: Style.font.caption; height: Style.space(30); foreground: root.ink; bordered: true; focusable: true; onClicked: { if (root.service) root.service.newConversation(); root.tab = "chat" } }
                  Ui.Button { text: "Copy transcript"; fontSize: Style.font.caption; height: Style.space(30); foreground: root.ink; bordered: true; focusable: true; onClicked: if (root.service) root.service.copyTranscript() }
                }
                Row {
                  spacing: Style.spacing.md
                  Ui.Button { text: "Play demo"; fontSize: Style.font.caption; height: Style.space(30); foreground: root.ink; bordered: true; focusable: true; onClicked: { root.tab = "chat"; if (root.service) root.service.startDemo() } }
                  Ui.Button { text: "Quit ELIZA"; fontSize: Style.font.caption; height: Style.space(30); foreground: root.ink; bordered: true; focusable: true; onClicked: root.quit() }
                }
                Caption { text: "Quit ends the conversation and closes ELIZA. The bar mark stays." }
                Caption { visible: text !== ""; text: root.service ? root.service.configError : "" }
                Caption { visible: text !== ""; text: root.service ? root.service.copyStatus : "" }
              }
              Column {
                id: aboutColumn
                width: settingsView.width; visible: root.tab === "about"
                spacing: Style.spacing.md
                AboutText { text: "ELIZA is Joseph Weizenbaum’s 1966 program for studying conversation between people and computers. Her DOCTOR script plays a therapist by matching patterns in what you type and handing your own words back." }
                // The warning is the point of the homage, so it gets the one emphasis on the page.
                Row {
                  width: aboutColumn.width; spacing: Style.space(10)
                  Rectangle { width: Style.space(2); height: quote.height; color: Color.accent }
                  Column {
                    id: quote
                    width: parent.width - Style.space(12); spacing: Style.space(4)
                    AboutText { width: parent.width; text: "“I had not realized that extremely short exposures to a relatively simple computer program could induce powerful delusional thinking in quite normal people.”" }
                    AboutNote { width: parent.width; text: "Joseph Weizenbaum, Computer Power and Human Reason, 1976" }
                  }
                }
                AboutHeading { text: "The name" }
                AboutText { text: "She is named after Eliza Doolittle of Pygmalion, because she could be taught. Typing + put the original into a teaching mode, PLEASE INSTRUCT ME, where rules could be added, ranked and saved. The 1966 paper gives it one sentence." }
                AboutHeading { text: "The code" }
                AboutText { text: "The original source was found in Weizenbaum’s papers at MIT in 2021 and released CC0 by his estate. It has since run again on a restored CTSS (ELIZA Reanimated, 2025), which is how the teaching mode came back to light." }
                AboutHeading { text: "Credits" }
                Repeater {
                  model: [
                    {who: "Anthony and Max Hay", what: "the 1966 engine, CC0"},
                    {who: "Charles Hayden", what: "Eliza 1.3 for Macintosh, 1985"},
                    {who: "The ELIZA Archaeology Project", what: "finding and restoring the original"},
                    {who: "Lane, Hay, Schwarz, Berry, Shrager", what: "ELIZA Reanimated, source of the CTSS login"},
                    {who: "Peter Hull", what: "VT323 font, SIL OFL"},
                    {who: "Robin Casady", what: "ChicagoFLF font, public domain"},
                    {who: "Susan Kare", what: "the Macintosh startup icons, redrawn here as a tribute"}
                  ]
                  Column {
                    id: credit
                    required property var modelData
                    width: aboutColumn.width; spacing: 0
                    AboutText { width: parent.width; text: credit.modelData.who; lineHeight: 1.2 }
                    AboutNote { width: parent.width; text: credit.modelData.what }
                  }
                }
                AboutNote { text: "Not affiliated with Apple, MIT or Omarchy. Full notices are in THIRD_PARTY_NOTICES.md." }
                AboutHeading { text: "Read more" }
                Text {
                  width: aboutColumn.width
                  text: '<a href="https://findingeliza.org">findingeliza.org</a><br><a href="https://github.com/anthay/ELIZA">github.com/anthay/ELIZA</a><br><a href="https://chayden.net/eliza">chayden.net/eliza</a><br><a href="https://arxiv.org/abs/2501.06707">arxiv.org/abs/2501.06707</a>'
                  textFormat: Text.StyledText; wrapMode: Text.Wrap; lineHeight: 1.5
                  color: root.ink; linkColor: Color.accent; font.family: Style.font.family; font.pixelSize: Style.font.caption
                  onLinkActivated: function(link) { Qt.openUrlExternally(link) }
                }
                Item { width: 1; height: Style.space(4) }
              }
            }
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.screenBorder; opacity: 0.6 }
            // Version comes from the manifest so it never drifts from the tag.
            Row {
              Layout.fillWidth: true
              spacing: Style.spacing.xs
              Caption { width: implicitWidth; text: "ELIZA v" + (root.service && root.service.manifest && root.service.manifest.version ? root.service.manifest.version : "?") + " \u00b7" }
              Caption {
                id: repoLink
                readonly property string url: "https://github.com/vichong/omarchy-eliza"
                width: implicitWidth; text: "github.com/vichong/omarchy-eliza"
                color: repoHover.hovered ? root.ink : root.muted
                font.underline: repoHover.hovered
                HoverHandler { id: repoHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Qt.openUrlExternally(repoLink.url) }
              }
            }
          }
        }
      }
      Rectangle {
        opacity: root.tab === "chat" ? 1 : 0
        enabled: root.tab === "chat"
        color: "transparent"; border.color: root.screenBorder
        Layout.preferredHeight: Style.space(30)
        Layout.fillWidth: true
        RowLayout {
          anchors.fill: parent; anchors.leftMargin: Style.space(10); anchors.rightMargin: Style.space(10)
          spacing: Style.space(8)
          Text { text: "›"; color: Color.accent; font.family: Style.font.family; font.pixelSize: Style.font.body }
          Ui.TextField {
            id: input
            maximumLength: Model.MAX_INPUT_CHARS
            Layout.fillWidth: true; Layout.fillHeight: true
            enabled: !!root.service && root.service.ready && !root.service.typing && !root.service.booting
            foreground: root.ink
            font.family: Style.font.family
            placeholderText: root.service && root.service.booting ? (root.service.era === "1966" ? "logging in to CTSS…" : "starting up…") : root.service && root.service.typing ? "ELIZA is typing at " + root.service.teletypeCps + " characters a second" : root.service && root.service.finished ? "Conversation over. Enter starts a new one." : ""
            font.pixelSize: Style.font.body
            leftPadding: Style.space(5)
            background: Item {}
            verticalPadding: 0
            cursorDelegate: Rectangle {
              width: Style.space(7); height: Style.space(15)
              color: root.ink; visible: input.activeFocus && cursorOn
              property bool cursorOn: true
              Timer { interval: 600; repeat: true; running: input.activeFocus; onTriggered: parent.cursorOn = !parent.cursorOn }
            }
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: function(event) { root.handleKey(event) }
            onAccepted: {
              if (!root.service) return
              if (root.service.finished) root.service.newConversation()
              else if (text.trim()) root.service.say(text)
              else return
              text = ""; root.historyIndex = -1; root.draft = ""
            }
          }
        }
      }
      Item {
        id: footer
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(footerHint.implicitHeight, turnLabel.implicitHeight, traceRow.implicitHeight)
        opacity: root.tab === "chat" ? 1 : 0
        // 1966 only: the trace is Hay's modern look inside the machine, so it is opt-in.
        Row {
          id: traceRow
          anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(6)
          visible: !root.mac && footerHint.text === ""
          enabled: root.tab === "chat"
          Text { anchors.verticalCenter: parent.verticalCenter; text: "Trace"; color: root.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
          Ui.ToggleSwitch {
            anchors.verticalCenter: parent.verticalCenter
            trackHeight: Style.space(14)
            foreground: root.ink
            checked: !!root.service && root.service.thoughts
            onToggled: { if (root.service) root.service.toggleThoughts(); root.focusInput() }
          }
        }
        Text {
          id: footerHint
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - turnLabel.implicitWidth - Style.space(6)
          text: root.service && root.service.booting ? "any key or click skips" : root.service && root.service.demo ? "demo · any key takes over" : ""
          wrapMode: Text.Wrap; textFormat: Text.PlainText
          color: root.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption
        }
        Text {
          id: turnLabel
          anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right
          text: "turn " + (root.service ? root.service.turns : 0) + (root.mac && root.service ? " · Memory: " + root.service.memoryCount : "")
          color: root.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption
        }
      }
    }
  }
  // Consume the skip click before any control can act on it.
  MouseArea {
    anchors.fill: parent; z: 100
    visible: !!root.service && root.service.booting
    onClicked: { root.service.finishBoot(); root.focusInput() }
  }
  Component { id: ttyEra; EraTeletype { model: root.service.conversation; thoughtsOn: root.service.thoughts; typing: root.service.typing; bootText: root.service.bootText; booting: root.service.booting; phosphor: root.service.phosphor } }
  Component {
    id: macEra
    EraMac {
      model: root.service.conversation
      ink: root.service.macPaper ? "#000000" : root.ink
      paper: root.service.macPaper ? "#ffffff" : root.paper
      booting: root.service.booting
      bootBeat: root.service.bootBeat
      onCloseRequested: root.dismiss()
    }
  }
  // ButtonGroup's native Buttons, with compact dimensions shared by every picker.
  component Segments: Row {
    id: group
    property var options: []
    property string value: ""
    signal changed(string value)
    spacing: 0
    Repeater {
      model: group.options
      Ui.Button {
        required property var modelData
        text: modelData.label
        selected: group.value === modelData.value
        foreground: root.muted; accent: Color.menu.selectedText
        background: "transparent"; bordered: true; focusable: true
        fontSize: Style.font.caption
        horizontalPadding: Style.space(10); verticalPadding: 0
        height: Style.space(22)
        onClicked: group.changed(modelData.value)
      }
    }
  }
  component EraSwitch: Segments {
    options: [{value: "1966", label: "1966"}, {value: "1985", label: "1985"}]
    value: root.service ? root.service.era : "1966"
    onChanged: function(value) { root.setEra(value) }
  }
  component SettingRow: RowLayout {
    width: settingsColumn.width; height: Style.space(30)
    spacing: Style.spacing.md
  }
  component AboutText: Text { width: aboutColumn.width; color: root.ink; font.family: Style.font.family; font.pixelSize: Style.font.body; lineHeight: 1.35; wrapMode: Text.Wrap; textFormat: Text.PlainText }
  component AboutNote: Text { width: aboutColumn.width; color: root.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; lineHeight: 1.3; wrapMode: Text.Wrap; textFormat: Text.PlainText }
  component AboutHeading: Text { width: aboutColumn.width; topPadding: Style.space(6); color: root.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; font.capitalization: Font.AllUppercase; font.letterSpacing: 1.5; textFormat: Text.PlainText }
  component FieldLabel: Text { color: root.muted; font.family: Style.font.family; font.pixelSize: Style.font.body; textFormat: Text.PlainText }
  component Caption: Text { width: settingsColumn.width; color: root.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.Wrap; textFormat: Text.PlainText }
}
