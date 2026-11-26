import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

CardFrame {
    id: root
    width: 376
    height: 256
    title: "slate"
    cardCode: "05 // SLATE"
    statusColor: slateBackend.saved ? theme.green : theme.accent
    dragAnywhere: false

    headerExtra: [
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: slateBackend.saved ? "SAVED" : "EDIT"
            color: slateBackend.saved ? theme.green : theme.accent
            font.family: theme.fontFamily; font.pixelSize: 9; font.weight: Font.Bold
        },
        Rectangle {
            width: 34; height: 18; radius: Math.min(3, theme.radius)
            color: cpMouse.containsMouse ? theme.accent : theme.surface
            Text { anchors.centerIn: parent; text: "COPY"; color: cpMouse.containsMouse ? theme.accentForeground : theme.foreground; font.family: theme.fontFamily; font.pixelSize: 9; font.weight: Font.Bold }
            MouseArea { id: cpMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: slateBackend.copyToClipboard() }
        },
        Rectangle {
            width: 28; height: 18; radius: Math.min(3, theme.radius)
            color: clrMouse.containsMouse ? theme.red : theme.surface
            Text { anchors.centerIn: parent; text: "CLR"; color: clrMouse.containsMouse ? theme.brightForeground : theme.foreground; font.family: theme.fontFamily; font.pixelSize: 9; font.weight: Font.Bold }
            MouseArea { id: clrMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: slateBackend.clear() }
        }
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            TextArea {
                id: editor
                text: slateBackend.text
                placeholderText: qsTr("Mission log / quick notes...")
                placeholderTextColor: theme.muted
                color: theme.brightForeground
                selectionColor: theme.accent
                selectedTextColor: theme.accentForeground
                font.family: theme.fontFamily
                font.pixelSize: 12
                wrapMode: TextEdit.Wrap
                leftPadding: 12
                rightPadding: 12
                topPadding: 10
                bottomPadding: 10
                background: Item {}
                onTextChanged: {
                    if (text !== slateBackend.text)
                        slateBackend.text = text
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 22
            color: theme.darkBackground

            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                height: 1; color: theme.surface
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                Text {
                    text: slateBackend.wordCount + "W  " + slateBackend.lineCount + "L  " + slateBackend.charCount + "C"
                    color: theme.muted
                    font.family: theme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Bold
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "~/.local/share/slate/note.md"
                    color: theme.muted
                    font.family: theme.fontFamily
                    font.pixelSize: 9
                }
            }
        }
    }
}
