import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 460
    height: 104
    minimumWidth: 380
    minimumHeight: 96
    visible: true
    title: "zulu"
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
        onActivated: backend.toggle24Hour()
    }
    Shortcut {
        sequence: "S"
        context: Qt.ApplicationShortcut
        onActivated: backend.toggleSeconds()
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

            // Subtle accent bar along the leading edge.
            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: 12
                width: 3
                radius: Math.min(2, theme.radius)
                color: theme.accent
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 16
                anchors.topMargin: 22
                anchors.bottomMargin: 12
                spacing: 8

                Repeater {
                    model: backend.zones

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: modelData.code
                                    color: modelData.code === "ZULU" ? theme.accent : theme.muted
                                    font.family: theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1
                                }

                                Text {
                                    visible: modelData.dayDelta.length > 0
                                    text: modelData.dayDelta
                                    color: theme.accent
                                    font.family: theme.fontFamily
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }

                                Item { Layout.fillWidth: true }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.time
                                color: theme.brightForeground
                                font.family: theme.fontFamily
                                font.pixelSize: 16
                                font.weight: Font.Bold
                                fontSizeMode: Text.HorizontalFit
                                minimumPixelSize: 11
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.city
                                color: theme.muted
                                font.family: theme.fontFamily
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            // Minimal corner controls: 24H/12H pill on hover, X always visible.
            Row {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 8
                spacing: 6
                visible: !win.helpVisible

                Rectangle {
                    width: formatLabel.implicitWidth + 10
                    height: 18
                    radius: Math.min(4, theme.radius)
                    color: formatMouse.containsMouse ? theme.accent : theme.surface
                    opacity: hoverHandler.hovered ? 1.0 : 0.0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }

                    Text {
                        id: formatLabel
                        anchors.centerIn: parent
                        text: backend.use24Hour ? qsTr("24H") : qsTr("12H")
                        color: formatMouse.containsMouse ? theme.accentForeground : theme.foreground
                        font.family: theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: formatMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.toggle24Hour()
                    }
                }

                Rectangle {
                    width: 18
                    height: 18
                    radius: Math.min(4, theme.radius)
                    color: closeMouse.containsMouse ? theme.accent : theme.surface
                    border.width: 1
                    border.color: closeMouse.containsMouse ? theme.accent : theme.muted

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: closeMouse.containsMouse ? theme.accentForeground : theme.brightForeground
                        font.family: theme.fontFamily
                        font.pixelSize: 12
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
                    columns: 4
                    columnSpacing: 14
                    rowSpacing: 6

                    Text { text: "Space"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold }
                    Text { text: qsTr("Toggle 12h / 24h"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 12 }
                    Text { text: "S"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold }
                    Text { text: qsTr("Toggle seconds"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 12 }

                    Text { text: "?"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold }
                    Text { text: qsTr("Toggle shortcuts"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 12 }
                    Text { text: "Q"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold }
                    Text { text: qsTr("Quit"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 12 }
                }
            }
        }
    }
}
