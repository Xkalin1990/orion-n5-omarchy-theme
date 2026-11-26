import QtQuick
import QtQuick.Layouts

CardFrame {
    id: root
    width: deck.compact ? 300 : 374
    height: deck.compact ? 124 : 156
    title: "epoch"
    cardCode: "01 // EPOCH"
    statusColor: theme.accent

    headerExtra: [
        Rectangle {
            width: 30; height: 18; radius: Math.min(3, theme.radius)
            color: fmtMouse.containsMouse ? theme.accent : theme.surface
            Text {
                anchors.centerIn: parent
                text: epochBackend.use24Hour ? "24H" : "12H"
                color: fmtMouse.containsMouse ? theme.accentForeground : theme.foreground
                font.family: theme.fontFamily; font.pixelSize: 9; font.weight: Font.Bold
            }
            MouseArea {
                id: fmtMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: epochBackend.toggle24Hour()
            }
        },
        Rectangle {
            width: 28; height: 18; radius: Math.min(3, theme.radius)
            color: secMouse.containsMouse ? theme.accent : (epochBackend.showSeconds ? theme.selection : theme.surface)
            Text {
                anchors.centerIn: parent
                text: "SEC"
                color: secMouse.containsMouse ? theme.accentForeground : theme.foreground
                font.family: theme.fontFamily; font.pixelSize: 9; font.weight: Font.Bold
            }
            MouseArea {
                id: secMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: epochBackend.toggleSeconds()
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

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: epochBackend.timeText
                color: theme.brightForeground
                font.family: theme.fontFamily
                font.pixelSize: deck.compact ? 30 : 44
                font.weight: Font.Bold
                font.letterSpacing: -1
            }

            Text {
                visible: epochBackend.showSeconds
                text: ":" + epochBackend.secondsText
                color: theme.accent
                font.family: theme.fontFamily
                font.pixelSize: deck.compact ? 16 : 22
                font.weight: Font.Medium
                Layout.alignment: Qt.AlignBaseline
            }

            Text {
                visible: !epochBackend.use24Hour && epochBackend.ampmText.length > 0
                text: epochBackend.ampmText
                color: theme.muted
                font.family: theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignBaseline
            }

            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: translator.language.length >= 0 ? epochBackend.dateText : ""
                color: theme.foreground
                font.family: theme.fontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                width: weekLbl.implicitWidth + 10
                height: 18
                radius: Math.min(3, theme.radius)
                color: theme.selection
                Text {
                    id: weekLbl
                    anchors.centerIn: parent
                    text: epochBackend.weekText
                    color: theme.green
                    font.family: theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
            }
        }
    }

    // Minute sweep progress bar along bottom edge.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 3
        color: theme.darkBackground

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * epochBackend.minuteProgress
            color: theme.accent
        }
    }
}
