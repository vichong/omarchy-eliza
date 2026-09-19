import QtQuick
import Quickshell.Io
import qs.Ui as Ui
import qs.Commons

Ui.Panel {
  id: root
  moduleName: "io.github.vichong.eliza"
  ipcTarget: "eliza"
  manageIpc: false
  readonly property var service: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
  readonly property bool solid: service && (service.overlayOpen || service.typing)
  readonly property string family: bar ? bar.fontFamily : Style.font.family
  property bool blinkOn: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  function summon(tab) { eliza.show(tab); open() }
  function quit() { close(); if (service) { service.overlayOpen = false; service.newConversation(true) } }
  onOpenedChanged: if (service) service.overlayOpen = opened
  Component.onDestruction: if (service) service.overlayOpen = false
  Timer {
    interval: 600; repeat: true
    running: !!root.service && root.service.blink && !root.solid
    onTriggered: root.blinkOn = !root.blinkOn
    onRunningChanged: root.blinkOn = true
  }
  IpcHandler {
    target: "eliza"
    function open(): void { root.summon("chat") }
    function close(): void { root.close() }
    function quit(): void { root.quit() }
    function toggle(): void { if (root.opened) root.close(); else root.summon("chat") }
    function settings(): void { root.summon("settings") }
    function about(): void { root.summon("about") }
    function newConversation(): void { if (root.service) root.service.newConversation() }
    function era(name: string): void { if (root.service) root.service.setEra(name) }
    function thoughts(): void { if (root.service) root.service.toggleThoughts() }
    function demo(): void { root.summon("chat"); if (root.service) root.service.startDemo() }
    function copy(): void { if (root.service) root.service.copyTranscript() }
    function say(text: string): string { return root.service ? root.service.say(text) : "" }
    function status(): string { return root.service ? root.service.statusLine() : "service: UNREACHABLE" }
  }
  Ui.WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    fixedWidth: pill.implicitWidth + scaledHorizontalMargin * 2
    fixedHeight: vertical ? Style.bar.iconSlot : -1
    tooltipText: root.service && root.service.lastReply ? root.service.lastReply : "ELIZA"
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) root.summon("settings")
      else if (mouseButton === Qt.MiddleButton) { if (root.service) root.service.newConversation() }
      else if (root.opened) root.close()
      else root.summon("chat")
    }
    Row {
      id: pill
      anchors.centerIn: parent
      spacing: Style.space(2)
      Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        visible: !!root.service && root.service.showLabel
        text: "ELIZA"
        color: root.solid ? Color.accent : root.barForeground
        font.family: root.family
        font.pixelSize: Style.font.body
      }
      Item {
        id: markSlot
        // Next to the label the block is the same width and height as the
        // capital A it follows: the painted box of "A" in the label's font.
        // Without the label it takes a bar glyph's painted box, like other marks.
        readonly property bool cell: !!root.service && root.service.showLabel
        readonly property rect glyphBox: cell ? aMetrics.tightBoundingRect : glyphMetrics.tightBoundingRect
        // Native glyph rendering hints the A one hairline narrower and shorter
        // than its outline metrics (measured at 2x: outline 12x16, painted 10x14),
        // so the block trims a hairline off the outline box to sit on the pixels.
        readonly property int trim: cell ? Style.space(1) : 0
        readonly property real glyphTop: cell
          ? label.y + label.baselineOffset + aMetrics.tightBoundingRect.y + trim
          : glyphRef.y + glyphRef.baselineOffset + glyphMetrics.tightBoundingRect.y
        width: Math.max(1, Math.round(glyphBox.width) - trim)
        height: button.height
        Text {
          id: glyphRef
          anchors.centerIn: parent
          opacity: 0
          text: "󰖩"
          font.family: root.family
          font.pixelSize: Style.bar.iconFont
          renderType: Text.NativeRendering
        }
        TextMetrics { id: glyphMetrics; font: glyphRef.font; text: glyphRef.text }
        TextMetrics { id: aMetrics; font.family: root.family; font.pixelSize: Style.font.body; text: "A" }
        Rectangle {
          y: markSlot.glyphTop
          width: markSlot.width
          height: Math.max(1, Math.round(markSlot.glyphBox.height) - markSlot.trim)
          color: root.solid ? Color.accent : root.barForeground
          visible: root.solid || !root.service || !root.service.blink || root.blinkOn
        }
      }
    }
  }
  Ui.KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: eliza
    padding: Style.spacing.panelPadding
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.cappedContentHeight(Style.space(500))
    Console {
      id: eliza
      anchors.fill: parent
      service: root.service
      opened: root.opened
      onCloseRequested: root.close()
    }
  }
}
