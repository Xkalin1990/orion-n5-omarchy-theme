import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 360
    height: 240
    minimumWidth: 260
    minimumHeight: 160
    visible: true
    title: "slate"
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.Window
    font.family: theme.fontFamily

    Material.theme: Material.Dark
    Material.accent: theme.accent
    Material.roundedScale: theme.radius

    property bool helpVisible: false

    Shortcut {
        sequence: "Ctrl+S"
        context: Qt.ApplicationShortcut
        onActivated: backend.saveNow()
    }
    Shortcut {
        sequence: "Ctrl+L"
        context: Qt.ApplicationShortcut
        onActivated: backend.clear()
    }
    Shortcut {
        sequence: "Ctrl+Q"
        context: Qt.ApplicationShortcut
        onActivated: Qt.quit()
    }
    Shortcut {
        sequence: "?"
        context: Qt.ApplicationShortcut
        onActivated: win.helpVisible = !win.helpVisible
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
            border.color: hoverHandler.hovered || editor.activeFocus ? theme.accent : theme.surface
            clip: true

            Behavior on border.color {
                ColorAnimation { duration: 140 }
            }

            HoverHandler {
                id: hoverHandler
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Top header strip acts as the drag handle.
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        onPressed: win.startSystemMove()
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 6
                        spacing: 8

                        Rectangle {
                            width: 6
                            height: 6
                            radius: Math.min(3, theme.radius)
                            color: theme.accent
                        }

                        Text {
                            text: "SLATE // LOG"
                            color: theme.foreground
                            font.family: theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.letterSpacing: 0.8
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: translator.language.length >= 0
                                  ? (backend.saved ? qsTr("SAVED") : qsTr("EDITING"))
                                  : ""
                            color: backend.saved ? theme.muted : theme.accent
                            font.family: theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.5
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
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: theme.surface
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    TextArea {
                        id: editor
                        text: backend.text
                        color: theme.brightForeground
                        selectionColor: theme.accent
                        selectedTextColor: theme.accentForeground
                        placeholderText: translator.language.length >= 0 ? qsTr("Write a note...") : ""
                        placeholderTextColor: theme.muted
                        font.family: theme.fontFamily
                        font.pixelSize: 13
                        wrapMode: TextEdit.Wrap
                        padding: 10
                        background: null
                        focus: true

                        onTextChanged: {
                            if (text !== backend.text)
                                backend.text = text
                        }

                        Connections {
                            target: backend
                            function onTextChanged() {
                                if (editor.text !== backend.text)
                                    editor.text = backend.text
                            }
                        }

                        Component.onCompleted: forceActiveFocus()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    color: theme.surface

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        Text {
                            text: backend.charCount + "c · " + backend.lineCount + "L"
                            color: theme.muted
                            font.family: theme.fontFamily
                            font.pixelSize: 10
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "?"
                            color: theme.muted
                            font.family: theme.fontFamily
                            font.pixelSize: 10
                        }
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

                    Text { text: "Ctrl+S"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold }
                    Text { text: qsTr("Save now"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 12 }

                    Text { text: "Ctrl+L"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold }
                    Text { text: qsTr("Clear note"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 12 }

                    Text { text: "?"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold }
                    Text { text: qsTr("Toggle shortcuts"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 12 }

                    Text { text: "Ctrl+Q / Esc"; color: theme.accent; font.family: theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold }
                    Text { text: qsTr("Quit"); color: theme.foreground; font.family: theme.fontFamily; font.pixelSize: 12 }
                }
            }
        }
    }
}
