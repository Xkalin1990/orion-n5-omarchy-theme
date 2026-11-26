import QtQuick
import QtQuick.Layouts

CardFrame {
    id: root
    width: 484
    height: 118
    title: "zulu"
    cardCode: "06 // ZULU"
    statusColor: theme.accent

    headerExtra: [
        Rectangle {
            width: 30; height: 18; radius: Math.min(3, theme.radius)
            color: zFmtMouse.containsMouse ? theme.accent : theme.surface
            Text {
                anchors.centerIn: parent
                text: zuluBackend.use24Hour ? "24H" : "12H"
                color: zFmtMouse.containsMouse ? theme.accentForeground : theme.foreground
                font.family: theme.fontFamily; font.pixelSize: 9; font.weight: Font.Bold
            }
            MouseArea {
                id: zFmtMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: zuluBackend.toggle24Hour()
            }
        },
        Rectangle {
            width: 28; height: 18; radius: Math.min(3, theme.radius)
            color: zSecMouse.containsMouse ? theme.accent : (zuluBackend.showSeconds ? theme.selection : theme.surface)
            Text {
                anchors.centerIn: parent; text: "SEC"
                color: zSecMouse.containsMouse ? theme.accentForeground : theme.foreground
                font.family: theme.fontFamily; font.pixelSize: 9; font.weight: Font.Bold
            }
            MouseArea {
                id: zSecMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: zuluBackend.toggleSeconds()
            }
        }
    ]

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 0

        Repeater {
            model: zuluBackend.zones

            Item {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    visible: index > 0
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    width: 1
                    color: theme.surface
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 3

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 4

                        Text {
                            text: modelData.code
                            color: modelData.code === "ZULU" ? theme.accent : theme.green
                            font.family: theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 1
                        }

                        Text {
                            visible: modelData.dayDelta.length > 0
                            text: modelData.dayDelta
                            color: theme.yellow
                            font.family: theme.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.Bold
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.time
                        color: theme.brightForeground
                        font.family: theme.fontFamily
                        font.pixelSize: zuluBackend.showSeconds ? 16 : 22
                        font.weight: Font.Bold
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.city
                        color: theme.muted
                        font.family: theme.fontFamily
                        font.pixelSize: 9
                    }
                }
            }
        }
    }
}
