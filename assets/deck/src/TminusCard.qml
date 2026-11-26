import QtQuick
import QtQuick.Layouts

CardFrame {
    id: root
    width: 344
    height: 162
    title: "tminus"
    cardCode: "02 // T-MINUS"
    statusColor: tminusBackend.finished ? theme.red : (tminusBackend.running ? theme.accent : theme.green)

    headerExtra: [
        Rectangle {
            width: statusLbl.implicitWidth + 10; height: 18; radius: Math.min(3, theme.radius)
            color: tminusBackend.running ? theme.selection : theme.surface
            Text {
                id: statusLbl
                anchors.centerIn: parent
                text: tminusBackend.finished ? "DONE" : (tminusBackend.running ? "ACTIVE" : "HOLD")
                color: tminusBackend.finished ? theme.red : (tminusBackend.running ? theme.accent : theme.foreground)
                font.family: theme.fontFamily; font.pixelSize: 9; font.weight: Font.Bold
            }
        }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 8
        anchors.bottomMargin: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: tminusBackend.timeText
                color: tminusBackend.finished ? theme.red : theme.brightForeground
                font.family: theme.fontFamily
                font.pixelSize: 42
                font.weight: Font.Bold
                font.letterSpacing: -1
            }

            Item { Layout.fillWidth: true }

            // Play/Pause + Reset hardware keys
            Row {
                spacing: 6

                Rectangle {
                    width: 36; height: 28; radius: Math.min(3, theme.radius)
                    color: playMouse.containsMouse || tminusBackend.running ? theme.accent : theme.selection
                    border.width: 1; border.color: theme.accent
                    Text {
                        anchors.centerIn: parent
                        text: tminusBackend.running ? "⏸" : "▶"
                        color: playMouse.containsMouse || tminusBackend.running ? theme.accentForeground : theme.brightForeground
                        font.family: theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold
                    }
                    MouseArea {
                        id: playMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: tminusBackend.toggleRunning()
                    }
                }

                Rectangle {
                    width: 28; height: 28; radius: Math.min(3, theme.radius)
                    color: rstMouse.containsMouse ? theme.accent : theme.surface
                    border.width: 1; border.color: theme.muted
                    Text {
                        anchors.centerIn: parent; text: "↺"
                        color: rstMouse.containsMouse ? theme.accentForeground : theme.foreground
                        font.family: theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold
                    }
                    MouseArea {
                        id: rstMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: tminusBackend.reset()
                    }
                }
            }
        }

        // Preset & minute-adjust bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            Repeater {
                model: [
                    { label: "25M", idx: 0 },
                    { label: "15M", idx: 1 },
                    { label: "05M", idx: 2 }
                ]

                Rectangle {
                    required property var modelData
                    readonly property bool selected: !tminusBackend.stopwatch && tminusBackend.presetIndex === modelData.idx
                    width: 38; height: 22; radius: Math.min(3, theme.radius)
                    color: selected ? theme.selection : (pMouse.containsMouse ? theme.surface : theme.darkBackground)
                    border.width: 1; border.color: selected ? theme.accent : theme.surface
                    Text {
                        anchors.centerIn: parent; text: modelData.label
                        color: selected ? theme.brightForeground : theme.foreground
                        font.family: theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold
                    }
                    MouseArea {
                        id: pMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: tminusBackend.selectPreset(modelData.idx)
                    }
                }
            }

            Rectangle {
                width: 34; height: 22; radius: Math.min(3, theme.radius)
                color: tminusBackend.stopwatch ? theme.selection : (swMouse.containsMouse ? theme.surface : theme.darkBackground)
                border.width: 1; border.color: tminusBackend.stopwatch ? theme.accent : theme.surface
                Text {
                    anchors.centerIn: parent; text: "SW"
                    color: tminusBackend.stopwatch ? theme.brightForeground : theme.foreground
                    font.family: theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold
                }
                MouseArea {
                    id: swMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: tminusBackend.toggleStopwatch()
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 24; height: 22; radius: Math.min(3, theme.radius)
                color: minusMouse.containsMouse ? theme.accent : theme.surface
                Text { anchors.centerIn: parent; text: "-"; color: minusMouse.containsMouse ? theme.accentForeground : theme.foreground; font.family: theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold }
                MouseArea { id: minusMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tminusBackend.adjustMinutes(-1) }
            }
            Rectangle {
                width: 24; height: 22; radius: Math.min(3, theme.radius)
                color: plusMouse.containsMouse ? theme.accent : theme.surface
                Text { anchors.centerIn: parent; text: "+"; color: plusMouse.containsMouse ? theme.accentForeground : theme.foreground; font.family: theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold }
                MouseArea { id: plusMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tminusBackend.adjustMinutes(1) }
            }
        }
    }

    // Bottom progress bar
    Rectangle {
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 4; color: theme.darkBackground
        Rectangle {
            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
            width: parent.width * tminusBackend.progress
            color: tminusBackend.finished ? theme.red : theme.accent
        }
    }
}
