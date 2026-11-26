import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 340
    height: 116
    minimumWidth: 280
    minimumHeight: 100
    visible: true
    title: "signal"
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
        onActivated: backend.playPause()
    }
    Shortcut {
        sequence: "N"
        context: Qt.ApplicationShortcut
        onActivated: backend.nextTrack()
    }
    Shortcut {
        sequence: "Right"
        context: Qt.ApplicationShortcut
        onActivated: backend.nextTrack()
    }
    Shortcut {
        sequence: "P"
        context: Qt.ApplicationShortcut
        onActivated: backend.prevTrack()
    }
    Shortcut {
        sequence: "Left"
        context: Qt.ApplicationShortcut
        onActivated: backend.prevTrack()
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

            // Leading accent bar: active accent when playing, muted when paused or idle.
            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.topMargin: 14
                anchors.bottomMargin: 16
                anchors.leftMargin: 12
                width: 3
                radius: Math.min(2, theme.radius)
                color: backend.playing ? theme.accent : theme.muted

                Behavior on color {
                    ColorAnimation { duration: 140 }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 26
                anchors.rightMargin: 14
                anchors.topMargin: 14
                anchors.bottomMargin: 14
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: backend.title
                        color: theme.brightForeground
                        font.family: theme.fontFamily
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // Always-visible minimal close button in top-right corner.
                    Rectangle {
                        width: 20
                        height: 20
                        radius: Math.min(4, theme.radius)
                        color: closeMouse.containsMouse ? theme.accent : theme.surface
                        border.width: 1
                        border.color: closeMouse.containsMouse ? theme.accent : theme.muted
                        visible: !win.helpVisible

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

                Text {
                    text: backend.artist
                    color: theme.foreground
                    font.family: theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Normal
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Compact media controls (subtle at rest, full opacity on hover).
                    Row {
                        spacing: 4
                        opacity: hoverHandler.hovered ? 1.0 : 0.45

                        Behavior on opacity {
                            NumberAnimation { duration: 120 }
                        }

                        Repeater {
                            model: [
                                { glyph: "⏮", action: function() { backend.prevTrack() } },
                                { glyph: backend.playing ? "⏸" : "▶", action: function() { backend.playPause() } },
                                { glyph: "⏭", action: function() { backend.nextTrack() } }
                            ]

                            delegate: Rectangle {
                                width: 24
                                height: 22
                                radius: Math.min(4, theme.radius)
                                color: btnMouse.containsMouse ? theme.accent : theme.surface

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.glyph
                                    color: btnMouse.containsMouse ? theme.accentForeground : theme.brightForeground
                                    font.family: theme.fontFamily
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    id: btnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: modelData.action()
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: backend.positionText
                        color: theme.muted
                        font.family: theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
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

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * Math.max(0, Math.min(1, backend.progress))
                    color: backend.playing ? theme.accent : theme.muted

                    Behavior on width {
                        NumberAnimation { duration: 200 }
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
                    columns: 2
                    columnSpacing: 16
                    rowSpacing: 3

                    Text { text: "Space"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
                    Text { text: qsTr("Play / Pause"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 11 }

                    Text { text: "N / →"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
                    Text { text: qsTr("Next track"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 11 }

                    Text { text: "P / ←"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
                    Text { text: qsTr("Previous track"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 11 }

                    Text { text: "?"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
                    Text { text: qsTr("Toggle shortcuts"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 11 }

                    Text { text: "Q / Esc"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
                    Text { text: qsTr("Quit"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 11 }
                }
            }
        }
    }
}
