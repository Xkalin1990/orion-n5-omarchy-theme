import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
  id: root
  width: 1920
  height: 1080
  color: "#0f1110"

  property string currentUser: userModel.lastUser
  property bool loginFailed: false
  property int sessionIndex: {
    for (var i = 0; i < sessionModel.rowCount(); i++) {
      var name = (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole) || "").toString()
      if (name.indexOf("uwsm") !== -1 || name.indexOf("omarchy") !== -1)
        return i
    }
    return sessionModel.lastIndex
  }

  Image {
    anchors.fill: parent
    source: "background.png"
    fillMode: Image.PreserveAspectCrop
    opacity: 0.35
  }

  Connections {
    target: sddm
    function onLoginFailed() {
      root.loginFailed = true
      password.text = ""
      password.focus = true
    }
    function onLoginSucceeded() {
      root.loginFailed = false
    }
  }

  Column {
    anchors.centerIn: parent
    spacing: 36

    Image {
      id: logo
      source: "logo.png"
      width: Math.min(sourceSize.width, root.width * 0.72)
      height: sourceSize.width > 0 ? Math.round(width * sourceSize.height / sourceSize.width) : 0
      fillMode: Image.PreserveAspectFit
      anchors.horizontalCenter: parent.horizontalCenter
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 15

      Image {
        source: root.loginFailed ? "lock-failed.png" : "lock.png"
        width: 34
        height: 38
        fillMode: Image.PreserveAspectFit
        anchors.verticalCenter: parent.verticalCenter
      }

      Item {
        width: entry.width
        height: entry.height

        Image {
          id: entry
          source: root.loginFailed ? "entry-failed.png" : "entry.png"
          anchors.centerIn: parent
        }

        Row {
          anchors.left: parent.left
          anchors.leftMargin: 20
          anchors.verticalCenter: parent.verticalCenter
          spacing: 5

          Repeater {
            model: Math.min(password.text.length, 21)

            Image {
              source: "bullet.png"
              width: 8
              height: 8
            }
          }
        }

        TextInput {
          id: password
          anchors.fill: parent
          anchors.leftMargin: 20
          anchors.rightMargin: 20
          verticalAlignment: TextInput.AlignVCenter
          echoMode: TextInput.Password
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 22
          font.letterSpacing: 5
          passwordCharacter: "\u2022"
          color: "transparent"
          selectionColor: "transparent"
          selectedTextColor: "transparent"
          cursorDelegate: Item {}
          focus: true

          onTextChanged: root.loginFailed = false

          Keys.onPressed: {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              sddm.login(root.currentUser, password.text, root.sessionIndex)
              event.accepted = true
            }
          }
        }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.loginFailed ? "ACCESS DENIED // RETRY CREDENTIALS" : "OPERATOR: " + root.currentUser.toUpperCase() + "  //  SECTOR UPLO-07"
      color: root.loginFailed ? "#ff4526" : "#7d9689"
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 12
      font.letterSpacing: 2.5
    }
  }

  // Bottom-right Reboot & Shutdown industrial controls
  Row {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: 28
    spacing: 12

    Rectangle {
      width: 96
      height: 28
      radius: 2
      color: "#141615"
      border.width: 1
      border.color: "#25332c"

      Text {
        anchors.centerIn: parent
        text: "REBOOT"
        color: "#e5a93c"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
        font.letterSpacing: 2
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: sddm.reboot()
      }
    }

    Rectangle {
      width: 112
      height: 28
      radius: 2
      color: "#141615"
      border.width: 1
      border.color: "#ff5a1f"

      Text {
        anchors.centerIn: parent
        text: "SHUTDOWN"
        color: "#ff5a1f"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
        font.letterSpacing: 2
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: sddm.powerOff()
      }
    }
  }

  Component.onCompleted: password.forceActiveFocus()
}
