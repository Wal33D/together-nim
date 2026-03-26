## Character entity — the single source of truth for character data

import
  "../constants",
  ../systems/animation,
  math

type
  CharacterAbility* = enum
    doubleJump, floatAbility, heavy, wallJump, coyoteTime, gracefulFall

  Character* = object
    id*: string
    x*, y*: float
    width*, height*: int
    colorIndex*: int
    color*: Color
    vx*, vy*: float
    grounded*: bool
    facingRight*: bool
    ability*: CharacterAbility
    jumpCount*: int
    coyoteTimer*: float
    jumpBufferTimer*: float
    atExit*: bool
    dead*: bool
    spawnX*, spawnY*: float
    wallTouching*: bool
    wallTouchDir*: int           # -1 = wall on left, +1 = wall on right
    wallSliding*: bool
    # Death/respawn animation
    deathTimer*: float          # >0 means dying; counts down from 0.5s
    respawnTimer*: float        # >0 means respawning; counts down from 0.3s
    deathFlashCount*: int       # tracks red flash count (0..3)
    # Animation
    squashX*, squashY*: float     # 1.0 = normal, <1 = squashed, >1 = stretched
    idleTimer*: float             # for idle sway
    idleFidgetTimer*: float       # stagger offset so characters don't fidget in sync
    idleOffsetX*: float           # visual horizontal offset for dreamy sway (Luca)
    lookDir*: int                 # -1/0/+1 look direction for idle look-around (Cara)
    blinking*: bool               # true during slow blink (Felix)
    blinkTimer*: float            # tracks blink duration
    landingTimer*: float          # flash on landing
    contentment*: float           # 0-1 emotional glow
    anticipation*: float          # 0-1 moving toward another character
    inputDir*: int                # -1, 0, or 1 from current input
    ridingCharacterId*: int       # index of character being stood on; -1 = none
    proximityLean*: float          # horizontal lean offset toward nearest character (0..2px)
    proximityTarget*: int          # index of nearest character within 80px (-1 if none)
    celebrateTimer*: float         # counts down from stagger delay, then triggers bounce
    celebrating*: bool             # true while bounce sequence is active
    celebrateSquash*: float        # squash target during celebrate (default 0.8, finale 0.65)
    glowScale*: float              # dynamic glow scale from proximity (default 1.8)
    glowAlpha*: float              # dynamic glow alpha from proximity (default 0.15)
    glowGoldMix*: float            # gold tint blend for full-group proximity (0..0.15)
    pupilOffset*: float             # smooth pupil direction (-1..+1); thresholded to pixel offset
    prevProximityTarget*: int        # previous frame's proximityTarget; -1 = none
    isolationTimer*: float           # seconds without any neighbour within 200 px; resets on contact
    isolationSat*: float             # 0.0 = full colour, 1.0 = near-greyscale (loneliness)
    rotation*: float                   # visual tilt in degrees; positive = lean right. Anchored at center-bottom.
    prevLeanSign*: int                 # previous lean direction sign for overshoot detection
    leanOvershootTimer*: float         # countdown for direction-reversal overshoot (0.1s)
    wallSlideOffsetX*: float           # 1-2px offset into wall during Cara wall-slide
    introGlowBoost*: float             # additive glow alpha multiplier during intro (0..2)
    wallFloatRelayActive*: bool          # true when Cara-Luca wall-float relay is active
    wallFloatRelayPartner*: int          # index of relay partner (-1 = none)
    invulnTimer*: float                  # seconds remaining of invulnerability; 0 = vulnerable
    lastLandingTime*: float              # game.elapsedTime when this character last landed
    footstepTimer*: float                  # countdown to next footstep sound
    # Landing squash recovery tween
    squashRecoveryT*: float                  # <0 = inactive; 0..1 = easeOutElastic progress
    squashXOrigin*: float                    # squashX at start of recovery
    squashYOrigin*: float                    # squashY at start of recovery

