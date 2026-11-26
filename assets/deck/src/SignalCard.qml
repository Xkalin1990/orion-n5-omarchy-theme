import QtQuick
import QtQuick.Layouts

CardFrame {
    id: root
    width: deck.compact ? 300 : 374
    height: deck.compact ? 124 : 156
    title: "signal"
    cardCode: "04 // SIGNAL"
    statusColor: signalBackend.playing ? theme.accent : theme.muted

    headerExtra: [
        Row {
            spacing: 2
            height: 14
            anchors.verticalCenter: parent.verticalCenter
            visible: signalBackend.playing

            Repeater {
                model: [10, 14, 7]
                Rectangle {
                    required property int modelData
                    required property int index
                    width: 2; height: modelData; anchors.bottom: parent.bottom
                    color: theme.accent
                    SequentialAnimation on height {
                        running: signalBackend.playing
                        loops: Animation.Infinite
                        NumberAnimation { to: 4; duration: 280 + index * 90 }
                        NumberAnimation { to: 14; duration: 260 + index * 70 }
                    }
                }
            }
        }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 10
        anchors.bottomMargin: 12
        spacing: 6

        Text {
            text: signalBackend.title
            color: theme.brightForeground
            font.family: theme.fontFamily
            font.pixelSize: 16
            font.weight: Font.Bold
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            text: signalBackend.artist
            color: theme.foreground
            font.family: theme.fontFamily
            font.pixelSize: 11
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: signalBackend.positionText + " / " + signalBackend.durationText
                color: theme.muted
                font.family: theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: 5

                Rectangle {
                    width: 26; height: 24; radius: Math.min(3, theme.radius)
                    color: prevMouse.containsMouse ? theme.accent : theme.surface
                    Text { anchors.centerIn: parent; text: "⏮"; color: prevMouse.containsMouse ? theme.accentForeground : theme.foreground; font.pixelSize: 11 }
                    MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: signalBackend.prevTrack() }
                }

                Rectangle {
                    width: 34; height: 24; radius: Math.min(3, theme.radius)
                    color: ppMouse.containsMouse || signalBackend.playing ? theme.accent : theme.selection
                    border.width: 1; border.color: theme.accent
                    Text { anchors.centerIn: parent; text: signalBackend.playing ? "⏸" : "▶"; color: ppMouse.containsMouse || signalBackend.playing ? theme.accentForeground : theme.brightForeground; font.pixelSize: 12 }
                    MouseArea { id: ppMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: signalBackend.playPause() }
                }

                Rectangle {
                    width: 26; height: 24; radius: Math.min(3, theme.radius)
                    color: nextMouse.containsMouse ? theme.accent : theme.surface
                    Text { anchors.centerIn: parent; text: "⏭"; color: nextMouse.containsMouse ? theme.accentForeground : theme.foreground; font.pixelSize: 11 }
                    MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: signalBackend.nextTrack() }
                }
            }
        }
    }

    Rectangle {
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 4; color: theme.darkBackground
        Rectangle {
            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
            width: parent.width * signalBackend.progress
            color: signalBackend.playing ? theme.accent : theme.muted
        }
    }
}
