.pragma library

// Row indices in assets/oma-e-spritesheet.png (5 rows x 4 cols, 128x128 px each)
var ROW_IDLE = 0
var ROW_ROLL = 1
var ROW_CURIOUS = 2
var ROW_WAVE = 3
var ROW_SLEEP = 4

function createState(initialX, config) {
  var cfg = config || {}
  return {
    x: initialX || 200,
    vx: 0,
    facingRight: true,
    targetX: initialX || 200,
    cursorY: 0,
    hasTarget: false,

    // Mode: "idle", "roll", "curious", "wave", "sleep"
    mode: "idle",
    frame: 0,
    frameElapsed: 0,

    // Timers (seconds)
    noticeTimer: 0,
    pendingMove: false,
    idleElapsed: 0,
    curiousElapsed: 0,
    waveElapsed: 0,
    manualSleep: false,

    // Tunables
    deadzonePx: cfg.deadzonePx !== undefined ? cfg.deadzonePx : 44,
    followDelaySec: (cfg.followDelayMs !== undefined ? cfg.followDelayMs : 220) / 1000.0,
    maxSpeed: cfg.maxSpeed !== undefined ? cfg.maxSpeed : 340,
    accel: cfg.accel !== undefined ? cfg.accel : 980,
    decel: cfg.decel !== undefined ? cfg.decel : 1350,
    sleepAfterSec: cfg.sleepAfterSec !== undefined ? cfg.sleepAfterSec : 25
  }
}

function rowForMode(mode) {
  if (mode === "roll") return ROW_ROLL
  if (mode === "curious") return ROW_CURIOUS
  if (mode === "wave") return ROW_WAVE
  if (mode === "sleep") return ROW_SLEEP
  return ROW_IDLE
}

function setCursor(state, localX, localY) {
  var moved = !state.hasTarget || Math.abs(localX - state.targetX) > 2 || Math.abs(localY - state.cursorY) > 2
  state.targetX = localX
  state.cursorY = localY
  state.hasTarget = true

  if (moved) {
    state.idleElapsed = 0
    if (state.mode === "sleep" && !state.manualSleep) {
      state.mode = "idle"
      state.frame = 0
      state.frameElapsed = 0
    }
  }
}

function triggerWave(state) {
  state.manualSleep = false
  state.idleElapsed = 0
  state.mode = "wave"
  state.waveElapsed = 0
  state.frame = 0
  state.frameElapsed = 0
  state.vx = 0
  state.pendingMove = false
}

function setSleep(state, asleep) {
  state.manualSleep = !!asleep
  if (asleep) {
    state.mode = "sleep"
    state.vx = 0
    state.pendingMove = false
    state.frame = 0
    state.frameElapsed = 0
  } else {
    state.idleElapsed = 0
    state.mode = "idle"
    state.frame = 0
    state.frameElapsed = 0
  }
}