proc newCharacter*(id: string): Character =
  result.x = 0.0
  result.y = 0.0
  result.vx = 0.0
  result.vy = 0.0
  result.grounded = false
  result.facingRight = true
  result.id = id
  result.jumpCount = 0
  result.coyoteTimer = 0.0
  result.jumpBufferTimer = 0.0
  result.atExit = false
  result.dead = false
  result.wallTouching = false
  result.wallTouchDir = 0
  result.wallSliding = false
  result.squashX = 1.0
  result.squashY = 1.0
  result.idleTimer = 0.0
  result.idleFidgetTimer = 0.0
  result.idleOffsetX = 0.0
  result.lookDir = 0
  result.blinking = false
  result.blinkTimer = 0.0
  result.landingTimer = 0.0
  result.contentment = 0.0
  result.anticipation = 0.0
  result.ridingCharacterId = -1
  result.proximityLean = 0.0
  result.proximityTarget = -1
  result.celebrateTimer = 0.0
  result.celebrating = false
  result.celebrateSquash = 0.8
  result.glowScale = 1.8
  result.glowAlpha = 0.15
  result.glowGoldMix = 0.0
  result.pupilOffset = 0.0
  result.prevProximityTarget = -1
  result.isolationTimer = 0.0
  result.isolationSat = 0.0
  result.rotation = 0.0
  result.prevLeanSign = 0
  result.leanOvershootTimer = 0.0
  result.wallSlideOffsetX = 0.0
  result.introGlowBoost = 0.0
  result.wallFloatRelayActive = false
  result.wallFloatRelayPartner = -1
  result.invulnTimer = 0.0
  result.lastLandingTime = -1.0
  result.footstepTimer = 0.0
  result.squashRecoveryT = -1.0
  result.squashXOrigin = 1.0
  result.squashYOrigin = 1.0
  case id
  of "pip":
    result.width = 24; result.height = 24
    result.colorIndex = 0; result.color = PIP_COLOR
    result.ability = doubleJump
  of "luca":
    result.width = 28; result.height = 28
    result.colorIndex = 1; result.color = LUCA_COLOR
    result.ability = floatAbility
  of "bruno":
    result.width = 40; result.height = 40
    result.colorIndex = 2; result.color = BRUNO_COLOR
    result.ability = heavy
  of "cara":
    result.width = 20; result.height = 20
    result.colorIndex = 3; result.color = CARA_COLOR
    result.ability = wallJump
  of "felix":
    result.width = 20; result.height = 50
    result.colorIndex = 4; result.color = FELIX_COLOR
    result.ability = coyoteTime
  of "ivy":
    result.width = 28; result.height = 28
    result.colorIndex = 5; result.color = IVY_COLOR
    result.ability = gracefulFall
  else:
    result.width = 24; result.height = 24
    result.colorIndex = 0; result.color = (r: 128'u8, g: 128'u8, b: 128'u8)
    result.ability = doubleJump
  result.idleFidgetTimer = float(result.colorIndex) * 0.5

proc moveSpeed*(c: Character): float =
  case c.id
  of "pip": 165.0
  of "luca": 138.0
  of "bruno": 92.0
  of "cara": 182.0
  of "felix": 138.0
  of "ivy": 120.0
  else: 138.0

proc jumpForce*(c: Character): float =
  case c.id
  of "pip": -380.0
  of "luca": -320.0
  of "bruno": -280.0
  of "cara": -340.0
  of "felix": -280.0
  of "ivy": -300.0
  else: -380.0

proc updateAnimation*(c: var Character, dt: float) =
  # Squash/stretch recovery
  if c.squashRecoveryT >= 0.0:
    c.squashRecoveryT += dt / 0.15
    if c.squashRecoveryT >= 1.0:
      c.squashX = 1.0
      c.squashY = 1.0
      c.squashRecoveryT = -1.0
    else:
      let e = easeOutElastic(c.squashRecoveryT)
      c.squashX = c.squashXOrigin + (1.0 - c.squashXOrigin) * e
      c.squashY = c.squashYOrigin + (1.0 - c.squashYOrigin) * e
  else:
    c.squashX += (1.0 - c.squashX) * 8.0 * dt
    c.squashY += (1.0 - c.squashY) * 8.0 * dt

  # Celebration bounce
  if c.celebrateTimer > 0.0 and not c.celebrating:
    c.celebrateTimer -= dt
    if c.celebrateTimer <= 0.0:
      c.celebrating = true
      c.squashY = c.celebrateSquash
      c.celebrateTimer = 0.08
  elif c.celebrating and c.celebrateTimer > 0.0:
    c.celebrateTimer -= dt
    c.squashY = c.celebrateSquash
    if c.celebrateTimer <= 0.0:
      c.squashY = 1.15
  elif c.celebrating:
    if abs(c.squashY - 1.0) < 0.02:
      c.celebrating = false
      c.squashY = 1.0

  # Fall stretch — proportional to vy when falling faster than 200 px/s.
  if not c.grounded and c.vy > 200.0:
    let fallT = clamp((c.vy - 200.0) / (MAX_FALL_SPEED - 200.0), 0.0, 1.0)
    c.squashX -= 0.10 * fallT
    c.squashY += 0.15 * fallT

  # Movement lean — 2-3° tilt in movement direction.
  block:
    var targetRotation = 0.0
    if abs(c.vx) > 10.0:
      let leanT = clamp(abs(c.vx) / 180.0, 0.0, 1.0)
      let sign = if c.vx > 0.0: 1.0 else: -1.0
      targetRotation = sign * (2.0 + 1.0 * leanT)

    # Detect direction reversal and trigger overshoot.
    let curSign = if targetRotation > 0.1: 1
                  elif targetRotation < -0.1: -1
                  else: 0
    if curSign != 0 and c.prevLeanSign != 0 and curSign != c.prevLeanSign:
      c.leanOvershootTimer = 0.1
    if curSign != 0:
      c.prevLeanSign = curSign

    # During overshoot, briefly target −1° in the new direction.
    if c.leanOvershootTimer > 0.0:
      c.leanOvershootTimer -= dt
      let overshootSign = if targetRotation > 0.0: -1.0 else: 1.0
      targetRotation = overshootSign * 1.0

    let leanSpeed = if abs(targetRotation) < 0.1 and abs(c.rotation) > 0.5: 15.0 else: 10.0
    c.rotation += (targetRotation - c.rotation) * leanSpeed * dt
    if abs(c.rotation) < 0.05:
      c.rotation = 0.0

  # Cara wall-slide compress — 0.9× width, 1.05× height, offset 1-2px into wall.
  if c.wallSliding and c.ability == wallJump:
    c.squashX = min(c.squashX, 0.90)
    c.squashY = max(c.squashY, 1.05)
    c.rotation = float(c.wallTouchDir) * 5.0
    c.wallSlideOffsetX = float(c.wallTouchDir) * -1.5
  else:
    c.wallSlideOffsetX = 0.0

  # Landing timer decay
  if c.landingTimer > 0:
    c.landingTimer -= dt

  # Idle timer — reset on input or movement; otherwise increment
  if c.inputDir != 0 or abs(c.vx) > 5.0:
    c.idleTimer = 0.0
    c.idleOffsetX = 0.0
    c.lookDir = 0
    c.blinking = false
    c.blinkTimer = 0.0
  else:
    c.idleTimer += dt

  # Per-character idle fidgets (activate after 2s idle and grounded)
  if c.idleTimer > 2.0 and c.grounded:
    let fidgetTime = c.idleTimer - 2.0 + c.idleFidgetTimer
    case c.ability
    of doubleJump:
      # Pip: small bounce every 3s
      let prev = fidgetTime - dt
      if floor(fidgetTime / 3.0) > floor(prev / 3.0):
        c.squashY = 0.9
    of floatAbility:
      # Luca: dreamy side-sway
      c.idleOffsetX = 2.0 * sin(c.idleTimer * 1.5)
    of heavy:
      # Bruno: weight shift over 4s period
      c.squashX = 1.0 + sin(c.idleTimer * PI / 2.0) * 0.03
    of wallJump:
      # Cara: look-around cycling -1, +1, 0 every 1s
      let phase = int(floor(fidgetTime)) mod 3
      case phase
      of 0: c.lookDir = -1
      of 1: c.lookDir = 1
      else: c.lookDir = 0
    of coyoteTime:
      # Felix: slow blink every 5s for 0.2s
      let cyclePos = fidgetTime mod 5.0
      c.blinking = cyclePos < 0.2
    of gracefulFall:
      # Ivy: breathing — squashY oscillates +/-0.02 on 3s sine
      c.squashY = 1.0 + sin(c.idleTimer * PI * 2.0 / 3.0) * 0.02

proc triggerLanding*(c: var Character, vy: float = 300.0) =
  ## Apply landing squash proportional to fall velocity.
  const
    MinLandingVy = 80.0
    MaxLandingVy = 600.0
  let intensity = clamp((vy - MinLandingVy) / (MaxLandingVy - MinLandingVy), 0.0, 1.0)
  if intensity < 0.1:
    return
  c.squashX = 1.0 + 0.3 * intensity
  c.squashY = 1.0 - 0.3 * intensity
  c.squashXOrigin = c.squashX
  c.squashYOrigin = c.squashY
  c.squashRecoveryT = 0.0
  c.landingTimer = 0.15

proc triggerJump*(c: var Character, isDoubleJump: bool = false) =
  ## Apply jump stretch; smaller for Pip's double jump.
  if isDoubleJump:
    c.squashX = 0.85
    c.squashY = 1.15
  else:
    c.squashX = 0.7
    c.squashY = 1.3

proc drawWidth*(c: Character): float =
  float(c.width) * c.squashX

proc drawHeight*(c: Character): float =
  float(c.height) * c.squashY

proc drawX*(c: Character): float =
  ## Centered horizontally during squash/stretch
  c.x - (c.drawWidth() - float(c.width)) * 0.5

proc drawY*(c: Character): float =
  ## Anchored at feet during squash/stretch
  c.y + float(c.height) - c.drawHeight()

proc idleSway*(c: Character): float =
  ## Gentle breathing motion. Sways more when contentment is low (lonely).
  if c.grounded and abs(c.vx) < 5.0:
    let amplitude = 1.5 + (1.0 - c.contentment) * 1.0
    sin(c.idleTimer * 2.0) * amplitude
  else:
    0.0

proc isInvulnerable*(c: Character): bool =
  ## True when the character has an active invulnerability window.
  c.invulnTimer > 0.0

proc isDying*(c: Character): bool =
  ## True when the character is in the death animation phase.
  c.deathTimer > 0.0

proc isRespawning*(c: Character): bool =
  ## True when the character is fading in at spawn point.
  c.respawnTimer > 0.0

proc deathVisible*(c: Character): bool =
  ## Whether the character sprite should be drawn during death flash.
  ## 3 flashes at 50ms on, 50ms off = 300ms total flash phase.
  if not c.isDying():
    return true
  let flashPhase = 0.5 - c.deathTimer  # elapsed time since death started
  if flashPhase >= 0.3:
    return false  # after 300ms of flashing, hide until respawn
  let cyclePos = (flashPhase * 1000.0).int mod 100
  cyclePos < 50  # first 50ms of each 100ms cycle = visible

proc respawnAlpha*(c: Character): uint8 =
  ## Alpha value (0..255) for the respawn fade-in effect.
  if not c.isRespawning():
    return 255'u8
  let elapsed = 0.3 - c.respawnTimer
  let t = max(0.0, min(1.0, elapsed / 0.3))
  uint8(t * 255.0)
