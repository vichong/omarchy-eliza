pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import qs.Commons

Rectangle {
  id: root
  property alias model: transcript.model
  property color ink: Color.menu.text
  property color paper: Color.menu.background
  property bool thoughtsOn: false
  property bool typing: false
  property bool booting: false
  property int bootBeat: 0
  property bool questionVisible: true
  onBootingChanged: questionVisible = true
  Timer { interval: 500; repeat: true; running: root.booting && root.bootBeat === 0; onTriggered: root.questionVisible = !root.questionVisible }
  signal closeRequested()
  color: paper
  border.color: Qt.rgba(Color.menu.text.r, Color.menu.text.g, Color.menu.text.b, 0.4)
  clip: true
  FontLoader { id: chicago; source: Qt.resolvedUrl("fonts/ChicagoFLF.ttf") }
  function page(delta) { scrollTo(transcript.contentY + delta * transcript.height * 0.8) }
  function scrollTo(y) { transcript.contentY = Math.max(transcript.originY, Math.min(transcript.originY + scrollRange, y)) }
  readonly property real scrollRange: Math.max(0, transcript.contentHeight - transcript.height)

  Rectangle {
    visible: !root.booting
    x: window.x + 2; y: window.y + 2
    width: window.width; height: window.height; color: root.ink
  }
  Rectangle {
    id: window
    x: 8; y: 8
    visible: !root.booting
    width: root.width - 16; height: root.height - 16
    color: root.paper; border.color: root.ink; border.width: 1
    Item {
      id: titleBar
      x: 1; y: 1; width: parent.width - 2; height: 19
      Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.ink }
      Repeater {
        model: 4
        Rectangle {
          required property int index
          x: 18; y: 3 + index * 3; width: titleBar.width - 51; height: 1; color: root.ink
        }
      }
      Rectangle {
        x: 3; width: 11; height: 11; anchors.verticalCenter: parent.verticalCenter
        color: root.paper; border.color: root.ink
        MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }
      }
      Rectangle {
        anchors.centerIn: parent; width: title.implicitWidth + 12; height: 18; color: root.paper
        Text {
          id: title; anchors.centerIn: parent; text: "Eliza"
          font.family: chicago.name; font.pixelSize: 12; font.bold: true; color: root.ink
        }
      }
      Repeater {
        model: 2
        Rectangle {
          required property int index
          x: titleBar.width - 14 - index * 15
          width: 11; height: 11; anchors.verticalCenter: parent.verticalCenter
          color: root.paper; border.color: root.ink
        }
      }
    }
    Item {
      id: body
      anchors { top: titleBar.bottom; bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 1; rightMargin: 1 }
      ListView {
        id: transcript
        anchors { fill: parent; leftMargin: 10; rightMargin: 25; topMargin: 8; bottomMargin: 8 }
        clip: true; spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        onCountChanged: Qt.callLater(function() { if (transcript.contentHeight > transcript.height) transcript.positionViewAtEnd(); else transcript.contentY = transcript.originY })
        onContentHeightChanged: if (contentHeight <= height) contentY = originY
        onHeightChanged: if (contentHeight <= height) contentY = originY
        delegate: Text {
          required property string role
          required property var model
          width: transcript.width
          text: model.text; textFormat: Text.PlainText; wrapMode: Text.Wrap
          color: root.ink; font.family: chicago.name; font.pixelSize: 12
          font.bold: role === "eliza"
          lineHeight: 18; lineHeightMode: Text.FixedHeight
        }

      }
      Rectangle {
        id: scrollbar
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
        width: 15; color: root.paper
        Rectangle { width: 1; height: parent.height; color: root.ink }
        Item {
          id: track
          x: 1; y: 15; width: 14; height: Math.max(0, parent.height - 30)
          clip: true
          Repeater {
            model: Math.ceil((track.height + track.width) / 3)
            Rectangle {
              required property int index
              x: 0; y: index * 3 - track.width; width: 22; height: 1
              rotation: 45; transformOrigin: Item.TopLeft; color: root.ink; opacity: 0.35
            }
          }
          MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) { root.page(mouse.y < thumb.y ? -1 : 1) }
            onWheel: function(wheel) { root.scrollTo(transcript.contentY - wheel.angleDelta.y / 3); wheel.accepted = true }
          }
          Rectangle {
            id: thumb
            width: track.width
            height: Math.min(track.height, Math.max(15, track.height * transcript.height / Math.max(1, transcript.contentHeight)))
            y: root.scrollRange > 0 ? (track.height - height) * (transcript.contentY - transcript.originY) / root.scrollRange : 0
            visible: root.scrollRange > 0
            color: root.paper; border.color: root.ink
            MouseArea {
              anchors.fill: parent
              property real startY: 0
              property real startContent: 0
              onPressed: function(mouse) { startY = mapToItem(track, mouse.x, mouse.y).y; startContent = transcript.contentY }
              onPositionChanged: function(mouse) {
                if (pressed && track.height > thumb.height)
                  root.scrollTo(startContent + (mapToItem(track, mouse.x, mouse.y).y - startY) * root.scrollRange / (track.height - thumb.height))
              }
            }
          }
        }
        Repeater {
          model: 2
          Rectangle {
            id: arrow
            required property int index
            x: 0; y: index === 0 ? 0 : scrollbar.height - 15
            width: 15; height: 15; color: root.paper; border.color: root.ink
            Repeater {
              model: 4
              Rectangle {
                required property int index
                width: 1 + index * 2; height: 1; x: (15 - width) / 2
                y: arrow.index === 0 ? 5 + index : 8 - index; color: root.ink
              }
            }
            MouseArea {
              id: arrowMouse
              anchors.fill: parent
              onPressed: root.scrollTo(transcript.contentY + (arrow.index === 0 ? -18 : 18))
              Timer {
                interval: 100; repeat: true; running: arrowMouse.pressed
                onTriggered: root.scrollTo(transcript.contentY + (arrow.index === 0 ? -18 : 18))
              }
            }
          }
        }
      }
    }
  }
  Item {
    anchors.fill: parent; anchors.margins: 1
    visible: root.booting
    Canvas {
      id: dither
      anchors.fill: parent
      onWidthChanged: requestPaint()
      onHeightChanged: requestPaint()
      Connections { target: root; function onInkChanged() { dither.requestPaint() } }
      onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height); ctx.fillStyle = root.ink; ctx.globalAlpha = 0.5
        for (var row = 0; row < height; row += 2)
          for (var col = 0; col < width; col += 2) {
            ctx.fillRect(col, row, 1, 1); ctx.fillRect(col + 1, row + 1, 1, 1)
          }
      }
    }
    // Startup icons redrawn pixel by pixel after the 1984 Macintosh originals, at 2x: a 512-wide Mac
    // screen scaled to this card puts the 1-bit icons near 1x, so 2x keeps the
    // strokes as thin as they read on a real System 1 screen.
    Shape {
      anchors.centerIn: parent
      width: root.bootBeat === 0 ? 48 : 64; height: root.bootBeat === 0 ? 48 : 60
      visible: root.bootBeat < 2
      ShapePath {
        strokeColor: "transparent"; fillColor: root.ink; scale: Qt.size(2, 2)
        PathSvg { path: root.bootBeat === 0 ? "M1 1h1v1h-1zM2 1h1v1h-1zM3 1h1v1h-1zM4 1h1v1h-1zM5 1h1v1h-1zM6 1h1v1h-1zM7 1h1v1h-1zM8 1h1v1h-1zM9 1h1v1h-1zM10 1h1v1h-1zM11 1h1v1h-1zM12 1h1v1h-1zM13 1h1v1h-1zM14 1h1v1h-1zM15 1h1v1h-1zM16 1h1v1h-1zM17 1h1v1h-1zM18 1h1v1h-1zM19 1h1v1h-1zM20 1h1v1h-1zM21 1h1v1h-1zM22 1h1v1h-1zM1 2h1v1h-1zM22 2h1v1h-1zM1 3h1v1h-1zM7 3h1v1h-1zM8 3h1v1h-1zM9 3h1v1h-1zM10 3h1v1h-1zM11 3h1v1h-1zM12 3h1v1h-1zM13 3h1v1h-1zM14 3h1v1h-1zM22 3h1v1h-1zM1 4h1v1h-1zM7 4h1v1h-1zM14 4h1v1h-1zM22 4h1v1h-1zM1 5h1v1h-1zM7 5h1v1h-1zM10 5h1v1h-1zM11 5h1v1h-1zM14 5h1v1h-1zM22 5h1v1h-1zM1 6h1v1h-1zM7 6h1v1h-1zM10 6h1v1h-1zM11 6h1v1h-1zM14 6h1v1h-1zM22 6h1v1h-1zM1 7h1v1h-1zM7 7h1v1h-1zM8 7h1v1h-1zM9 7h1v1h-1zM10 7h1v1h-1zM11 7h1v1h-1zM12 7h1v1h-1zM13 7h1v1h-1zM14 7h1v1h-1zM22 7h1v1h-1zM1 8h1v1h-1zM22 8h1v1h-1zM1 9h1v1h-1zM22 9h1v1h-1zM1 10h1v1h-1zM22 10h1v1h-1zM1 11h1v1h-1zM4 11h1v1h-1zM5 11h1v1h-1zM6 11h1v1h-1zM7 11h1v1h-1zM8 11h1v1h-1zM9 11h1v1h-1zM10 11h1v1h-1zM11 11h1v1h-1zM12 11h1v1h-1zM13 11h1v1h-1zM14 11h1v1h-1zM15 11h1v1h-1zM16 11h1v1h-1zM17 11h1v1h-1zM18 11h1v1h-1zM19 11h1v1h-1zM22 11h1v1h-1zM1 12h1v1h-1zM4 12h1v1h-1zM19 12h1v1h-1zM22 12h1v1h-1zM1 13h1v1h-1zM4 13h1v1h-1zM19 13h1v1h-1zM22 13h1v1h-1zM1 14h1v1h-1zM4 14h1v1h-1zM19 14h1v1h-1zM22 14h1v1h-1zM1 15h1v1h-1zM4 15h1v1h-1zM19 15h1v1h-1zM22 15h1v1h-1zM1 16h1v1h-1zM4 16h1v1h-1zM19 16h1v1h-1zM22 16h1v1h-1zM1 17h1v1h-1zM4 17h1v1h-1zM19 17h1v1h-1zM22 17h1v1h-1zM1 18h1v1h-1zM4 18h1v1h-1zM19 18h1v1h-1zM22 18h1v1h-1zM1 19h1v1h-1zM4 19h1v1h-1zM19 19h1v1h-1zM22 19h1v1h-1zM1 20h1v1h-1zM4 20h1v1h-1zM19 20h1v1h-1zM22 20h1v1h-1zM1 21h1v1h-1zM4 21h1v1h-1zM19 21h1v1h-1zM22 21h1v1h-1zM1 22h1v1h-1zM4 22h1v1h-1zM19 22h1v1h-1zM22 22h1v1h-1zM1 23h1v1h-1zM2 23h1v1h-1zM3 23h1v1h-1zM4 23h1v1h-1zM5 23h1v1h-1zM6 23h1v1h-1zM7 23h1v1h-1zM8 23h1v1h-1zM9 23h1v1h-1zM10 23h1v1h-1zM11 23h1v1h-1zM12 23h1v1h-1zM13 23h1v1h-1zM14 23h1v1h-1zM15 23h1v1h-1zM16 23h1v1h-1zM17 23h1v1h-1zM18 23h1v1h-1zM19 23h1v1h-1zM20 23h1v1h-1zM21 23h1v1h-1zM22 23h1v1h-1z" : "M3 1h1v1h-1zM4 1h1v1h-1zM5 1h1v1h-1zM6 1h1v1h-1zM7 1h1v1h-1zM8 1h1v1h-1zM9 1h1v1h-1zM10 1h1v1h-1zM11 1h1v1h-1zM12 1h1v1h-1zM13 1h1v1h-1zM14 1h1v1h-1zM15 1h1v1h-1zM16 1h1v1h-1zM17 1h1v1h-1zM18 1h1v1h-1zM19 1h1v1h-1zM20 1h1v1h-1zM21 1h1v1h-1zM22 1h1v1h-1zM23 1h1v1h-1zM24 1h1v1h-1zM25 1h1v1h-1zM26 1h1v1h-1zM27 1h1v1h-1zM28 1h1v1h-1zM3 2h1v1h-1zM28 2h1v1h-1zM3 3h1v1h-1zM5 3h1v1h-1zM6 3h1v1h-1zM7 3h1v1h-1zM8 3h1v1h-1zM9 3h1v1h-1zM10 3h1v1h-1zM11 3h1v1h-1zM12 3h1v1h-1zM13 3h1v1h-1zM14 3h1v1h-1zM15 3h1v1h-1zM16 3h1v1h-1zM17 3h1v1h-1zM18 3h1v1h-1zM19 3h1v1h-1zM20 3h1v1h-1zM21 3h1v1h-1zM22 3h1v1h-1zM23 3h1v1h-1zM24 3h1v1h-1zM25 3h1v1h-1zM26 3h1v1h-1zM28 3h1v1h-1zM3 4h1v1h-1zM5 4h1v1h-1zM26 4h1v1h-1zM28 4h1v1h-1zM3 5h1v1h-1zM5 5h1v1h-1zM8 5h1v1h-1zM9 5h1v1h-1zM10 5h1v1h-1zM11 5h1v1h-1zM12 5h1v1h-1zM13 5h1v1h-1zM14 5h1v1h-1zM15 5h1v1h-1zM16 5h1v1h-1zM17 5h1v1h-1zM18 5h1v1h-1zM19 5h1v1h-1zM20 5h1v1h-1zM21 5h1v1h-1zM22 5h1v1h-1zM26 5h1v1h-1zM28 5h1v1h-1zM3 6h1v1h-1zM5 6h1v1h-1zM8 6h1v1h-1zM15 6h1v1h-1zM22 6h1v1h-1zM26 6h1v1h-1zM28 6h1v1h-1zM3 7h1v1h-1zM5 7h1v1h-1zM8 7h1v1h-1zM10 7h1v1h-1zM11 7h1v1h-1zM12 7h1v1h-1zM13 7h1v1h-1zM14 7h1v1h-1zM15 7h1v1h-1zM19 7h1v1h-1zM20 7h1v1h-1zM22 7h1v1h-1zM26 7h1v1h-1zM28 7h1v1h-1zM3 8h1v1h-1zM5 8h1v1h-1zM8 8h1v1h-1zM10 8h1v1h-1zM20 8h1v1h-1zM22 8h1v1h-1zM26 8h1v1h-1zM28 8h1v1h-1zM3 9h1v1h-1zM5 9h1v1h-1zM8 9h1v1h-1zM10 9h1v1h-1zM20 9h1v1h-1zM22 9h1v1h-1zM26 9h1v1h-1zM28 9h1v1h-1zM3 10h1v1h-1zM5 10h1v1h-1zM8 10h1v1h-1zM10 10h1v1h-1zM20 10h1v1h-1zM22 10h1v1h-1zM26 10h1v1h-1zM28 10h1v1h-1zM3 11h1v1h-1zM5 11h1v1h-1zM8 11h1v1h-1zM10 11h1v1h-1zM20 11h1v1h-1zM22 11h1v1h-1zM26 11h1v1h-1zM28 11h1v1h-1zM3 12h1v1h-1zM5 12h1v1h-1zM8 12h1v1h-1zM9 12h1v1h-1zM10 12h1v1h-1zM20 12h1v1h-1zM22 12h1v1h-1zM26 12h1v1h-1zM28 12h1v1h-1zM3 13h1v1h-1zM5 13h1v1h-1zM8 13h1v1h-1zM10 13h1v1h-1zM20 13h1v1h-1zM22 13h1v1h-1zM26 13h1v1h-1zM28 13h1v1h-1zM3 14h1v1h-1zM5 14h1v1h-1zM8 14h1v1h-1zM10 14h1v1h-1zM20 14h1v1h-1zM22 14h1v1h-1zM26 14h1v1h-1zM28 14h1v1h-1zM3 15h1v1h-1zM5 15h1v1h-1zM8 15h1v1h-1zM10 15h1v1h-1zM20 15h1v1h-1zM22 15h1v1h-1zM26 15h1v1h-1zM28 15h1v1h-1zM3 16h1v1h-1zM5 16h1v1h-1zM8 16h1v1h-1zM10 16h1v1h-1zM20 16h1v1h-1zM22 16h1v1h-1zM26 16h1v1h-1zM28 16h1v1h-1zM3 17h1v1h-1zM5 17h1v1h-1zM8 17h1v1h-1zM10 17h1v1h-1zM11 17h1v1h-1zM12 17h1v1h-1zM13 17h1v1h-1zM14 17h1v1h-1zM15 17h1v1h-1zM16 17h1v1h-1zM17 17h1v1h-1zM18 17h1v1h-1zM19 17h1v1h-1zM20 17h1v1h-1zM22 17h1v1h-1zM26 17h1v1h-1zM28 17h1v1h-1zM3 18h1v1h-1zM5 18h1v1h-1zM8 18h1v1h-1zM15 18h1v1h-1zM22 18h1v1h-1zM26 18h1v1h-1zM28 18h1v1h-1zM3 19h1v1h-1zM5 19h1v1h-1zM8 19h1v1h-1zM9 19h1v1h-1zM10 19h1v1h-1zM11 19h1v1h-1zM12 19h1v1h-1zM13 19h1v1h-1zM14 19h1v1h-1zM15 19h1v1h-1zM17 19h1v1h-1zM18 19h1v1h-1zM19 19h1v1h-1zM20 19h1v1h-1zM21 19h1v1h-1zM22 19h1v1h-1zM26 19h1v1h-1zM28 19h1v1h-1zM3 20h1v1h-1zM5 20h1v1h-1zM26 20h1v1h-1zM28 20h1v1h-1zM3 21h1v1h-1zM5 21h1v1h-1zM6 21h1v1h-1zM7 21h1v1h-1zM8 21h1v1h-1zM9 21h1v1h-1zM10 21h1v1h-1zM11 21h1v1h-1zM12 21h1v1h-1zM13 21h1v1h-1zM14 21h1v1h-1zM15 21h1v1h-1zM16 21h1v1h-1zM17 21h1v1h-1zM18 21h1v1h-1zM19 21h1v1h-1zM20 21h1v1h-1zM21 21h1v1h-1zM22 21h1v1h-1zM23 21h1v1h-1zM24 21h1v1h-1zM25 21h1v1h-1zM26 21h1v1h-1zM28 21h1v1h-1zM3 22h1v1h-1zM28 22h1v1h-1zM3 23h1v1h-1zM12 23h1v1h-1zM13 23h1v1h-1zM14 23h1v1h-1zM15 23h1v1h-1zM16 23h1v1h-1zM17 23h1v1h-1zM18 23h1v1h-1zM19 23h1v1h-1zM20 23h1v1h-1zM21 23h1v1h-1zM28 23h1v1h-1zM3 24h1v1h-1zM28 24h1v1h-1zM3 25h1v1h-1zM4 25h1v1h-1zM5 25h1v1h-1zM6 25h1v1h-1zM7 25h1v1h-1zM8 25h1v1h-1zM9 25h1v1h-1zM10 25h1v1h-1zM11 25h1v1h-1zM12 25h1v1h-1zM13 25h1v1h-1zM14 25h1v1h-1zM15 25h1v1h-1zM16 25h1v1h-1zM17 25h1v1h-1zM18 25h1v1h-1zM19 25h1v1h-1zM20 25h1v1h-1zM21 25h1v1h-1zM22 25h1v1h-1zM23 25h1v1h-1zM24 25h1v1h-1zM25 25h1v1h-1zM26 25h1v1h-1zM27 25h1v1h-1zM28 25h1v1h-1zM2 26h1v1h-1zM29 26h1v1h-1zM2 27h1v1h-1zM3 27h1v1h-1zM4 27h1v1h-1zM5 27h1v1h-1zM6 27h1v1h-1zM7 27h1v1h-1zM8 27h1v1h-1zM9 27h1v1h-1zM10 27h1v1h-1zM11 27h1v1h-1zM12 27h1v1h-1zM13 27h1v1h-1zM14 27h1v1h-1zM15 27h1v1h-1zM16 27h1v1h-1zM17 27h1v1h-1zM18 27h1v1h-1zM19 27h1v1h-1zM20 27h1v1h-1zM21 27h1v1h-1zM22 27h1v1h-1zM23 27h1v1h-1zM24 27h1v1h-1zM25 27h1v1h-1zM26 27h1v1h-1zM27 27h1v1h-1zM28 27h1v1h-1zM29 27h1v1h-1zM2 28h1v1h-1zM29 28h1v1h-1zM2 29h1v1h-1zM3 29h1v1h-1zM4 29h1v1h-1zM5 29h1v1h-1zM6 29h1v1h-1zM7 29h1v1h-1zM8 29h1v1h-1zM9 29h1v1h-1zM10 29h1v1h-1zM11 29h1v1h-1zM12 29h1v1h-1zM13 29h1v1h-1zM14 29h1v1h-1zM15 29h1v1h-1zM16 29h1v1h-1zM17 29h1v1h-1zM18 29h1v1h-1zM19 29h1v1h-1zM20 29h1v1h-1zM21 29h1v1h-1zM22 29h1v1h-1zM23 29h1v1h-1zM24 29h1v1h-1zM25 29h1v1h-1zM26 29h1v1h-1zM27 29h1v1h-1zM28 29h1v1h-1zM29 29h1v1h-1z" }
      }
      ShapePath {
        strokeColor: "transparent"; fillColor: root.questionVisible && root.bootBeat === 0 ? root.ink : "transparent"
        scale: Qt.size(2, 2)
        PathSvg { path: "M9 13h1v1h-1zM10 13h1v1h-1zM11 13h1v1h-1zM12 13h1v1h-1zM13 13h1v1h-1zM14 13h1v1h-1zM8 14h1v1h-1zM9 14h1v1h-1zM14 14h1v1h-1zM15 14h1v1h-1zM8 15h1v1h-1zM9 15h1v1h-1zM14 15h1v1h-1zM15 15h1v1h-1zM14 16h1v1h-1zM15 16h1v1h-1zM13 17h1v1h-1zM14 17h1v1h-1zM12 18h1v1h-1zM13 18h1v1h-1zM12 19h1v1h-1zM13 19h1v1h-1zM12 21h1v1h-1zM13 21h1v1h-1z" }
      }
    }
    Rectangle {
      visible: root.bootBeat === 2
      x: 13; y: 39; width: parent.width - 26; height: 132
      color: root.paper; border.color: root.ink; border.width: 1
      Rectangle {
        anchors.fill: parent; anchors.margins: 3
        color: root.paper; border.color: root.ink; border.width: 1
      }
      Shape {
        x: 12; y: 10; width: 44; height: 44
        ShapePath {
          strokeColor: root.ink; fillColor: "transparent"; strokeWidth: 1.1
          capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
          PathSvg { path: "M14 4 C 22 3, 30 3, 36 5 L 37 27 C 30 29, 22 29, 15 27 Z M18 8 L 33 8 L 33 21 L 18 21 Z M21 11 h4 M21 18 h4 M27 11 h3 M27 18 h3 M21 11 v7 M30 11 v7 M20 24 h11 M15 27 L 14 35 C 22 37, 30 37, 38 35 L 37 27 M4 36 C 6 32, 9 31, 11 33 L 12 38 C 11 41, 7 42, 5 40 Z M9 31 L 12 26 C 13 25, 14 26, 13 28 L 11 33" }
        }
      }
      Text {
        // Centred in the space right of the hand-drawn Mac, as on the original screen.
        x: 64 + Math.max(0, (parent.width - 64 - implicitWidth) / 2); y: 34
        text: "Welcome to Omarchy."; font.family: chicago.name; font.pixelSize: 16; color: root.ink
      }
    }
  }
}
