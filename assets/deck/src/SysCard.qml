import QtQuick
import QtQuick.Layouts

CardFrame {
    id: root
    width: deck.compact ? 300 : 374
    height: deck.compact ? 168 : 204
    title: "sys"
    cardCode: "07 // D350 SYS"
    statusColor: sysBackend.cpuPercent >= 85 ? theme.red
               : sysBackend.cpuPercent >= 65 ? theme.yellow
               : theme.green

    headerExtra: [
        Rectangle {
            width: 36; height: 18; radius: Math.min(3, theme.radius)
            color: btopMouse.containsMouse ? theme.accent : theme.surface
            Text {
                anchors.centerIn: parent; text: "BTOP"
                color: btopMouse.containsMouse ? theme.accentForeground : theme.foreground
                font.family: theme.fontFamily; font.pixelSize: 9; font.weight: Font.Bold
            }
            MouseArea {
                id: btopMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: sysBackend.openBtop()
            }
        }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 8
        anchors.bottomMargin: 10
        spacing: 8

        // Built-in Orion N5 // D350 telemetry branding strip
        Rectangle {
            Layout.fillWidth: true
            height: 28
            radius: Math.min(3, theme.radius)
            color: theme.darkBackground
            border.width: 1
            border.color: theme.surface

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                // Minimal Orion N5 geometric hex emblem
                Canvas {
                    width: 16; height: 16
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        ctx.strokeStyle = theme.green
                        ctx.lineWidth = 1.4
                        var cx = 8, cy = 8, r = 6.5
                        ctx.beginPath()
                        for (var i = 0; i < 6; i++) {
                            var a = (Math.PI / 3) * i - Math.PI / 6
                            var x = cx + r * Math.cos(a)
                            var y = cy + r * Math.sin(a)
                            if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
                        }
                        ctx.closePath()
                        ctx.stroke()
                        ctx.fillStyle = theme.accent
                        ctx.beginPath()
                        ctx.arc(cx, cy, 2.0, 0, Math.PI * 2)
                        ctx.fill()
                    }
                    Connections {
                        target: theme
                        function onChanged() { parent.requestPaint() }
                    }
                }

                Text {
                    text: "ORION N5 // " + sysBackend.hostText
                    color: theme.brightForeground
                    font.family: theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    visible: sysBackend.tempC >= 0
                    text: sysBackend.tempC + "°C"
                    color: sysBackend.tempC >= 80 ? theme.red : theme.yellow
                    font.family: theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }

                Text {
                    text: "UP " + sysBackend.uptimeText
                    color: theme.muted
                    font.family: theme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Bold
                }
            }
        }

        // CPU readout + 18-bar live sparkline
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Column {
                spacing: 1
                Text {
                    text: "CPU LOAD"
                    color: theme.muted
                    font.family: theme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                }
                Text {
                    text: sysBackend.cpuPercent + "%"
                    color: theme.brightForeground
                    font.family: theme.fontFamily
                    font.pixelSize: deck.compact ? 18 : 26
                    font.weight: Font.Bold
                }
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: 3
                height: 36
                Layout.alignment: Qt.AlignBottom

                Repeater {
                    model: sysBackend.cpuHistory

                    Rectangle {
                        required property var modelData
                        width: 5
                        anchors.bottom: parent.bottom
                        height: Math.max(4, Math.round((modelData / 100.0) * 34))
                        radius: 1
                        color: modelData >= 85 ? theme.red : (modelData >= 65 ? theme.yellow : theme.green)
                    }
                }
            }
        }

        // Memory bar
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                Text { text: "MEM"; color: theme.muted; font.family: theme.fontFamily; font.pixelSize: 9; font.weight: Font.Bold }
                Text { text: sysBackend.memText; color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 9; Layout.fillWidth: true }
                Text { text: sysBackend.memPercent + "%"; color: theme.brightForeground; font.family: theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold }
            }

            Rectangle {
                Layout.fillWidth: true; height: 5; radius: 1; color: theme.darkBackground
                Rectangle {
                    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                    width: parent.width * (sysBackend.memPercent / 100.0)
                    radius: 1
                    color: sysBackend.memPercent >= 85 ? theme.red : theme.accent
                }
            }
        }

        // Disk bar
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                Text { text: "DSK"; color: theme.muted; font.family: theme.fontFamily; font.pixelSize: 9; font.weight: Font.Bold }
                Text { text: sysBackend.diskText; color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 9; Layout.fillWidth: true }
                Text { text: sysBackend.diskPercent + "%"; color: theme.brightForeground; font.family: theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold }
            }

            Rectangle {
                Layout.fillWidth: true; height: 5; radius: 1; color: theme.darkBackground
                Rectangle {
                    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                    width: parent.width * (sysBackend.diskPercent / 100.0)
                    radius: 1
                    color: sysBackend.diskPercent >= 90 ? theme.red : theme.green
                }
            }
        }
    }
}
