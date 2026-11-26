import QtQuick
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "orion.telemetry"

  property string cpuPct: "--"
  property string memPct: "--"
  property real prevTotal: 0
  property real prevIdle: 0

  implicitWidth: pill.implicitWidth + 8
  implicitHeight: bar ? bar.thickness : 26

  Process {
    id: statProc
    command: ["bash", "-c", "awk '/^cpu / {t=$2+$3+$4+$5+$6+$7+$8; i=$5+$6; print t, i}' /proc/stat; awk '/MemTotal:/ {mt=$2} /MemAvailable:/ {ma=$2} END {if (mt>0) printf \"%d\\n\", ((mt-ma)*100)/mt; else print 0}' /proc/meminfo"]
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = this.text.trim().split("\n")
        if (lines.length >= 2) {
          var parts = lines[0].trim().split(/\s+/)
          if (parts.length >= 2) {
            var total = parseFloat(parts[0])
            var idle = parseFloat(parts[1])
            if (root.prevTotal > 0 && total > root.prevTotal) {
              var dt = total - root.prevTotal
              var di = idle - root.prevIdle
              var pct = Math.max(0, Math.min(100, Math.round(((dt - di) * 100) / dt)))
              root.cpuPct = (pct < 10 ? "0" : "") + pct
            }
            root.prevTotal = total
            root.prevIdle = idle
          }
          var m = parseInt(lines[1].trim(), 10)
          if (!isNaN(m)) {
            root.memPct = (m < 10 ? "0" : "") + m
          }
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
    height: Math.max(18, (root.bar ? root.bar.thickness : 26) - 6)
    implicitWidth: row.implicitWidth + 14
    radius: 2
    color: "#1e2220"
    border.width: 1
    border.color: "#25332c"

    Row {
      id: row
      anchors.centerIn: parent
      spacing: 6

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
        text: "CPU " + root.cpuPct + "%  MEM " + root.memPct + "%"
        color: "#c4ddd0"
        font.pixelSize: 10
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        if (root.bar) root.bar.run("omarchy-launch-or-focus-tui btop")
      }
    }
  }
}
