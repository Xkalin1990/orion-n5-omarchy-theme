import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons

// Oma-e desktop companion service.
// Tracks the Hyprland cursor over its UNIX socket, persists live user settings
// to settings.json, exposes IPC, and renders Oma-e along the bottom screen edge.
Item {
  id: root

  property var shell: null
  property var manifest: null

  // Live configurable settings (persisted to settings.json)
  property bool enabled: true
  property int spriteSize: 68
  property int followDelayMs: 220
  property int maxSpeed: 340
  property int sleepAfterSec: 25
  property bool clickThrough: false
  property bool hideOnFullscreen: true

  property bool settingsLoaded: false
  property bool isSleeping: false

  // Global cursor coordinates from Hyprland
  property real cursorX: -1
  property real cursorY: -1
  property bool hasCursor: false

  // Broadcast counters for IPC / bar actions
  property int waveNonce: 0
  property int sleepCommand: 0 // 0 = auto, 1 = sleep, -1 = wake

  readonly property string pluginDir: {
    var url = String(Qt.resolvedUrl("."))
    var p = url.indexOf("file://") === 0 ? url.slice(7) : url
    return p.endsWith("/") ? p.slice(0, -1) : p
  }
  readonly property string trackerScript: pluginDir + "/cursor_tracker.py"
  readonly property string settingsPath: pluginDir + "/settings.json"

  function applySettingsObject(obj) {
    if (!obj || typeof obj !== "object") return
    if (obj.enabled !== undefined) enabled = !!obj.enabled
    if (obj.size !== undefined) spriteSize = Math.max(44, Math.min(112, Math.round(Number(obj.size))))
    if (obj.followDelayMs !== undefined) followDelayMs = Math.max(0, Math.min(600, Math.round(Number(obj.followDelayMs))))
    if (obj.maxSpeed !== undefined) maxSpeed = Math.max(120, Math.min(600, Math.round(Number(obj.maxSpeed))))
    if (obj.sleepAfterSec !== undefined) sleepAfterSec = Math.max(0, Math.min(120, Math.round(Number(obj.sleepAfterSec))))
    if (obj.clickThrough !== undefined) clickThrough = !!obj.clickThrough
    if (obj.hideOnFullscreen !== undefined) hideOnFullscreen = !!obj.hideOnFullscreen
  }

  function scheduleSave() {
    if (!settingsLoaded) return
    saveDebounce.restart()
  }

  function setEnabled(v) {
    enabled = !!v
    scheduleSave()
  }
  function setSpriteSize(v) {
    spriteSize = Math.max(44, Math.min(112, Math.round(Number(v))))
    scheduleSave()
  }
  function setFollowDelayMs(v) {
    followDelayMs = Math.max(0, Math.min(600, Math.round(Number(v))))
    scheduleSave()
  }
  function setMaxSpeed(v) {
    maxSpeed = Math.max(120, Math.min(600, Math.round(Number(v))))
    scheduleSave()
  }
  function setSleepAfterSec(v) {
    sleepAfterSec = Math.max(0, Math.min(120, Math.round(Number(v))))
    scheduleSave()
  }
  function setClickThrough(v) {
    clickThrough = !!v
    scheduleSave()
  }
  function setHideOnFullscreen(v) {
    hideOnFullscreen = !!v
    scheduleSave()
  }

  function triggerWave() {
    enabled = true
    isSleeping = false
    sleepCommand = -1
    waveNonce += 1
    scheduleSave()
  }

  function toggleSleep() {
    if (isSleeping) {
      isSleeping = false
      sleepCommand = -1
    } else {
      isSleeping = true
      sleepCommand = 1
    }
  }

  function resetDefaults() {
    enabled = true
    spriteSize = 68
    followDelayMs = 220
    maxSpeed = 340
    sleepAfterSec = 25
    clickThrough = false
    hideOnFullscreen = true
    isSleeping = false
    sleepCommand = -1
    scheduleSave()
  }

  // Load persisted settings once on startup
  FileView {
    id: settingsFile
    path: root.settingsPath
    watchChanges: false
    onLoaded: {
      try {
        var raw = settingsFile.text()
        if (raw && raw.trim() !== "") {
          root.applySettingsObject(JSON.parse(raw))
        }
      } catch (e) {}
      root.settingsLoaded = true
    }
    onLoadFailed: {
      // Fall back to optional shell.json overrides if no settings.json exists yet
      var cfg = root.shell && root.shell.shellConfig && root.shell.shellConfig["oma-e"]
        ? root.shell.shellConfig["oma-e"]
        : null
      if (cfg) root.applySettingsObject(cfg)
      root.settingsLoaded = true
    }
  }

  Timer {
    id: saveDebounce
    interval: 180
    onTriggered: {
      var payload = JSON.stringify({
        enabled: root.enabled,
        size: root.spriteSize,
        followDelayMs: root.followDelayMs,
        maxSpeed: root.maxSpeed,
        sleepAfterSec: root.sleepAfterSec,
        clickThrough: root.clickThrough,
        hideOnFullscreen: root.hideOnFullscreen
      }, null, 2)
      Quickshell.execDetached([
        "python3", "-c",
        "import os, sys; p, data = sys.argv[1], sys.argv[2]; tmp = p + '.tmp'; open(tmp, 'w').write(data + '\\n'); os.replace(tmp, p)",
        root.settingsPath,
        payload
      ])
    }
  }

  Process {
    id: cursorProc
    running: root.enabled
    command: ["python3", "-u", root.trackerScript]
    stdout: SplitParser {
      onRead: function(line) {
        var parts = String(line || "").trim().split(/\s+/)
        if (parts.length < 2) return
        var x = Number(parts[0])
        var y = Number(parts[1])
        if (!isNaN(x) && !isNaN(y)) {
          root.cursorX = x
          root.cursorY = y
          root.hasCursor = true
        }
      }
    }
    onExited: function() {
      if (root.enabled) restartTimer.restart()
    }
  }

  Timer {
    id: restartTimer
    interval: 1500
    onTriggered: {
      if (root.enabled && !cursorProc.running) cursorProc.running = true
    }
  }

  ShellIpc {
    target: "oma-e"
    function toggle(): string {
      root.setEnabled(!root.enabled)
      return root.enabled ? "shown" : "hidden"
    }
    function show(): string {
      root.setEnabled(true)
      return "shown"
    }
    function hide(): string {
      root.setEnabled(false)
      return "hidden"
    }
    function wave(): string {
      root.triggerWave()
      return "ok"
    }
    function sleep(): string {
      root.isSleeping = true
      root.sleepCommand = 1
      return "sleeping"
    }
    function wake(): string {
      root.isSleeping = false
      root.sleepCommand = -1
      return "awake"
    }
    function state(): string {
      return root.enabled ? "enabled" : "disabled"
    }
  }

  Variants {
    model: Quickshell.screens
    delegate: OmaeWindow {
      required property var modelData
      screen: modelData
      service: root
    }
  }
}
