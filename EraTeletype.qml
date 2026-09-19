pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.Commons
import "Model.js" as Model

Rectangle {
  id: root
  property alias model: transcript.model
  property bool thoughtsOn: true
  property bool typing: false
  property bool booting: false
  property string bootText: ""
  property string phosphor: "green"
  readonly property color ink: phosphor === "amber" ? "#ffb347" : phosphor === "theme" ? Color.menu.text : "#5dff8a"
  readonly property color glow: phosphor === "amber" ? "#b8781f" : phosphor === "theme" ? Color.muted : "#2fbf5e"
  color: "#050806"; radius: 6
  border.color: Qt.rgba(Color.menu.text.r, Color.menu.text.g, Color.menu.text.b, 0.4)
  clip: true
  FontLoader { id: vt323; source: Qt.resolvedUrl("fonts/VT323-Regular.ttf") }
  function page(delta) { transcript.contentY = Math.max(transcript.originY, Math.min(transcript.originY + Math.max(0, transcript.contentHeight - transcript.height), transcript.contentY + delta * transcript.height * 0.8)) }
  Item {
    id: phosphorText
    anchors.fill: parent; anchors.margins: 12
    // MultiEffect needs a hardware/RHI scene graph; keep text visible on software renderers.
    layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
    layer.effect: MultiEffect { shadowEnabled: true; shadowColor: root.glow; shadowBlur: 1.0; shadowOpacity: 0.7; shadowHorizontalOffset: 0; shadowVerticalOffset: 0; blurMax: 8 }
    ListView {
      id: transcript
      anchors.fill: parent; anchors.leftMargin: 2; anchors.rightMargin: 2
      visible: !root.booting; clip: true; spacing: 0
      boundsBehavior: Flickable.StopAtBounds
      property int expandedIndex: -1
      function end() { Qt.callLater(function() { if (transcript.contentHeight > transcript.height) transcript.positionViewAtEnd(); else transcript.contentY = transcript.originY }) }
      onCountChanged: { expandedIndex = count - 1; end() }
      onContentHeightChanged: { if (root.typing) end(); else if (contentHeight <= height) contentY = originY }
      onHeightChanged: if (contentHeight <= height) contentY = originY
      Connections { target: root; function onThoughtsOnChanged() { transcript.expandedIndex = root.thoughtsOn ? transcript.count - 1 : -1; transcript.end() } }
      delegate: Column {
        id: entry
        required property int index
        required property string role
        required property string text
        required property string trace
        required property real elapsed
        width: transcript.width
        Column {
          width: parent.width
          visible: root.thoughtsOn && entry.role === "eliza" && entry.trace !== ""
          CrtText {
            width: parent.width; font.pixelSize: 14; opacity: 0.55
            text: (transcript.expandedIndex === entry.index ? "⌄ " : "› ") + "Thought for " + entry.elapsed.toFixed(1) + " ms"
            MouseArea { anchors.fill: parent; onClicked: { transcript.expandedIndex = transcript.expandedIndex === entry.index ? -1 : entry.index; transcript.end() } }
          }
          Flickable {
            width: parent.width; height: Math.min(90, rawTrace.implicitHeight)
            visible: transcript.expandedIndex === entry.index; clip: true
            contentHeight: rawTrace.implicitHeight; contentWidth: width
            CrtText { id: rawTrace; width: parent.width; text: Model.unescapeTrace(entry.trace); font.pixelSize: 14; opacity: 0.55; wrapMode: Text.Wrap }
          }
        }
        // The kept login matches the live boot view: 15 px, no tracking, one line each,
        // then a blank line so the program reads apart from the system.
        CrtText { visible: entry.role === "boot"; width: parent.width; text: entry.text; wrapMode: Text.NoWrap; font.pixelSize: 15; font.letterSpacing: 0; bottomPadding: lineHeight }
        CrtText { visible: entry.role !== "boot"; width: parent.width; text: (entry.role === "user" ? "> " : "") + entry.text + (root.typing && entry.index === transcript.count - 1 ? "▮" : "") }
      }
    }
    Flickable {
      id: bootView
      anchors.fill: parent; visible: root.booting; clip: true
      contentHeight: bootLabel.implicitHeight
      onContentHeightChanged: contentY = Math.max(0, contentHeight - height)
      // The CTSS login line is the widest thing the CRT ever shows; 15 px with no
      // tracking keeps it on one line at the card width, as a 7094 console would.
      CrtText { id: bootLabel; width: bootView.width; text: root.bootText + "▮"; wrapMode: Text.NoWrap
        font.pixelSize: 15; font.letterSpacing: 0
      }
      TextMetrics {
        id: bootMeasure
        font.family: vt323.name; font.pixelSize: 16; font.letterSpacing: 0.3
        text: root.bootText.split("\n").reduce(function(longest, line) { return line.length > longest.length ? line : longest }, "") + "▮"
      }
    }
  }
  Repeater {
    model: Math.floor(root.height / 3)
    Rectangle { required property int index; x: 1; y: index * 3 + 2; width: root.width - 2; height: 1; color: "black"; opacity: 0.28 }
  }
  Shape {
    width: 100; height: 100
    transform: Scale { xScale: root.width / 100; yScale: root.height / 100 }
    ShapePath {
      strokeColor: "transparent"
      fillGradient: RadialGradient {
        centerX: 50; centerY: 50
        centerRadius: 50
        focalX: centerX; focalY: centerY
        GradientStop { position: 0; color: "transparent" }
        GradientStop { position: 0.55; color: "transparent" }
        GradientStop { position: 1; color: "#8c000000" }
      }
      PathRectangle { x: 0; y: 0; width: 100; height: 100; radius: 1.5 }
    }
  }
  component CrtText: Text {
    textFormat: Text.PlainText; wrapMode: Text.Wrap
    color: root.ink; font.family: vt323.name; font.pixelSize: 16; font.letterSpacing: 0.3
    lineHeight: 18; lineHeightMode: Text.FixedHeight
    layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
    layer.effect: MultiEffect { shadowEnabled: true; shadowColor: root.ink; shadowBlur: 1; blurMax: 2; shadowOpacity: 0.5; shadowHorizontalOffset: 0; shadowVerticalOffset: 0 }
    style: Text.Outline; styleColor: Qt.rgba(root.glow.r, root.glow.g, root.glow.b, 0.25)
  }
}
