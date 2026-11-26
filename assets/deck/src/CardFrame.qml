import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Window {
    id: cardWin
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.Window

    Material.theme: Material.Dark
    Material.accent: theme.accent
    Material.roundedScale: theme.radius

    property string cardCode: "00 // CARD"
    property color statusColor: theme.accent
    property bool dragAnywhere: true
    property alias headerExtra: extraSlot.data
    default property alias bodyContent: contentHost.data

    signal closeRequested()

    Item {
        anchors.fill: parent
        LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
        LayoutMirroring.childrenInherit: true

        Rectangle {
            id: chassis
            anchors.fill: parent
            radius: theme.radius
            color: theme.background
            border.width: 1
            border.color: cardHover.hovered ? theme.accent : theme.muted
            clip: true

            Behavior on border.color {
                ColorAnimation { duration: 140 }
            }

            HoverHandler {
                id: cardHover
            }

            // Optional full-card drag handle for non-editor widgets.
            MouseArea {
                anchors.fill: parent
                enabled: cardWin.dragAnywhere
                acceptedButtons: Qt.LeftButton
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                onPressed: cardWin.startSystemMove()
            }

            // Top 2px telemetry accent hairline.
            Rectangle {
                id: topRule
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 2
                color: cardWin.statusColor
            }

            // Recessed header bar (always draggable).
            Rectangle {
                id: headerBar
                anchors.top: topRule.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 28
                color: theme.darkBackground

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    onPressed: cardWin.startSystemMove()
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: theme.surface
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 6
                    spacing: 6

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: cardWin.statusColor
                    }

                    Text {
                        text: cardWin.cardCode
                        color: theme.foreground
                        font.family: theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                    }

                    Item { Layout.fillWidth: true }

                    Row {
                        id: extraSlot
                        spacing: 4
                    }

                    Rectangle {
                        width: 18
                        height: 18
                        radius: Math.min(3, theme.radius)
                        color: closeArea.containsMouse ? theme.accent : theme.surface
                        border.width: 1
                        border.color: closeArea.containsMouse ? theme.accent : theme.muted

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: closeArea.containsMouse ? theme.accentForeground : theme.brightForeground
                            font.family: theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }

                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cardWin.closeRequested()
                        }
                    }
                }
            }

            // Card body container.
            Item {
                id: contentHost
                anchors.top: headerBar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
            }
        }
    }
}
