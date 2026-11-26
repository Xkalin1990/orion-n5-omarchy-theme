import QtQuick
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "orion.deck"

  property bool panelOpen: false
  property bool deckRunning: false
  property var stateObj: ({
    "epoch": true,
    "tminus": false,
    "uplink": false,
    "signal": false,
    "slate": false,
    "zulu": false,
    "sys": false,
    "compact": false
  })

  implicitWidth: pill.implicitWidth + 8
  implicitHeight: bar && bar.thickness ? bar.thickness : 26

  function activeCount() {
    var keys = ["epoch", "tminus", "uplink", "signal", "slate", "zulu", "sys"]
    var n = 0
    for (var i = 0; i < keys.length; i++) {
      if (root.stateObj[keys[i]]) n++
    }
    return n
  }

  function writeStateAndEnsureRunning(nextObj) {
    root.stateObj = nextObj
    var jsonStr = JSON.stringify(nextObj, null, 2)
    var b64 = Qt.btoa(jsonStr)
    var cmd = "mkdir -p ~/.config/deck && printf '%s' '" + b64 + "' | base64 -d > ~/.config/deck/state.json.tmp && mv ~/.config/deck/state.json.tmp ~/.config/deck/state.json && (pgrep -x deck >/dev/null || setsid -f deck >/dev/null 2>&1)"
    if (root.bar) root.bar.run(cmd)
    root.deckRunning = true
  }

  function toggleKey(key) {
    var next = Object.assign({}, root.stateObj)
    next[key] = !next[key]
    writeStateAndEnsureRunning(next)
  }

  function toggleAll() {
    var keys = ["epoch", "tminus", "uplink", "signal", "slate", "zulu", "sys"]
    var enable = activeCount() < keys.length
    var next = Object.assign({}, root.stateObj)
    for (var i = 0; i < keys.length; i++) next[keys[i]] = enable
    writeStateAndEnsureRunning(next)
  }

  function toggleDeckProcess() {
    if (root.deckRunning) {
      if (root.bar) root.bar.run("pkill -x deck >/dev/null 2>&1 || true")
      root.deckRunning = false
    } else {
      if (root.bar) root.bar.run("setsid -f deck >/dev/null 2>&1")
      root.deckRunning = true
    }
  }

  Process {
    id: stateProc
    command: [
      "bash", "-c",
      "pgrep -x deck >/dev/null && echo 1 || echo 0; " +
      "cat ~/.config/deck/state.json 2>/dev/null || echo '{}'"
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        var txt = this.text.trim()
        var nl = txt.indexOf("\n")
        if (nl < 0) return
        root.deckRunning = txt.slice(0, nl).trim() === "1"
        try {
          var parsed = JSON.parse(txt.slice(nl + 1))
          root.stateObj = Object.assign({
            "epoch": true, "tminus": false, "uplink": false,
            "signal": false, "slate": false, "zulu": false,
            "sys": false, "compact": false
          }, parsed)
        } catch (e) {}
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: stateProc.running = true
  }

  Rectangle {
    id: pill
    anchors.centerIn: parent
    height: Math.max(18, (root.bar && root.bar.thickness ? root.bar.thickness : 26) - 6)
    implicitWidth: row.implicitWidth + 14
    radius: 2
    color: root.panelOpen ? "#25332c" : "#1e2220"
    border.width: 1
    border.color: root.panelOpen || root.deckRunning ? "#ff5a1f" : "#25332c"

    Row {
      id: row
      anchors.centerIn: parent
      spacing: 5

      Text {
        textFormat: Text.PlainText
        anchors.verticalCenter: parent.verticalCenter
        text: "⊞"
        color: root.deckRunning ? "#ff5a1f" : "#7d9689"
        font.pixelSize: 11
        font.bold: true
      }

      Text {
        textFormat: Text.PlainText
        anchors.verticalCenter: parent.verticalCenter
        text: "DECK"
        color: "#c4ddd0"
        font.pixelSize: 10
        font.bold: true
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        stateProc.running = true
        root.panelOpen = !root.panelOpen
      }
    }
  }

  PopupCard {
    id: deckPopup
    anchorItem: pill
    bar: root.bar
    owner: root
    open: root.panelOpen
    contentWidth: 276
    contentHeight: 272
    triggerMode: "click"

    onOpenChanged: {
      if (!open && root.panelOpen) root.panelOpen = false
    }

    Column {
      anchors.fill: parent
      spacing: 8

      // Header
      Row {
        width: parent.width
        spacing: 6

        Rectangle {
          width: 7; height: 7; radius: 3.5
          anchors.verticalCenter: parent.verticalCenter
          color: root.deckRunning ? "#ff5a1f" : "#54685e"
        }

        Text {
          textFormat: Text.PlainText
          text: "ORION N5 // DECK"
          color: "#eef7f2"
          font.pixelSize: 11
          font.bold: true
        }

        Item { width: 1; height: 1 }
      }

      Rectangle { width: parent.width; height: 1; color: "#25332c" }

      // 7 Card Toggle Rows
      Grid {
        width: parent.width
        columns: 2
        columnSpacing: 6
        rowSpacing: 6

        Repeater {
          model: [
            { id: "epoch",  label: "01 EPOCH" },
            { id: "tminus", label: "02 T-MINUS" },
            { id: "uplink", label: "03 UPLINK" },
            { id: "signal", label: "04 SIGNAL" },
            { id: "slate",  label: "05 SLATE" },
            { id: "zulu",   label: "06 ZULU" },
            { id: "sys",    label: "07 D350 SYS" }
          ]

          Rectangle {
            required property var modelData
            readonly property bool isOn: !!root.stateObj[modelData.id]
            width: (parent.width - 6) / 2
            height: 28
            radius: 2
            color: isOn ? "#25332c" : "#0f1110"
            border.width: 1
            border.color: isOn ? "#ff5a1f" : "#1e2220"

            Row {
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: 8
              spacing: 6

              Rectangle {
                width: 6; height: 6; radius: 3
                anchors.verticalCenter: parent.verticalCenter
                color: isOn ? "#ff5a1f" : "#54685e"
              }

              Text {
                textFormat: Text.PlainText
                text: modelData.label
                color: isOn ? "#eef7f2" : "#7d9689"
                font.pixelSize: 10
                font.bold: true
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.toggleKey(modelData.id)
            }
          }
        }
      }

      Rectangle { width: parent.width; height: 1; color: "#25332c" }

      // Size mode + All + Power controls
      Row {
        width: parent.width
        spacing: 6

        Rectangle {
          width: (parent.width - 12) / 3
          height: 28
          radius: 2
          color: root.stateObj.compact ? "#25332c" : "#1e2220"
          border.width: 1
          border.color: root.stateObj.compact ? "#ff5a1f" : "#54685e"

          Text {
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: root.stateObj.compact ? "SIZE: MINI" : "SIZE: STD"
            color: "#eef7f2"
            font.pixelSize: 9
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleKey("compact")
          }
        }

        Rectangle {
          width: (parent.width - 12) / 3
          height: 28
          radius: 2
          color: "#1e2220"
          border.width: 1
          border.color: "#54685e"

          Text {
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: root.activeCount() === 7 ? "ALL OFF" : "ALL ON"
            color: "#c4ddd0"
            font.pixelSize: 9
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleAll()
          }
        }

        Rectangle {
          width: (parent.width - 12) / 3
          height: 28
          radius: 2
          color: root.deckRunning ? "#25332c" : "#ff5a1f"
          border.width: 1
          border.color: root.deckRunning ? "#ff4526" : "#ff5a1f"

          Text {
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: root.deckRunning ? "HIDE DECK" : "OPEN DECK"
            color: root.deckRunning ? "#ff6b52" : "#0a0b0a"
            font.pixelSize: 9
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleDeckProcess()
          }
        }
      }
    }
  }
}
