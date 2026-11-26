import QtQuick
import QtQuick.Layouts

CardFrame {
    id: root
    width: 332
    height: 146
    title: "uplink"
    cardCode: "03 // UPLINK"
    statusColor: uplinkBackend.statusText === "OFFLINE" ? theme.red
               : uplinkBackend.statusText === "DEGRADED" ? theme.yellow
               : theme.green

    headerExtra: [
        Rectangle {
            width: 22; height: 18; radius: Math.min(3, theme.radius)
            color: refMouse.containsMouse ? theme.accent : theme.surface
            Text {
                anchors.centerIn: parent; text: "↻"
                color: refMouse.containsMouse ? theme.accentForeground : theme.foreground
                font.family: theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold
            }
            MouseArea {
                id: refMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: uplinkBackend.refresh()
            }
        }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Column {
                spacing: 2

                Rectangle {
                    width: stText.implicitWidth + 12; height: 20; radius: Math.min(3, theme.radius)
                    color: theme.darkBackground
                    border.width: 1; border.color: root.statusColor
                    Text {
                        id: stText
                        anchors.centerIn: parent
                        text: uplinkBackend.statusText
                        color: root.statusColor
                        font.family: theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1
                    }
                }

                Text {
                    text: uplinkBackend.latencyMs >= 0 ? (uplinkBackend.latencyMs + " ms") : "-- ms"
                    color: theme.brightForeground
                    font.family: theme.fontFamily
                    font.pixelSize: 28
                    font.weight: Font.Bold
                }
            }

            Item { Layout.fillWidth: true }

            // Live latency sparkline (14 recent probes)
            Row {
                spacing: 3
                height: 44
                Layout.alignment: Qt.AlignBottom

                Repeater {
                    model: uplinkBackend.history

                    Rectangle {
                        required property var modelData
                        width: 5
                        anchors.bottom: parent.bottom
                        height: modelData <= 0 ? 4 : Math.max(6, Math.min(42, Math.round(modelData / 3.0)))
                        radius: 1
                        color: modelData <= 0 ? theme.red : (modelData > 150 ? theme.yellow : theme.green)
                    }
                }
            }
        }

        // Target selector pills
        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            Repeater {
                model: uplinkBackend.targetNames

                Rectangle {
                    required property string modelData
                    required property int index
                    readonly property bool active: uplinkBackend.targetIndex === index
                    Layout.fillWidth: true
                    height: 22
                    radius: Math.min(3, theme.radius)
                    color: active ? theme.selection : (tMouse.containsMouse ? theme.surface : theme.darkBackground)
                    border.width: 1
                    border.color: active ? theme.accent : theme.surface

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: active ? theme.brightForeground : theme.foreground
                        font.family: theme.fontFamily; font.pixelSize: 9; font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: tMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: uplinkBackend.selectTarget(index)
                    }
                }
            }
        }
    }
}