function step(state, dt, minX, maxX) {
  if (dt <= 0 || dt > 0.2) dt = 0.016

  var clampedTarget = Math.max(minX, Math.min(maxX, state.targetX))
  var dx = clampedTarget - state.x
  var dist = Math.abs(dx)

  // Manual or idle sleep handling
  if (state.mode === "sleep") {
    state.vx = 0
    state.frameElapsed += dt
    // Progress through power-down frames 0->3, then hold frame 3 (with gentle zZz)
    if (state.frame < 3 && state.frameElapsed >= 0.24) {
      state.frameElapsed = 0
      state.frame += 1
    } else if (state.frame === 3 && state.frameElapsed >= 0.9) {
      // Gentle breathing toggle between frames 2 and 3 while sleeping
      state.frameElapsed = 0
      state.frame = 2
    } else if (state.frame === 2 && state.idleElapsed > 2.0 && state.frameElapsed >= 0.9) {
      state.frameElapsed = 0
      state.frame = 3
    }
    state.idleElapsed += dt
    return state
  }

  // Wave reaction takes brief priority (~1.35s)
  if (state.mode === "wave") {
    state.vx = 0
    state.waveElapsed += dt
    state.frameElapsed += dt
    if (state.frameElapsed >= 0.14) {
      state.frameElapsed = 0
      state.frame = (state.frame + 1) % 4
    }
    if (state.waveElapsed >= 1.35) {
      state.mode = "idle"
      state.frame = 0
      state.frameElapsed = 0
    }
    return state
  }

  // Decide whether to chase the cursor (with natural reaction delay)
  var wantsToMove = state.hasTarget && dist > state.deadzonePx

  if (wantsToMove && state.mode !== "roll") {
    if (!state.pendingMove) {
      state.pendingMove = true
      state.noticeTimer = 0
      // Face toward the cursor right away as it "notices"
      if (Math.abs(dx) > 4) state.facingRight = dx > 0
    } else {
      state.noticeTimer += dt
      if (state.noticeTimer >= state.followDelaySec) {
        state.pendingMove = false
        state.mode = "roll"
        state.frame = 0
        state.frameElapsed = 0
      }
    }
  } else if (!wantsToMove) {
    state.pendingMove = false
    state.noticeTimer = 0
  }

  if (state.mode === "roll") {
    var dir = dx >= 0 ? 1 : -1
    if (dist > 4) state.facingRight = dir > 0

    // Stopping distance for smooth deceleration into a comfy offset near cursor
    var stopRadius = Math.max(12, state.deadzonePx * 0.55)
    var remaining = Math.max(0, dist - stopRadius)
    var desiredSpeed = 0
    if (remaining > 1) {
      // v = sqrt(2 * decel * remaining) capped at maxSpeed
      desiredSpeed = Math.min(state.maxSpeed, Math.sqrt(2 * state.decel * remaining))
    }
    var desiredVx = dir * desiredSpeed

    var dv = desiredVx - state.vx
    var maxDv = (Math.abs(desiredVx) > Math.abs(state.vx) ? state.accel : state.decel) * dt
    if (Math.abs(dv) <= maxDv) {
      state.vx = desiredVx
    } else {
      state.vx += (dv > 0 ? 1 : -1) * maxDv
    }

    state.x += state.vx * dt
    if (state.x < minX) { state.x = minX; state.vx = 0 }
    if (state.x > maxX) { state.x = maxX; state.vx = 0 }

    // Tread animation cadence scales with speed
    var speedRatio = Math.min(1.0, Math.abs(state.vx) / Math.max(1, state.maxSpeed))
    var frameDur = 0.16 - speedRatio * 0.095 // 0.16s slow -> 0.065s fast
    state.frameElapsed += dt
    if (state.frameElapsed >= frameDur) {
      state.frameElapsed = 0
      state.frame = (state.frame + 1) % 4
    }

    // Arrived smoothly
    if (remaining <= 2 && Math.abs(state.vx) < 18) {
      state.vx = 0
      state.mode = "curious"
      state.curiousElapsed = 0
      state.frame = 0
      state.frameElapsed = 0
    }
    return state
  }

  // Curious look-up right after catching up to cursor
  if (state.mode === "curious") {
    state.curiousElapsed += dt
    state.idleElapsed += dt
    state.frameElapsed += dt
    if (state.frameElapsed >= 0.22) {
      state.frameElapsed = 0
      state.frame = (state.frame + 1) % 4
    }
    if (state.curiousElapsed >= 2.2) {
      state.mode = "idle"
      state.frame = 0
      state.frameElapsed = 0
    }
    return state
  }

  // Default IDLE state
  state.idleElapsed += dt
  state.frameElapsed += dt
  if (state.frameElapsed >= 0.34) {
    state.frameElapsed = 0
    state.frame = (state.frame + 1) % 4
  }

  if (state.sleepAfterSec > 0 && state.idleElapsed >= state.sleepAfterSec) {
    state.mode = "sleep"
    state.frame = 0
    state.frameElapsed = 0
  }

  return state
}
