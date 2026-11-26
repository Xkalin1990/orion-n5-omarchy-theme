import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import "RobotPhysics.js" as Physics

// One screen's bottom-edge transparent layer surface for Oma-e.
// ExclusionMode.Ignore ensures tiled windows are never shifted; mask limits
// pointer input strictly to the robot's bounding box (or empty in clickThrough mode).
PanelWindow {
  id: win

  property var service: null

  readonly property var monitor: Hyprland.monitorFor(screen)
  readonly property var workspace: monitor ? monitor.activeWorkspace : null
  readonly property int workspaceId: workspace ? workspace.id : -1

  readonly property int monX: monitor && monitor.lastIpcObject ? (monitor.lastIpcObject.x || 0) : 0
  readonly property int monY: monitor && monitor.lastIpcObject ? (monitor.lastIpcObject.y || 0) : 0
  readonly property int monW: screen ? screen.width : 1280
  readonly property int monH: screen ? screen.height : 720

  // Hide automatically behind fullscreen apps (mode 2 or 3 in Hyprland).
  readonly property int fullscreenMode: {
    var mode = 0
    var toplevels = Hyprland.toplevels.values
    for (var i = 0; i < toplevels.length; i++) {
      var toplevel = toplevels[i]
      if (!toplevel.workspace || toplevel.workspace.id !== workspaceId) continue
      var ipc = toplevel.lastIpcObject
      mode = Math.max(mode, ipc && ipc.fullscreen ? ipc.fullscreen : 0)
    }
    return mode
  }

  readonly property bool cursorOnThisScreen: {
    if (!service || !service.hasCursor) return monitor ? monitor.focused : true
    return service.cursorX >= monX && service.cursorX < monX + monW &&
           service.cursorY >= monY && service.cursorY < monY + monH
  }

  readonly property bool shown: !!service && service.enabled &&
    (!service.hideOnFullscreen || fullscreenMode < 2) &&
    (cursorOnThisScreen || Quickshell.screens.length <= 1)

  readonly property int spriteSize: service ? service.spriteSize : 68

  anchors {
    left: true
    right: true
    bottom: true
  }

  implicitHeight: spriteSize + 10
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.exclusionMode: ExclusionMode.Ignore
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  WlrLayershell.namespace: "omarchy-oma-e"

  // Only the robot itself accepts clicks; the rest of the bottom strip is click-through.
  mask: Region {
    item: (win.shown && service && !service.clickThrough) ? robotHitbox : null
  }

  // Mutable kinematics state owned by this screen's Oma-e instance
  property var phys: Physics.createState(Math.round(win.monW * 0.5), {
    followDelayMs: service ? service.followDelayMs : 220,
    maxSpeed: service ? service.maxSpeed : 340,
    sleepAfterSec: service ? service.sleepAfterSec : 25
  })

  property real robotX: win.monW * 0.5
  property bool facingRight: true
  property int spriteRow: 0
  property int spriteCol: 0

  function syncFromPhys() {
    robotX = phys.x
    facingRight = phys.facingRight
    spriteRow = Physics.rowForMode(phys.mode)
    spriteCol = phys.frame
  }

  Connections {
    target: service
    function onFollowDelayMsChanged() {
      win.phys.followDelaySec = service.followDelayMs / 1000.0
    }
    function onMaxSpeedChanged() {
      win.phys.maxSpeed = service.maxSpeed
    }
    function onSleepAfterSecChanged() {
      win.phys.sleepAfterSec = service.sleepAfterSec
    }
    function onCursorXChanged() {
      if (win.cursorOnThisScreen && service.hasCursor) {
        Physics.setCursor(win.phys, service.cursorX - win.monX, service.cursorY - win.monY)
      }
    }
    function onCursorYChanged() {
      if (win.cursorOnThisScreen && service.hasCursor) {
        Physics.setCursor(win.phys, service.cursorX - win.monX, service.cursorY - win.monY)
      }
    }
    function onWaveNonceChanged() {
      if (win.shown) {
        Physics.triggerWave(win.phys)
        win.syncFromPhys()
      }
    }
    function onSleepCommandChanged() {
      if (service.sleepCommand === 1) {
        Physics.setSleep(win.phys, true)
        win.syncFromPhys()
      } else if (service.sleepCommand === -1) {
        Physics.setSleep(win.phys, false)
        win.syncFromPhys()
      }
    }
  }

  // 60 FPS kinematics + sprite animation tick
  Timer {
    id: tickTimer
    interval: 16
    repeat: true
    running: win.shown
    property double lastMs: Date.now()
    onRunningChanged: if (running) lastMs = Date.now()
    onTriggered: {
      var now = Date.now()
      var dt = Math.min(0.05, Math.max(0.004, (now - lastMs) / 1000.0))
      lastMs = now
      var margin = Math.round(win.spriteSize * 0.55)
      Physics.step(win.phys, dt, margin, Math.max(margin + 1, win.width - margin))
      win.syncFromPhys()
    }
  }

  // Robot sprite & clickable hitbox
  Item {
    id: robotHitbox
    visible: win.shown
    width: win.spriteSize
    height: win.spriteSize
    x: Math.round(win.robotX - width / 2)
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 2
    opacity: win.shown ? 1 : 0

    Behavior on opacity {
      NumberAnimation {
        duration: Style.duration(180)
        easing.type: Easing.OutCubic
      }
    }

    // Clipped 1-frame viewport into the 4x5 sprite sheet
    Item {
      anchors.fill: parent
      clip: true
      transform: Scale {
        origin.x: robotHitbox.width / 2
        origin.y: robotHitbox.height / 2
        xScale: win.facingRight ? 1 : -1
      }

      Image {
        id: sheetImg
        source: Qt.resolvedUrl("assets/oma-e-spritesheet.png")
        width: win.spriteSize * 4
        height: win.spriteSize * 5
        x: -win.spriteCol * win.spriteSize
        y: -win.spriteRow * win.spriteSize
        smooth: true
        mipmap: true
        cache: true
      }
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          Physics.setSleep(win.phys, win.phys.mode !== "sleep")
        } else {
          Physics.triggerWave(win.phys)
        }
        win.syncFromPhys()
      }
    }
  }
}
