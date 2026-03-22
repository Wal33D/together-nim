## Physics and collision detection system

import
  std/math,
  "../constants",
  "../entities/character",
  "../entities/level"

type
  Rect* = object
    x*, y*, w*, h*: float

  PhysicsResult* = object
    deadCharacters*: seq[string]
    exitedCharacters*: seq[string]
    landedCharacters*: seq[string]

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
      # Cara wall-slide: touching wall on the right while airborne
      if c.ability == wallJump and not c.grounded:
        c.wallTouching = true
        c.wallTouchDir = -1  # wall is to the right, push away left
        if c.vy > 120.0:
          c.vy = 120.0
    else:
      c.x = rect.x + rect.w
      # Cara wall-slide: touching wall on the left while airborne
      if c.ability == wallJump and not c.grounded:
        c.wallTouching = true
        c.wallTouchDir = 1  # wall is to the left, push away right
        if c.vy > 120.0:
          c.vy = 120.0
    c.vx = 0.0

proc updateMovingPlatforms*(level: var Level, dt: float) =
  for i in 0..<level.movingPlatforms.len:
    var mp = level.movingPlatforms[i]
    mp.prevX = mp.x
    mp.prevY = mp.y
    # Ping-pong interpolation
    if mp.forward:
      mp.currentT += mp.speed * dt
      if mp.currentT >= 1.0:
        mp.currentT = 1.0
        mp.forward = false
    else:
      mp.currentT -= mp.speed * dt
      if mp.currentT <= 0.0:
        mp.currentT = 0.0
        mp.forward = true
    mp.x = mp.startX + (mp.endX - mp.startX) * mp.currentT
    mp.y = mp.startY + (mp.endY - mp.startY) * mp.currentT
    level.movingPlatforms[i] = mp

proc applyJump*(c: var Character) =
  if c.grounded:
    c.vy = c.jumpForce()
    c.grounded = false
    c.jumpCount = 1
    c.triggerJump()

proc updatePhysics*(characters: var seq[Character], level: var Level, dt: float): PhysicsResult =
  result = PhysicsResult(deadCharacters: @[], exitedCharacters: @[], landedCharacters: @[])

  # Update moving platforms
  updateMovingPlatforms(level, dt)

  # Reset all doors to closed; buttons will re-open them below
  for d in 0..<level.doors.len:
    level.doors[d].isOpen = false

  # Snapshot and reset button active state for edge detection
  for b in 0..<level.buttons.len:
    level.buttons[b].prevActive = level.buttons[b].active
    level.buttons[b].active = false

  for i in 0..<characters.len:
    var c = characters[i]

    # Skip physics for dissolving/respawning characters
    if c.dissolving or c.respawning:
      characters[i] = c
      continue

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

    # Horizontal acceleration / deceleration
    let maxSpeed = c.moveSpeed()
    let accel = maxSpeed / GroundAccelTime
    let decel = maxSpeed / GroundDecelTime
    let airFactor = if c.grounded: 1.0 else: AirControlFactor

    if c.inputDir != 0:
      c.vx += float(c.inputDir) * accel * airFactor * dt
      c.vx = clamp(c.vx, -maxSpeed, maxSpeed)
    else:
      let step = decel * airFactor * dt
      if abs(c.vx) <= step:
        c.vx = 0.0
      else:
        c.vx -= sgn(c.vx).float * step

    # Move
    c.x += c.vx * dt
    c.y += c.vy * dt

    # Reset grounded and wall-touch before collision resolution
    let wasGrounded = c.grounded
    c.grounded = false
    c.wallTouching = false
    c.wallTouchDir = 0

    # Platform collision
    for platform in level.platforms:
      let pRect = Rect(x: platform.x, y: platform.y, w: platform.width, h: platform.height)
      if intersects(toRect(c), pRect):
        resolveCollision(c, pRect)

    # Moving platform collision + riding
    for mp in level.movingPlatforms:
      let mpRect = Rect(x: mp.x, y: mp.y, w: mp.width, h: mp.height)
      if intersects(toRect(c), mpRect):
        resolveCollision(c, mpRect)
    # Apply riding displacement: if grounded, check if standing on a moving platform
    if c.grounded:
      for mp in level.movingPlatforms:
        let feetY = c.y + float(c.height)
        let onTop = feetY >= mp.y - 1.0 and feetY <= mp.y + 2.0
        let overlapX = c.x + float(c.width) > mp.x and c.x < mp.x + mp.width
        if onTop and overlapX:
          c.x += mp.x - mp.prevX
          c.y += mp.y - mp.prevY
          break

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
      result.landedCharacters.add(c.id)

    # Hazard detection — skip during dissolve/respawn (invulnerability)
    if not c.dissolving and not c.respawning:
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

    # Button/door interaction — grounded character on button opens matching door
    if c.grounded:
      for bi in 0..<level.buttons.len:
        let bRect = Rect(x: level.buttons[bi].x, y: level.buttons[bi].y,
                         w: level.buttons[bi].width, h: level.buttons[bi].height)
        if intersects(toRect(c), bRect):
          if not level.buttons[bi].requiresHeavy or c.ability == heavy:
            level.buttons[bi].active = true
            for d in 0..<level.doors.len:
              if level.doors[d].id == level.buttons[bi].doorId:
                level.doors[d].isOpen = true

    characters[i] = c
