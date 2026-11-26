import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 320
    height: 136
    minimumWidth: 260
    minimumHeight: 118
    visible: true
    title: "tminus"
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.Window

    Material.theme: Material.Dark
    Material.accent: theme.accent
    Material.roundedScale: theme.radius

    property bool helpVisible: false

    Shortcut {
        sequence: "?"
        context: Qt.ApplicationShortcut
        onActivated: win.helpVisible = !win.helpVisible
    }
    Shortcut {
        sequence: "Q"
        context: Qt.ApplicationShortcut
        onActivated: Qt.quit()
    }
    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        onActivated: {
            if (win.helpVisible)
                win.helpVisible = false
            else
                Qt.quit()
        }
    }
    Shortcut {
        sequence: "Space"
        context: Qt.ApplicationShortcut
        onActivated: backend.toggleRunning()
    }
    Shortcut {
        sequence: "R"
        context: Qt.ApplicationShortcut
        onActivated: backend.reset()
    }
    Shortcut {
        sequence: "P"
        context: Qt.ApplicationShortcut
        onActivated: backend.nextPreset()
    }
    Shortcut {
        sequence: "M"
        context: Qt.ApplicationShortcut
        onActivated: backend.toggleStopwatch()
    }
    Shortcut {
        sequence: "+"
        context: Qt.ApplicationShortcut
        onActivated: backend.adjustMinutes(1)
    }
    Shortcut {
        sequence: "="
        context: Qt.ApplicationShortcut
        onActivated: backend.adjustMinutes(1)
    }
    Shortcut {
        sequence: "Up"
        context: Qt.ApplicationShortcut
        onActivated: backend.adjustMinutes(1)
    }
    Shortcut {
        sequence: "-"
        context: Qt.ApplicationShortcut
        onActivated: backend.adjustMinutes(-1)
    }
    Shortcut {
        sequence: "Down"
        context: Qt.ApplicationShortcut
        onActivated: backend.adjustMinutes(-1)
    }

    Item {
        anchors.fill: parent
        LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
        LayoutMirroring.childrenInherit: true

        Rectangle {
            id: card
            anchors.fill: parent
            radius: theme.radius
            color: theme.background
            border.width: 1
            border.color: hoverHandler.hovered ? theme.accent : theme.surface
            clip: true

            Behavior on border.color {
                ColorAnimation { duration: 140 }
            }

            HoverHandler {
                id: hoverHandler
            }

            // Drag anywhere on the widget to move it around the desktop.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                onPressed: win.startSystemMove()
            }

            // Leading accent bar.
            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: 12
                width: 3
                radius: Math.min(2, theme.radius)
                color: theme.accent
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 26
                anchors.rightMargin: 18
                anchors.topMargin: 16
                anchors.bottomMargin: 18
                spacing: 4

                Text {
                    text: backend.timeText
                    color: backend.finished ? theme.accent : theme.brightForeground
                    font.family: theme.fontFamily
                    font.pixelSize: 44
                    font.weight: Font.Bold
                    font.letterSpacing: -1
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: translator.language.length >= 0 ? backend.presetLabel : ""
                        color: theme.accent
                        font.family: theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: backend.finished ? qsTr("DONE")
                              : backend.running ? qsTr("RUNNING")
                              : qsTr("PAUSED")
                        color: backend.finished ? theme.accent : theme.muted
                        font.family: theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Normal
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            // Minimal corner controls: play/pause & preset pill on hover, X always visible.
            Row {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 10
                spacing: 6
                visible: !win.helpVisible

                Rectangle {
                    width: 22
                    height: 20
                    radius: Math.min(4, theme.radius)
                    color: playMouse.containsMouse ? theme.accent : theme.surface
                    opacity: hoverHandler.hovered ? 1.0 : 0.0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: backend.running ? "⏸" : "▶"
                        color: playMouse.containsMouse ? theme.accentForeground : theme.foreground
                        font.family: theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.toggleRunning()
                    }
                }

                Rectangle {
                    width: presetPillLabel.implicitWidth + 12
                    height: 20
                    radius: Math.min(4, theme.radius)
                    color: presetMouse.containsMouse ? theme.accent : theme.surface
                    opacity: hoverHandler.hovered ? 1.0 : 0.0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }

                    Text {
                        id: presetPillLabel
                        anchors.centerIn: parent
                        text: backend.presetLabel
                        color: presetMouse.containsMouse ? theme.accentForeground : theme.foreground
                        font.family: theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: presetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.nextPreset()
                    }
                }

                Rectangle {
                    width: 20
                    height: 20
                    radius: Math.min(4, theme.radius)
                    color: closeMouse.containsMouse ? theme.accent : theme.surface
                    border.width: 1
                    border.color: closeMouse.containsMouse ? theme.accent : theme.muted

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: closeMouse.containsMouse ? theme.accentForeground : theme.brightForeground
                        font.family: theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.quit()
                    }
                }
            }

            // Thin bottom progress bar.
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 3
                color: theme.surface
                visible: !backend.stopwatch

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * backend.progress
                    color: theme.accent

                    Behavior on width {
                        NumberAnimation { duration: 180 }
                    }
                }
            }

            // Compact keyboard shortcut overlay toggled with '?'.
            Rectangle {
                anchors.fill: parent
                radius: theme.radius
                color: theme.background
                border.width: 1
                border.color: theme.accent
                visible: win.helpVisible

                MouseArea {
                    anchors.fill: parent
                    onClicked: win.helpVisible = false
                }

                GridLayout {
                    anchors.centerIn: parent
                    columns: 4
                    columnSpacing: 10
                    rowSpacing: 4

                    Text { text: "Space"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
                    Text { text: qsTr("Start / Pause"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 11 }
                    Text { text: "R"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
                    Text { text: qsTr("Reset"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 11 }

                    Text { text: "P"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
                    Text { text: qsTr("Preset"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 11 }
                    Text { text: "M"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
                    Text { text: qsTr("Stopwatch"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 11 }

                    Text { text: "+/-"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
                    Text { text: qsTr("Adjust min"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 11 }
                    Text { text: "Q"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
                    Text { text: qsTr("Quit"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 11 }
                }
            }
        }
    }
}
