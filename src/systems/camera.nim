## Smooth follow camera for Together

import "../constants"
import math

const LERP_FACTOR* = 0.08
const LOOK_AHEAD_X* = 72.0
const IDLE_LOOK_AHEAD_X* = 18.0
const LOOK_AHEAD_Y_UP* = -20.0
const LOOK_AHEAD_Y_DOWN* = 26.0
const LOOK_AHEAD_LERP* = 7.5
const IMPULSE_DAMPING_X* = 7.5
const IMPULSE_DAMPING_Y* = 9.0
const RESPONSE_DECAY* = 2.4
const MAX_RESPONSE_BOOST* = 0.22
const MAX_IMPULSE_X* = 40.0
const MAX_IMPULSE_Y* = 28.0

const
  ShakeDecay = 10.0  # How fast shake amplitude decays per second.
  MaxShakes* = 4

type
  Shake* = object
    timer*: float
    duration*: float
    intensity*: float

  Camera* = object
    x*, y*: float        # current world coord of screen top-left
    targetX*, targetY*: float
    lookAheadX*, lookAheadY*: float
    impulseX*, impulseY*: float
    responseBoost*: float
    holdTimer*: float
    pendingSnapX, pendingSnapY: float
    pendingSnapActive: bool
    shakes*: array[MaxShakes, Shake]
    shakeOffsetX*: float     # per-frame render offset
    shakeOffsetY*: float

proc newCamera*(): Camera =
  Camera(
    x: 0.0,
    y: 0.0,
    targetX: 0.0,
    targetY: 0.0,
    lookAheadX: 0.0,
    lookAheadY: 0.0,
    impulseX: 0.0,
    impulseY: 0.0,
    responseBoost: 0.0,
    holdTimer: 0.0,
    pendingSnapX: 0.0,
    pendingSnapY: 0.0,
    pendingSnapActive: false
  )

proc clampf(value, low, high: float): float =
  max(low, min(high, value))

proc clampToBounds(cam: var Camera, levelWidth, levelHeight: float) =
  let maxX = max(0.0, levelWidth - float(DEFAULT_WIDTH))
  let maxY = max(0.0, levelHeight - float(DEFAULT_HEIGHT))
  cam.x = clampf(cam.x, 0.0, maxX)
  cam.y = clampf(cam.y, 0.0, maxY)
  cam.targetX = clampf(cam.targetX, 0.0, maxX)
  cam.targetY = clampf(cam.targetY, 0.0, maxY)

proc boostResponse*(cam: var Camera, amount: float) =
  cam.responseBoost = clampf(max(cam.responseBoost, amount), 0.0, MAX_RESPONSE_BOOST)

proc addImpulse*(cam: var Camera, x, y: float) =
  cam.impulseX = clampf(cam.impulseX + x, -MAX_IMPULSE_X, MAX_IMPULSE_X)
  cam.impulseY = clampf(cam.impulseY + y, -MAX_IMPULSE_Y, MAX_IMPULSE_Y)

proc centeredCameraX(charX, charW: float): float =
  charX + charW * 0.5 - float(DEFAULT_WIDTH) * 0.5

proc centeredCameraY(charY, charH: float): float =
  charY + charH * 0.5 - float(DEFAULT_HEIGHT) * 0.5

proc hold*(cam: var Camera, duration: float) =
  cam.holdTimer = max(cam.holdTimer, duration)

proc queueSnap*(cam: var Camera, charX, charY, charW, charH, levelWidth,
                levelHeight: float) =
  let maxX = max(0.0, levelWidth - float(DEFAULT_WIDTH))
  let maxY = max(0.0, levelHeight - float(DEFAULT_HEIGHT))
  cam.pendingSnapX = clampf(centeredCameraX(charX, charW), 0.0, maxX)
  cam.pendingSnapY = clampf(centeredCameraY(charY, charH), 0.0, maxY)
  cam.pendingSnapActive = true

proc flushPendingSnap(cam: var Camera, levelWidth, levelHeight: float) =
  if not cam.pendingSnapActive:
    return
  cam.x = cam.pendingSnapX
  cam.y = cam.pendingSnapY
  cam.targetX = cam.pendingSnapX
  cam.targetY = cam.pendingSnapY
  cam.pendingSnapActive = false
  cam.clampToBounds(levelWidth, levelHeight)

proc beginCameraUpdate(cam: var Camera, levelWidth, levelHeight, dt: float): bool =
  if cam.holdTimer > 0.0:
    cam.holdTimer = max(0.0, cam.holdTimer - dt)
    if cam.holdTimer > 0.0:
      return false

  if cam.pendingSnapActive:
    cam.flushPendingSnap(levelWidth, levelHeight)
    return false

  true

