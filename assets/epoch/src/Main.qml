import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 320
    height: 128
    minimumWidth: 260
    minimumHeight: 112
    visible: true
    title: "epoch"
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

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 26
                anchors.rightMargin: 18
                anchors.topMargin: 16
                anchors.bottomMargin: 16
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: backend.timeText
                        color: theme.brightForeground
                        font.family: theme.fontFamily
                        font.pixelSize: 44
                        font.weight: Font.Bold
                        font.letterSpacing: -1
                    }

                    Text {
                        visible: backend.showSeconds
                        text: ":" + backend.secondsText
                        color: theme.accent
                        font.family: theme.fontFamily
                        font.pixelSize: 22
                        font.weight: Font.Medium
                        Layout.alignment: Qt.AlignBaseline
                    }

                    Text {
                        visible: !backend.use24Hour && backend.ampmText.length > 0
                        text: backend.ampmText
                        color: theme.muted
                        font.family: theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        Layout.alignment: Qt.AlignBaseline
                    }

                    Item { Layout.fillWidth: true }
                }

                Text {
                    // Touch translator.language so QML re-evaluates on live language switch.
                    text: translator.language.length >= 0 ? backend.dateText : ""
                    color: theme.foreground
                    font.family: theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Normal
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Minimal corner controls: 24H/12H pill on hover, X always visible.
            Row {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 10
                spacing: 6
                visible: !win.helpVisible

                Rectangle {
                    width: formatLabel.implicitWidth + 12
                    height: 20
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
                        font.pixelSize: 10
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
