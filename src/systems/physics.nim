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
  a.x < b.x + b.w and
  a.x + a.w > b.x and
  a.y < b.y + b.h and
  a.y + a.h > b.y

proc toRect*(c: Character): Rect =
  Rect(x: c.x, y: c.y, w: float(c.width), h: float(c.height))

proc resolveCollision(c: var Character, rect: Rect) =
  let overlapLeft   = (c.x + float(c.width)) - rect.x
  let overlapRight  = (rect.x + rect.w) - c.x
  let overlapTop    = (c.y + float(c.height)) - rect.y
  let overlapBottom = (rect.y + rect.h) - c.y

  let minX = min(overlapLeft, overlapRight)
  let minY = min(overlapTop, overlapBottom)

  if minY <= minX:
    if overlapTop < overlapBottom:
      c.y = rect.y - float(c.height)
      if c.vy > 0.0:
        c.vy = 0.0
      c.grounded = true
      c.jumpCount = 0
      c.coyoteTimer = 0.0
    else:
      c.y = rect.y + rect.h
      if c.vy < 0.0:
        c.vy = 0.0
  else:
    if overlapLeft < overlapRight:
      c.x = rect.x - float(c.width)
    else:
      c.x = rect.x + rect.w
    c.vx = 0.0

proc applyJump*(c: var Character) =
  if c.grounded:
    c.vy = c.jumpForce()
    c.grounded = false
    c.jumpCount = 1
    c.triggerJump()

proc updatePhysics*(characters: var seq[Character], level: Level, dt: float): PhysicsResult =
  result = PhysicsResult(deadCharacters: @[], exitedCharacters: @[])

  for i in 0..<characters.len:
    var c = characters[i]

    # Gravity — ability-specific
    let grav = case c.ability
      of floatAbility: FLOAT_GRAVITY
      of gracefulFall: GRACEFUL_GRAVITY
      of heavy: GRAVITY * 1.3
      else: GRAVITY
    c.vy += grav * dt

    # Terminal velocity — ability-specific
    let maxFall = case c.ability
      of gracefulFall: GRACEFUL_TERMINAL
      of floatAbility: GRACEFUL_TERMINAL
      else: MAX_FALL_SPEED
    if c.vy > maxFall:
      c.vy = maxFall

    # Coyote time tracking
    if not c.grounded:
      c.coyoteTimer += dt

    # Friction
    if c.grounded:
      c.vx *= FRICTION
    else:
      c.vx *= AIR_RESISTANCE

    # Move
    c.x += c.vx * dt
    c.y += c.vy * dt

    # Reset grounded before collision resolution
    let wasGrounded = c.grounded
    c.grounded = false

    # Platform collision
    for platform in level.platforms:
      let pRect = Rect(x: platform.x, y: platform.y, w: platform.width, h: platform.height)
      if intersects(toRect(c), pRect):
        resolveCollision(c, pRect)

    # Closed door collision
    for door in level.doors:
      if not door.isOpen:
        let dRect = Rect(x: door.x, y: door.y, w: door.width, h: door.height)
        if intersects(toRect(c), dRect):
          resolveCollision(c, dRect)

    # Keep coyote time from last grounded frame
    if wasGrounded and not c.grounded:
      c.coyoteTimer = 0.0  # just left ground, start coyote window

    # Trigger landing animation on touchdown
    if not wasGrounded and c.grounded:
      c.triggerLanding()

    # Hazard detection
    block hazardCheck:
      for hazard in level.hazards:
        let hRect = Rect(x: hazard.x, y: hazard.y, w: hazard.width, h: hazard.height)
        if intersects(toRect(c), hRect):
          result.deadCharacters.add(c.id)
          break hazardCheck

    # Fell off screen
    if c.y > float(DEFAULT_HEIGHT) + 100.0:
      result.deadCharacters.add(c.id)

    # Exit detection
    for exit in level.exits:
      if exit.characterId == c.id:
        let eRect = Rect(x: exit.x, y: exit.y, w: exit.width, h: exit.height)
        if intersects(toRect(c), eRect):
          result.exitedCharacters.add(c.id)

    characters[i] = c
