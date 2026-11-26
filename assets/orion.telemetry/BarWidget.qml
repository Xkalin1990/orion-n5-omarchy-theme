import QtQuick
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "orion.telemetry"

  property string cpuPct: "--"
  property int cpuVal: 0
  property string memPct: "--"
  property int memVal: 0
  property string diskPct: "--"
  property string uptimeStr: "--"
  property real prevTotal: 0
  property real prevIdle: 0
  property bool panelOpen: false
  readonly property bool notchCompact: !!(root.bar && root.bar.centerBesideRight)

  implicitWidth: pill.implicitWidth + (notchCompact ? 4 : 8)
  implicitHeight: bar && bar.thickness ? bar.thickness : 26

  Process {
    id: statProc
    command: [
      "bash", "-c",
      "awk '/^cpu / {t=$2+$3+$4+$5+$6+$7+$8; i=$5+$6; print t, i}' /proc/stat; " +
      "awk '/MemTotal:/ {mt=$2} /MemAvailable:/ {ma=$2} END {if (mt>0) printf \"%d\\n\", ((mt-ma)*100)/mt; else print 0}' /proc/meminfo; " +
      "df -P / | awk 'NR==2 {gsub(/%/, \"\", $5); print $5}'; " +
      "awk '{u=int($1); h=int(u/3600); m=int((u%3600)/60); printf \"%dh %02dm\\n\", h, m}' /proc/uptime"
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = this.text.trim().split("\n")
        if (lines.length >= 4) {
          var parts = lines[0].trim().split(/\s+/)
          if (parts.length >= 2) {
            var total = parseFloat(parts[0])
            var idle = parseFloat(parts[1])
            if (root.prevTotal > 0 && total > root.prevTotal) {
              var dt = total - root.prevTotal
              var di = idle - root.prevIdle
              var pct = Math.max(0, Math.min(100, Math.round(((dt - di) * 100) / dt)))
              root.cpuVal = pct
              root.cpuPct = (pct < 10 ? "0" : "") + pct
            }
            root.prevTotal = total
            root.prevIdle = idle
          }
          var m = parseInt(lines[1].trim(), 10)
          if (!isNaN(m)) {
            root.memVal = Math.max(0, Math.min(100, m))
            root.memPct = (root.memVal < 10 ? "0" : "") + root.memVal
          }
          var d = lines[2].trim()
          if (d.length > 0 && d.length <= 4) root.diskPct = d
          var up = lines[3].trim()
          if (up.length > 0 && up.length <= 16) root.uptimeStr = up
        }
      }
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: statProc.running = true
  }

  Rectangle {
    id: pill
    anchors.centerIn: parent
    height: Math.max(18, (root.bar && root.bar.thickness ? root.bar.thickness : 26) - 6)
    implicitWidth: row.implicitWidth + (root.notchCompact ? 10 : 14)
    radius: 2
    color: root.panelOpen ? "#25332c" : "#1e2220"
    border.width: 1
    border.color: root.panelOpen ? "#ff5a1f" : "#25332c"

    Row {
      id: row
      anchors.centerIn: parent
      spacing: root.notchCompact ? 4 : 6

      Rectangle {
        width: 6
        height: 6
        radius: 3
        anchors.verticalCenter: parent.verticalCenter
        color: "#ff5a1f"
      }

      Text {
        textFormat: Text.PlainText
        anchors.verticalCenter: parent.verticalCenter
        text: "D350"
        color: "#ff5a1f"
        font.pixelSize: 10
        font.bold: true
      }

      Text {
        textFormat: Text.PlainText
        anchors.verticalCenter: parent.verticalCenter
        text: root.notchCompact
          ? (root.cpuPct + "%·" + root.memPct + "%")
          : ("CPU " + root.cpuPct + "%  MEM " + root.memPct + "%")
        color: "#c4ddd0"
        font.pixelSize: 10
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.panelOpen = !root.panelOpen
    }
  }

  PopupCard {
    id: missionCard
    anchorItem: pill
    bar: root.bar
    owner: root
    open: root.panelOpen
    contentWidth: 324
    contentHeight: 236
    triggerMode: "click"

    onOpenChanged: {
      if (!open && root.panelOpen) root.panelOpen = false
    }

    Column {
      anchors.fill: parent
      spacing: 10

      // Header
      Row {
        width: parent.width
        spacing: 8

        Rectangle {
          width: 4
          height: 16
          color: "#ff5a1f"
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          textFormat: Text.PlainText
          text: "ORION N5 // MISSION CONTROL"
          color: "#eef7f2"
          font.pixelSize: 12
          font.bold: true
          anchors.verticalCenter: parent.verticalCenter
        }

        Item { width: 1; height: 1 }

        Text {
          textFormat: Text.PlainText
          text: "UPLO-07"
          color: "#9ecab3"
          font.pixelSize: 10
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Rectangle { width: parent.width; height: 1; color: "#25332c" }

      // 2x2 Modular Telemetry Grid
      Grid {
        width: parent.width
        columns: 2
        rowSpacing: 8
        columnSpacing: 8

        // CPU Tile
        Rectangle {
          width: (parent.width - 8) / 2
          height: 66
          radius: 2
          color: "#0f1110"
          border.width: 1
          border.color: "#25332c"

          Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4
            Text { textFormat: Text.PlainText; text: "CPU LOAD"; color: "#7d9689"; font.pixelSize: 9 }
            Text { textFormat: Text.PlainText; text: root.cpuPct + "%"; color: "#eef7f2"; font.pixelSize: 20; font.bold: true }
            Rectangle {
              width: parent.width; height: 3; color: "#1e2220"
              Rectangle { width: parent.width * (root.cpuVal / 100.0); height: 3; color: "#9ecab3" }
            }
          }
        }

        // MEM Tile
        Rectangle {
          width: (parent.width - 8) / 2
          height: 66
          radius: 2
          color: "#0f1110"
          border.width: 1
          border.color: "#25332c"

          Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4
            Text { textFormat: Text.PlainText; text: "MEMORY"; color: "#7d9689"; font.pixelSize: 9 }
            Text { textFormat: Text.PlainText; text: root.memPct + "%"; color: "#9ecab3"; font.pixelSize: 20; font.bold: true }
            Rectangle {
              width: parent.width; height: 3; color: "#1e2220"
              Rectangle { width: parent.width * (root.memVal / 100.0); height: 3; color: "#7db5a3" }
            }
          }
        }

        // DISK Tile
        Rectangle {
          width: (parent.width - 8) / 2
          height: 58
          radius: 2
          color: "#0f1110"
          border.width: 1
          border.color: "#25332c"

          Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2
            Text { textFormat: Text.PlainText; text: "STORAGE (/)"; color: "#7d9689"; font.pixelSize: 9 }
            Text { textFormat: Text.PlainText; text: root.diskPct + "% USED"; color: "#e5a93c"; font.pixelSize: 15; font.bold: true }
          }
        }

        // UPTIME Accent Tile
        Rectangle {
          width: (parent.width - 8) / 2
          height: 58
          radius: 2
          color: "#ff5a1f"

          Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2
            Text { textFormat: Text.PlainText; text: "MISSION UPTIME"; color: "#141615"; font.pixelSize: 9; font.bold: true }
            Text { textFormat: Text.PlainText; text: root.uptimeStr; color: "#0a0b0a"; font.pixelSize: 15; font.bold: true }
          }
        }
      }

      // Launch btop action button
      Rectangle {
        width: parent.width
        height: 28
        radius: 2
        color: "#1e2220"
        border.width: 1
        border.color: "#25332c"

        Text {
          textFormat: Text.PlainText
          anchors.centerIn: parent
          text: "OPEN BTOP TELEMETRY MONITOR ↗"
          color: "#c4ddd0"
          font.pixelSize: 10
          font.bold: true
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.panelOpen = false
            if (root.bar) root.bar.run("omarchy-launch-or-focus-tui btop")
          }
        }
      }
    }
  }
}
