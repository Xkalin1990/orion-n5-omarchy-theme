import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 300
    height: 112
    minimumWidth: 260
    minimumHeight: 100
    visible: true
    title: "uplink"
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
        onActivated: backend.refresh()
    }
    Shortcut {
        sequence: "R"
        context: Qt.ApplicationShortcut
        onActivated: backend.refresh()
    }
    Shortcut {
        sequence: "T"
        context: Qt.ApplicationShortcut
        onActivated: backend.cycleTarget()
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
            border.color: hoverHandler.hovered ? statusColor : theme.surface
            clip: true

            property color statusColor: backend.online ? "#9ecab3" : "#ff4526"

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

            // Leading status bar: sage-mint when online, red when offline.
            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: 12
                width: 3
                radius: Math.min(2, theme.radius)
                color: card.statusColor

                Behavior on color {
                    ColorAnimation { duration: 160 }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 26
                anchors.rightMargin: 18
                anchors.topMargin: 16
                anchors.bottomMargin: 16
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    // Status pill
                    Rectangle {
                        width: statusPillLabel.implicitWidth + 16
                        height: 24
                        radius: Math.min(4, theme.radius)
                        color: Qt.rgba(card.statusColor.r, card.statusColor.g, card.statusColor.b, 0.16)
                        border.width: 1
                        border.color: card.statusColor

                        Text {
                            id: statusPillLabel
                            anchors.centerIn: parent
                            text: translator.language.length >= 0 ? backend.statusText : ""
                            color: card.statusColor
                            font.family: theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.letterSpacing: 0.6
                        }
                    }

                    // Live latency
                    Text {
                        text: backend.latencyMs >= 0
                              ? Number(backend.latencyMs).toLocaleString(Qt.locale(), 'f', 0) + " ms"
                              : "-- ms"
                        color: theme.brightForeground
                        font.family: theme.fontFamily
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        font.letterSpacing: -0.5
                    }

                    Item { Layout.fillWidth: true }
                }

                // Target label + up/total summary
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: backend.targetLabel
                        color: theme.foreground
                        font.family: theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        Layout.fillWidth: true

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: backend.cycleTarget()
                        }
                    }

                    Text {
                        text: translator.language.length >= 0 ? backend.targetsSummary : ""
                        color: theme.muted
                        font.family: theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }
            }

            // Minimal corner controls: refresh pill on hover, X always visible.
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
                    color: refreshMouse.containsMouse ? theme.accent : theme.surface
                    opacity: hoverHandler.hovered ? 1.0 : 0.0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "↻"
                        color: refreshMouse.containsMouse ? theme.accentForeground : theme.foreground
                        font.family: theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.refresh()
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
                    rowSpacing: 4

                    Text { text: "Space / R"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
                    Text { text: qsTr("Probe now"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 11 }

                    Text { text: "T"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
                    Text { text: qsTr("Cycle target"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 11 }

                    Text { text: "?"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
                    Text { text: qsTr("Toggle shortcuts"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 11 }

                    Text { text: "Q"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
                    Text { text: qsTr("Quit"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 11 }
                }
            }
        }
    }
}