proc updateCameraFocus*(cam: var Camera, charX, charY, charW, charH, charVX,
                        charVY: float, facingRight: bool, levelWidth,
                        levelHeight, dt: float) =
  let desiredLookAheadX =
    if abs(charVX) > 18.0:
      clampf(charVX * 0.26, -LOOK_AHEAD_X, LOOK_AHEAD_X)
    elif facingRight:
      IDLE_LOOK_AHEAD_X
    else:
      -IDLE_LOOK_AHEAD_X

  let desiredLookAheadY =
    if charVY < -45.0:
      LOOK_AHEAD_Y_UP
    elif charVY > 90.0:
      clampf(charVY * 0.08, 0.0, LOOK_AHEAD_Y_DOWN)
    else:
      0.0

  cam.lookAheadX += (desiredLookAheadX - cam.lookAheadX) *
    min(1.0, LOOK_AHEAD_LERP * dt)
  cam.lookAheadY += (desiredLookAheadY - cam.lookAheadY) *
    min(1.0, (LOOK_AHEAD_LERP - 1.0) * dt)

  cam.impulseX *= max(0.0, 1.0 - IMPULSE_DAMPING_X * dt)
  cam.impulseY *= max(0.0, 1.0 - IMPULSE_DAMPING_Y * dt)
  cam.responseBoost = max(0.0, cam.responseBoost - RESPONSE_DECAY * dt)

proc updateCamera*(cam: var Camera, charX, charY, charW, charH: float,
                   levelWidth, levelHeight: float) =
  if not cam.beginCameraUpdate(levelWidth, levelHeight, FIXED_TIMESTEP):
    return
  cam.updateCameraFocus(charX, charY, charW, charH, 0.0, 0.0, true,
                        levelWidth, levelHeight, FIXED_TIMESTEP)
  cam.targetX = centeredCameraX(charX, charW) +
    cam.lookAheadX + cam.impulseX
  cam.targetY = centeredCameraY(charY, charH) +
    cam.lookAheadY + cam.impulseY

  let follow = min(0.34, LERP_FACTOR + cam.responseBoost)
  cam.x += (cam.targetX - cam.x) * follow
  cam.y += (cam.targetY - cam.y) * follow
  cam.clampToBounds(levelWidth, levelHeight)

proc updateCamera*(cam: var Camera, charX, charY, charW, charH, charVX,
                   charVY: float, facingRight: bool, levelWidth,
                   levelHeight, dt: float) =
  if not cam.beginCameraUpdate(levelWidth, levelHeight, dt):
    return
  cam.updateCameraFocus(charX, charY, charW, charH, charVX, charVY,
                        facingRight, levelWidth, levelHeight, dt)

  cam.targetX = centeredCameraX(charX, charW) +
    cam.lookAheadX + cam.impulseX
  cam.targetY = centeredCameraY(charY, charH) +
    cam.lookAheadY + cam.impulseY

  let follow = min(0.34, LERP_FACTOR + cam.responseBoost)
  cam.x += (cam.targetX - cam.x) * follow
  cam.y += (cam.targetY - cam.y) * follow
  cam.clampToBounds(levelWidth, levelHeight)

proc snapCamera*(cam: var Camera, charX, charY, charW, charH: float,
                 levelWidth, levelHeight: float) =
  ## Instantly position camera on character (no lerp) — use on level load
  cam.lookAheadX = 0.0
  cam.lookAheadY = 0.0
  cam.impulseX = 0.0
  cam.impulseY = 0.0
  cam.responseBoost = 0.0
  cam.holdTimer = 0.0
  cam.pendingSnapActive = false
  cam.targetX = centeredCameraX(charX, charW)
  cam.targetY = centeredCameraY(charY, charH)

  cam.x = cam.targetX
  cam.y = cam.targetY
  cam.clampToBounds(levelWidth, levelHeight)

proc triggerShake*(cam: var Camera, intensity: float, duration: float) =
  ## Start a screen shake. Uses the first free slot, or replaces the weakest.
  var bestSlot = 0
  var bestIntensity = cam.shakes[0].intensity
  for i in 0..<MaxShakes:
    if cam.shakes[i].timer <= 0.0:
      cam.shakes[i] = Shake(timer: duration, duration: duration,
                             intensity: intensity)
      return
    if cam.shakes[i].intensity < bestIntensity:
      bestIntensity = cam.shakes[i].intensity
      bestSlot = i
  cam.shakes[bestSlot] = Shake(timer: duration, duration: duration,
                                intensity: intensity)

proc updateShake*(cam: var Camera, dt: float) =
  ## Advance all shake timers and compute additive per-frame offsets.
  var totalX = 0.0
  var totalY = 0.0
  for i in 0..<MaxShakes:
    if cam.shakes[i].timer <= 0.0:
      continue
    cam.shakes[i].timer -= dt
    if cam.shakes[i].timer <= 0.0:
      cam.shakes[i].timer = 0.0
      cam.shakes[i].intensity = 0.0
      continue
    cam.shakes[i].intensity *= max(0.0, 1.0 - ShakeDecay * dt)
    let amp = cam.shakes[i].intensity
    let freqX = 97.0 + float(i) * 23.0
    let freqY = 131.0 + float(i) * 17.0
    totalX += sin(cam.shakes[i].timer * freqX) * amp
    totalY += cos(cam.shakes[i].timer * freqY) * amp
  cam.shakeOffsetX = totalX
  cam.shakeOffsetY = totalY
