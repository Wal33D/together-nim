## Physics and collision detection system

import "../constants"
import "../entities/character"
import "../entities/level"

type
  Rect* = object
    x*, y*, w*, h*: float

  PhysicsResult* = object
    deadCharacters*: seq[string]
    exitedCharacters*: seq[string]

proc intersects*(a, b: Rect): bool =
  ## AABB collision detection
  a.x < b.x + b.w and
  a.x + a.w > b.x and
  a.y < b.y + b.h and
  a.y + a.h > b.y

proc toRect*(c: Character): Rect =
  Rect(x: c.x, y: c.y, w: float(c.width), h: float(c.height))

proc resolveCollision(c: var Character, rect: Rect) =
  ## Resolve AABB overlap by pushing the character out along the axis of minimum penetration.
  let overlapLeft   = (c.x + float(c.width)) - rect.x
  let overlapRight  = (rect.x + rect.w) - c.x
  let overlapTop    = (c.y + float(c.height)) - rect.y
  let overlapBottom = (rect.y + rect.h) - c.y

  let minX = min(overlapLeft, overlapRight)
  let minY = min(overlapTop, overlapBottom)

  if minY <= minX:
    # Vertical resolution
    if overlapTop < overlapBottom:
      # Character hit the top surface — land on it
      c.y = rect.y - float(c.height)
      if c.vy > 0.0:
        c.vy = 0.0
      c.grounded = true
    else:
      # Character hit the bottom surface — head bump
      c.y = rect.y + rect.h
      if c.vy < 0.0:
        c.vy = 0.0
  else:
    # Horizontal resolution
    if overlapLeft < overlapRight:
      c.x = rect.x - float(c.width)
    else:
      c.x = rect.x + rect.w
    c.vx = 0.0

# ---------------------------------------------------------------------------
# Character-specific physics stubs (full implementation in next ticket)
# ---------------------------------------------------------------------------

proc applyDoubleJumpStub*(c: var Character) =
  ## Stub: double jump — no-op until next ticket
  discard

proc applyFloatStub*(c: var Character, dt: float) =
  ## Stub: float ability — no-op until next ticket
  discard

proc applyHeavyStub*(c: var Character) =
  ## Stub: heavy — no-op until next ticket
  discard

proc applyWallJumpStub*(c: var Character) =
  ## Stub: wall jump — no-op until next ticket
  discard

proc applyCoyoteTimeStub*(c: var Character) =
  ## Stub: coyote time — no-op until next ticket
  discard

proc applyGracefulFallStub*(c: var Character) =
  ## Stub: graceful fall — no-op until next ticket
  discard

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

proc applyJump*(c: var Character) =
  ## Apply jump velocity if the character is grounded.
  if c.grounded:
    c.vy = JUMP_VELOCITY
    c.grounded = false

proc updatePhysics*(characters: var seq[Character], level: Level, dt: float): PhysicsResult =
  ## Apply gravity, move characters, resolve platform collisions, detect hazards and exits.
  result = PhysicsResult(deadCharacters: @[], exitedCharacters: @[])

  for i in 0..<characters.len:
    var c = characters[i]

    # --- Gravity ---
    c.vy += GRAVITY * dt
    if c.vy > MAX_FALL_SPEED:
      c.vy = MAX_FALL_SPEED

    # --- Character-specific modifiers (stubs) ---
    case c.ability
    of floatAbility:  applyFloatStub(c, dt)
    of gracefulFall:  applyGracefulFallStub(c)
    else:             discard

    # --- Move ---
    c.x += c.vx * dt
    c.y += c.vy * dt

    # Reset grounded before collision resolution
    c.grounded = false

    # --- Platform collision ---
    for platform in level.platforms:
      let pRect = Rect(x: platform.x, y: platform.y, w: platform.width, h: platform.height)
      if intersects(toRect(c), pRect):
        resolveCollision(c, pRect)

    # --- Closed door collision ---
    for door in level.doors:
      if not door.isOpen:
        let dRect = Rect(x: door.x, y: door.y, w: door.width, h: door.height)
        if intersects(toRect(c), dRect):
          resolveCollision(c, dRect)

    # --- Hazard detection ---
    block hazardCheck:
      for hazard in level.hazards:
        let hRect = Rect(x: hazard.x, y: hazard.y, w: hazard.width, h: hazard.height)
        if intersects(toRect(c), hRect):
          result.deadCharacters.add(c.id)
          break hazardCheck

    # --- Exit detection ---
    for exit in level.exits:
      if exit.characterId == c.id:
        let eRect = Rect(x: exit.x, y: exit.y, w: exit.width, h: exit.height)
        if intersects(toRect(c), eRect):
          result.exitedCharacters.add(c.id)

    characters[i] = c
