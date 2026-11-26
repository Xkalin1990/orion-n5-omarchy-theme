import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: barWin
    width: deck.compact ? 612 : 760
    height: 42
    minimumWidth: 612
    minimumHeight: 42
    maximumHeight: 42
    visible: false
    title: "deck"
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.Window

    Material.theme: Material.Dark
    Material.accent: theme.accent
    Material.roundedScale: theme.radius

    property bool helpVisible: false

    Component.onCompleted: {
        deck.registerLayerWindow(barWin, "deck")
        barWin.visible = true
    }

    Shortcut { sequence: "1"; context: Qt.WindowShortcut; onActivated: deck.toggle("epoch") }
    Shortcut { sequence: "2"; context: Qt.WindowShortcut; onActivated: deck.toggle("tminus") }
    Shortcut { sequence: "3"; context: Qt.WindowShortcut; onActivated: deck.toggle("uplink") }
    Shortcut { sequence: "4"; context: Qt.WindowShortcut; onActivated: deck.toggle("signal") }
    Shortcut { sequence: "5"; context: Qt.WindowShortcut; onActivated: deck.toggle("slate") }
    Shortcut { sequence: "6"; context: Qt.WindowShortcut; onActivated: deck.toggle("zulu") }
    Shortcut { sequence: "7"; context: Qt.WindowShortcut; onActivated: deck.toggle("sys") }
    Shortcut { sequence: "C"; context: Qt.WindowShortcut; onActivated: deck.toggleCompact() }
    Shortcut { sequence: "G"; context: Qt.WindowShortcut; onActivated: deck.arrangeAll() }
    Shortcut { sequence: "A"; context: Qt.WindowShortcut; onActivated: deck.toggleAll() }
    Shortcut { sequence: "?"; context: Qt.WindowShortcut; onActivated: barWin.helpVisible = !barWin.helpVisible }
    Shortcut { sequence: "Ctrl+Q"; context: Qt.ApplicationShortcut; onActivated: Qt.quit() }

    readonly property var toggleModel: [
        { id: "epoch",  key: "1", label: "EPOCH",  active: deck.epochVisible },
        { id: "tminus", key: "2", label: "TMINUS", active: deck.tminusVisible },
        { id: "uplink", key: "3", label: "UPLINK", active: deck.uplinkVisible },
        { id: "signal", key: "4", label: "SIGNAL", active: deck.signalVisible },
        { id: "slate",  key: "5", label: "SLATE",  active: deck.slateVisible },
        { id: "zulu",   key: "6", label: "ZULU",   active: deck.zuluVisible },
        { id: "sys",    key: "7", label: "SYS",    active: deck.sysVisible }
    ]

    Item {
        anchors.fill: parent
        LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
        LayoutMirroring.childrenInherit: true

        Rectangle {
            anchors.fill: parent
            radius: theme.radius
            color: theme.background
            border.width: 1
            border.color: barHover.hovered ? theme.accent : theme.muted
            clip: true

            Behavior on border.color { ColorAnimation { duration: 140 } }

            HoverHandler { id: barHover }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                onPressed: deck.beginDrag(barWin, "deck")
                onPositionChanged: {
                    if (pressed)
                        deck.updateDrag(barWin, "deck")
                }
                onReleased: deck.endDrag()
                onCanceled: deck.endDrag()
            }

            // Left aerospace orange trim bar.
            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: 3
                color: theme.accent
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                spacing: 8

                // Brand badge
                Row {
                    spacing: 6
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        anchors.verticalCenter: parent.verticalCenter
                        color: deck.activeCount > 0 ? theme.accent : theme.muted
                    }

                    Text {
                        text: "D350 // DECK"
                        color: theme.brightForeground
                        font.family: theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                    }
                }

                Rectangle {
                    width: 1
                    height: 20
                    color: theme.surface
                }

                // 6 Widget Toggle Pills
                RowLayout {
                    spacing: 5
                    Layout.fillWidth: true

                    Repeater {
                        model: barWin.toggleModel

                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 26
                            radius: Math.min(3, theme.radius)
                            color: modelData.active
                                   ? (pillMouse.containsMouse ? theme.accent : theme.selection)
                                   : (pillMouse.containsMouse ? theme.surface : theme.darkBackground)
                            border.width: 1
                            border.color: modelData.active ? theme.accent : theme.surface

                            Row {
                                anchors.centerIn: parent
                                spacing: 5

                                Rectangle {
                                    width: 5
                                    height: 5
                                    radius: 2.5
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: modelData.active
                                           ? (pillMouse.containsMouse ? theme.accentForeground : theme.accent)
                                           : theme.muted
                                }

                                Text {
                                    text: modelData.label
                                    color: modelData.active
                                           ? (pillMouse.containsMouse ? theme.accentForeground : theme.brightForeground)
                                           : theme.foreground
                                    font.family: theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.6
                                }
                            }

                            MouseArea {
                                id: pillMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: deck.toggle(modelData.id)
                            }
                        }
                    }
                }

                // Size mode toggle (STD / MINI)
                Rectangle {
                    width: 38
                    height: 26
                    radius: Math.min(3, theme.radius)
                    color: deck.compact
                           ? (sizeMouse.containsMouse ? theme.accent : theme.selection)
                           : (sizeMouse.containsMouse ? theme.accent : theme.surface)
                    border.width: 1
                    border.color: deck.compact || sizeMouse.containsMouse ? theme.accent : theme.muted

                    Text {
                        anchors.centerIn: parent
                        text: deck.compact ? "MINI" : "STD"
                        color: sizeMouse.containsMouse ? theme.accentForeground : theme.brightForeground
                        font.family: theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: sizeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: deck.toggleCompact()
                    }
                }

                // Snap / auto-arrange cards under bar
                Rectangle {
                    width: 26
                    height: 26
                    radius: Math.min(3, theme.radius)
                    color: gridMouse.containsMouse ? theme.accent : theme.surface
                    border.width: 1
                    border.color: gridMouse.containsMouse ? theme.accent : theme.muted

                    Text {
                        anchors.centerIn: parent
                        text: "⊞"
                        color: gridMouse.containsMouse ? theme.accentForeground : theme.foreground
                        font.family: theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: gridMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: deck.arrangeAll()
                    }
                }

                // Toggle All button
                Rectangle {
                    width: 34
                    height: 26
                    radius: Math.min(3, theme.radius)
                    color: allMouse.containsMouse ? theme.accent : theme.surface
                    border.width: 1
                    border.color: allMouse.containsMouse ? theme.accent : theme.muted

                    Text {
                        anchors.centerIn: parent
                        text: deck.activeCount === 7 ? qsTr("OFF") : qsTr("ALL")
                        color: allMouse.containsMouse ? theme.accentForeground : theme.foreground
                        font.family: theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: allMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: deck.toggleAll()
                    }
                }

                // Quit Deck button
                Rectangle {
                    width: 24
                    height: 24
                    radius: Math.min(3, theme.radius)
                    color: quitMouse.containsMouse ? theme.red : theme.surface
                    border.width: 1
                    border.color: quitMouse.containsMouse ? theme.red : theme.muted

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: theme.brightForeground
                        font.family: theme.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: quitMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.quit()
                    }
                }
            }

            // Inline help strip when '?' is pressed
            Rectangle {
                anchors.fill: parent
                color: theme.darkBackground
                visible: barWin.helpVisible

                MouseArea {
                    anchors.fill: parent
                    onClicked: barWin.helpVisible = false
                }

                Text {
                    anchors.centerIn: parent
                    text: qsTr("1-6: Toggle Card   A: Toggle All   Drag: Move   Ctrl+Q: Quit   ?: Close")
                    color: theme.foreground
                    font.family: theme.fontFamily
                    font.pixelSize: 11
                }
            }
        }
    }

    // Independent frameless widget cards controlled by the top bar.
    EpochCard  { visible: deck.epochVisible;  onCloseRequested: deck.setCardVisible("epoch", false) }
    TminusCard { visible: deck.tminusVisible; onCloseRequested: deck.setCardVisible("tminus", false) }
    UplinkCard { visible: deck.uplinkVisible; onCloseRequested: deck.setCardVisible("uplink", false) }
    SignalCard { visible: deck.signalVisible; onCloseRequested: deck.setCardVisible("signal", false) }
    SlateCard  { visible: deck.slateVisible;  onCloseRequested: deck.setCardVisible("slate", false) }
    ZuluCard   { visible: deck.zuluVisible;   onCloseRequested: deck.setCardVisible("zulu", false) }
    SysCard    { visible: deck.sysVisible;    onCloseRequested: deck.setCardVisible("sys", false) }
}
