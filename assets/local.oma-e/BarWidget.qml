import QtQuick
import Quickshell
import qs.Ui
import qs.Commons
import qs.Commons as Commons

// Top bar widget + PopupCard settings panel for Oma-e.
// Left-click opens settings; right-click toggles Oma-e on/off; middle-click waves.
BarWidget {
  id: root
  moduleName: "local.oma-e"

  readonly property var omae: bar?.shell?.serviceFor("local.oma-e")
  readonly property bool isOn: !!omae && omae.enabled

  property bool popupOpen: false
  function close() { popupOpen = false }

  implicitWidth: Style.space(28)
  implicitHeight: bar && bar.thickness ? bar.thickness : 26

  // Crisp custom Oma-e slender gyro-wheel icon (unmistakably distinct from Agents)
  Image {
    id: barGlyph
    anchors.centerIn: parent
    width: Style.space(20)
    height: Style.space(20)
    source: Qt.resolvedUrl("assets/oma-e-bar-icon.png")
    smooth: true
    mipmap: true
    opacity: root.isOn ? 1.0 : 0.35

    Behavior on opacity {
      NumberAnimation { duration: Style.duration(160) }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onClicked: function(mouse) {
      if (!root.omae) return
      if (mouse.button === Qt.RightButton) {
        root.omae.setEnabled(!root.omae.enabled)
      } else if (mouse.button === Qt.MiddleButton) {
        root.omae.triggerWave()
      } else {
        root.popupOpen = !root.popupOpen
      }
    }
    onEntered: if (root.bar) root.bar.showTooltip(root, root.isOn ? "Oma-e · Active (click for settings, right-click to hide)" : "Oma-e · Hidden (click for settings, right-click to show)")
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(300))
    contentHeight: popup.fittedContentHeight(contentCol.implicitHeight)

    Column {
      id: contentCol
      width: popup.contentWidth
      spacing: Style.spacing.md

      // Header row: icon + title + master toggle
      Item {
        width: parent.width
        height: Math.max(headerLeft.implicitHeight, masterSwitch.implicitHeight)

        Row {
          id: headerLeft
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.spacing.sm

          // Tiny live Oma-e sprite thumbnail in popup header
          Item {
            width: Style.space(28)
            height: Style.space(28)
            clip: true
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.isOn ? 1.0 : 0.45
            Image {
              source: Qt.resolvedUrl("assets/oma-e-spritesheet.png")
              width: parent.width * 4
              height: parent.height * 5
              x: 0
              y: 0
              smooth: true
              mipmap: true
            }
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            Text {
              textFormat: Text.PlainText
              text: "Oma-e"
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
              color: Commons.Color.popups.text
            }
            Text {
              textFormat: Text.PlainText
              text: root.isOn ? "Desktop companion active" : "Hidden"
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              color: Util.alpha(Commons.Color.popups.text, 0.65)
            }
          }
        }

        ToggleSwitch {
          id: masterSwitch
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          checked: root.isOn
          foreground: Commons.Color.popups.text
          accent: Commons.Color.accent
          onToggled: if (root.omae) root.omae.setEnabled(!root.omae.enabled)
        }
      }

      // Quick action buttons
      Row {
        width: parent.width
        spacing: Style.spacing.sm

        Button {
          width: Math.floor((parent.width - Style.spacing.sm * 2) / 3)
          text: "Wave"
          enabled: !!root.omae
          onClicked: if (root.omae) root.omae.triggerWave()
        }
        Button {
          width: Math.floor((parent.width - Style.spacing.sm * 2) / 3)
          text: (root.omae && root.omae.isSleeping) ? "Wake" : "Sleep"
          enabled: root.isOn
          onClicked: if (root.omae) root.omae.toggleSleep()
        }
        Button {
          width: Math.floor((parent.width - Style.spacing.sm * 2) / 3)
          text: "Reset"
          enabled: !!root.omae
          onClicked: if (root.omae) root.omae.resetDefaults()
        }
      }

      PanelSeparator { width: parent.width }

      // Size slider
      Column {
        width: parent.width
        spacing: Style.spacing.xs
        Item {
          width: parent.width
          height: sizeLbl.implicitHeight
          Text {
            id: sizeLbl
            textFormat: Text.PlainText
            text: "Size"
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            color: Commons.Color.popups.text
          }
          Text {
            textFormat: Text.PlainText
            anchors.right: parent.right
            text: (root.omae ? root.omae.spriteSize : 68) + " px"
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            color: Util.alpha(Commons.Color.popups.text, 0.7)
          }
        }
        PanelSlider {
          width: parent.width
          bar: root.bar
          minimum: 44
          maximum: 112
          step: 4
          integer: true
          value: root.omae ? root.omae.spriteSize : 68
          onMoved: function(v) { if (root.omae) root.omae.setSpriteSize(v) }
        }
      }

      // Follow Delay slider
      Column {
        width: parent.width
        spacing: Style.spacing.xs
        Item {
          width: parent.width
          height: delayLbl.implicitHeight
          Text {
            id: delayLbl
            textFormat: Text.PlainText
            text: "Follow delay"
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            color: Commons.Color.popups.text
          }
          Text {
            textFormat: Text.PlainText
            anchors.right: parent.right
            text: (root.omae ? root.omae.followDelayMs : 220) + " ms"
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            color: Util.alpha(Commons.Color.popups.text, 0.7)
          }
        }
        PanelSlider {
          width: parent.width
          bar: root.bar
          minimum: 0
          maximum: 600
          step: 20
          integer: true
          value: root.omae ? root.omae.followDelayMs : 220
          onMoved: function(v) { if (root.omae) root.omae.setFollowDelayMs(v) }
        }
      }

      // Max Speed slider
      Column {
        width: parent.width
        spacing: Style.spacing.xs
        Item {
          width: parent.width
          height: speedLbl.implicitHeight
          Text {
            id: speedLbl
            textFormat: Text.PlainText
            text: "Speed"
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            color: Commons.Color.popups.text
          }
          Text {
            textFormat: Text.PlainText
            anchors.right: parent.right
            text: (root.omae ? root.omae.maxSpeed : 340) + " px/s"
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            color: Util.alpha(Commons.Color.popups.text, 0.7)
          }
        }
        PanelSlider {
          width: parent.width
          bar: root.bar
          minimum: 120
          maximum: 600
          step: 20
          integer: true
          value: root.omae ? root.omae.maxSpeed : 340
          onMoved: function(v) { if (root.omae) root.omae.setMaxSpeed(v) }
        }
      }

      // Sleep After slider
      Column {
        width: parent.width
        spacing: Style.spacing.xs
        Item {
          width: parent.width
          height: sleepLbl.implicitHeight
          Text {
            id: sleepLbl
            textFormat: Text.PlainText
            text: "Sleep after idle"
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            color: Commons.Color.popups.text
          }
          Text {
            textFormat: Text.PlainText
            anchors.right: parent.right
            text: (root.omae && root.omae.sleepAfterSec === 0) ? "Never" : ((root.omae ? root.omae.sleepAfterSec : 25) + " s")
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            color: Util.alpha(Commons.Color.popups.text, 0.7)
          }
        }
        PanelSlider {
          width: parent.width
          bar: root.bar
          minimum: 0
          maximum: 120
          step: 5
          integer: true
          value: root.omae ? root.omae.sleepAfterSec : 25
          onMoved: function(v) { if (root.omae) root.omae.setSleepAfterSec(v) }
        }
      }

      PanelSeparator { width: parent.width }

      // Click-through toggle
      Item {
        width: parent.width
        height: Math.max(ctLbl.implicitHeight, ctSwitch.implicitHeight)
        Text {
          id: ctLbl
          textFormat: Text.PlainText
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Click-through robot"
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          color: Commons.Color.popups.text
        }
        ToggleSwitch {
          id: ctSwitch
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          checked: !!root.omae && root.omae.clickThrough
          foreground: Commons.Color.popups.text
          accent: Commons.Color.accent
          onToggled: if (root.omae) root.omae.setClickThrough(!root.omae.clickThrough)
        }
      }

      // Hide on fullscreen toggle
      Item {
        width: parent.width
        height: Math.max(fsLbl.implicitHeight, fsSwitch.implicitHeight)
        Text {
          id: fsLbl
          textFormat: Text.PlainText
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Hide in fullscreen"
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          color: Commons.Color.popups.text
        }
        ToggleSwitch {
          id: fsSwitch
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          checked: !root.omae || root.omae.hideOnFullscreen
          foreground: Commons.Color.popups.text
          accent: Commons.Color.accent
          onToggled: if (root.omae) root.omae.setHideOnFullscreen(!root.omae.hideOnFullscreen)
        }
      }
    }
  }
}
