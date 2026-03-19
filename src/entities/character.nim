## Character entity — the single source of truth for character data

import "../constants"
import math

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
    # Animation
    squashX*, squashY*: float     # 1.0 = normal, <1 = squashed, >1 = stretched
    idleTimer*: float             # for idle sway
    landingTimer*: float          # flash on landing
    contentment*: float           # 0-1 emotional glow

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
  result.squashX = 1.0
  result.squashY = 1.0
  result.idleTimer = 0.0
  result.landingTimer = 0.0
  result.contentment = 0.0
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
  c.squashX += (1.0 - c.squashX) * 8.0 * dt
  c.squashY += (1.0 - c.squashY) * 8.0 * dt

  # Landing timer decay
  if c.landingTimer > 0:
    c.landingTimer -= dt

  # Idle sway
  c.idleTimer += dt

  # Contentment — builds when near exit
  if c.atExit:
    c.contentment = min(1.0, c.contentment + 2.0 * dt)
  else:
    c.contentment = max(0.0, c.contentment - 0.5 * dt)

proc triggerLanding*(c: var Character) =
  c.squashX = 1.3
  c.squashY = 0.7
  c.landingTimer = 0.15

proc triggerJump*(c: var Character) =
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
  ## Gentle breathing motion
  if c.grounded and abs(c.vx) < 5.0:
    sin(c.idleTimer * 2.0) * 1.5
  else:
    0.0
