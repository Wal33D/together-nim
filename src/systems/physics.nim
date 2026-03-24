## Physics and collision detection system

import
  std/[algorithm, math],
  "../constants",
  "../entities/character",
  "../entities/level"

type
  Rect* = object
    x*, y*, w*, h*: float

  LandedCharacter* = object
    id*: string
    fallVelocity*: float
    ability*: CharacterAbility

  PhysicsResult* = object
    deadCharacters*: seq[string]
    hazardCharacters*: seq[string]
    exitedCharacters*: seq[string]
    landedCharacters*: seq[LandedCharacter]

  SuperBounceResult* = object
    triggered*: bool
    contactX*, contactY*: float

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

proc nextWaypointIndex*(mp: MovingPlatform): int =
  ## Return the index of the next waypoint based on current direction.
  let n = mp.waypoints.len
  if mp.forward:
    (mp.currentWaypoint + 1) mod n
  else:
    (mp.currentWaypoint - 1 + n) mod n

proc updateMovingPlatforms*(level: var Level, dt: float) =
  for i in 0..<level.movingPlatforms.len:
    var mp = level.movingPlatforms[i]
    mp.prevX = mp.x
    mp.prevY = mp.y
    let n = mp.waypoints.len
    if n < 2:
      level.movingPlatforms[i] = mp
      continue

    let nextIdx = nextWaypointIndex(mp)
    let cur = mp.waypoints[mp.currentWaypoint]
    let nxt = mp.waypoints[nextIdx]
    let dx = nxt.x - cur.x
    let dy = nxt.y - cur.y
    let dist = sqrt(dx * dx + dy * dy)
    if dist > 0.0:
      mp.progress += dt * mp.speed / dist
    else:
      mp.progress = 1.0

    if mp.progress >= 1.0:
      mp.progress -= 1.0
      mp.currentWaypoint = nextIdx
      if mp.pingPong:
        if mp.forward and mp.currentWaypoint >= n - 1:
          mp.forward = false
        elif not mp.forward and mp.currentWaypoint <= 0:
          mp.forward = true

    # Sinusoidal ease: smooth accel/decel at endpoints.
    let curWp = mp.waypoints[mp.currentWaypoint]
    let nxtWp = mp.waypoints[nextWaypointIndex(mp)]
    let t = (1.0 - cos(mp.progress * PI)) / 2.0
    mp.x = curWp.x + (nxtWp.x - curWp.x) * t
    mp.y = curWp.y + (nxtWp.y - curWp.y) * t
    level.movingPlatforms[i] = mp

proc applyJump*(c: var Character) =
  if c.grounded:
    c.vy = c.jumpForce()
    c.grounded = false
    c.jumpCount = 1
    c.triggerJump()

proc updatePhysics*(characters: var seq[Character], level: var Level, dt: float): PhysicsResult =
  result = PhysicsResult(deadCharacters: @[], hazardCharacters: @[],
                         exitedCharacters: @[], landedCharacters: @[])

  # Update moving platforms
  updateMovingPlatforms(level, dt)

  # Reset all doors to closed; buttons will re-open them below
  for d in 0..<level.doors.len:
    level.doors[d].isOpen = false

  # Snapshot and reset button active state for edge detection
  for b in 0..<level.buttons.len:
    level.buttons[b].prevActive = level.buttons[b].active
    level.buttons[b].active = false

  # Snapshot X positions before per-character physics so dx captures full displacement.
  var prevX = newSeq[float](characters.len)
  for i in 0..<characters.len:
    prevX[i] = characters[i].x

  for i in 0..<characters.len:
    var c = characters[i]

    # Skip physics for dying/respawning characters
    if c.isDying() or c.isRespawning():
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
    let preLandVy = c.vy
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
      c.triggerLanding(preLandVy)
      result.landedCharacters.add(LandedCharacter(
        id: c.id, fallVelocity: preLandVy, ability: c.ability))

    # Tick invulnerability timer.
    if c.invulnTimer > 0.0:
      c.invulnTimer -= dt
      if c.invulnTimer < 0.0:
        c.invulnTimer = 0.0

    # Hazard detection — skip during death/respawn/invulnerability
    if not c.isDying() and not c.isRespawning() and not c.isInvulnerable():
      block hazardCheck:
        for hazard in level.hazards:
          let hRect = Rect(x: hazard.x, y: hazard.y, w: hazard.width, h: hazard.height)
          if intersects(toRect(c), hRect):
            result.deadCharacters.add(c.id)
            result.hazardCharacters.add(c.id)
            break hazardCheck

      # Fell off screen
      if c.y > float(DEFAULT_HEIGHT) + 100.0:
        result.deadCharacters.add(c.id)

    # Exit detection
    for exit in level.exits:
      if exit.sharedExit or exit.characterId == c.id:
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

  # Wall-float relay: Luca's float slows Cara's wall-slide when aligned.
  for i in 0..<characters.len:
    characters[i].wallFloatRelayActive = false
    characters[i].wallFloatRelayPartner = -1
  for i in 0..<characters.len:
    if characters[i].ability != wallJump or not characters[i].wallTouching:
      continue
    if characters[i].vy <= 0.0:
      continue
    if characters[i].isDying() or characters[i].isRespawning():
      continue
    # Cara is wall-sliding and falling. Look for Luca below within horizontal range.
    for j in 0..<characters.len:
      if characters[j].ability != floatAbility:
        continue
      if characters[j].isDying() or characters[j].isRespawning():
        continue
      let horizDist = abs(characters[i].x - characters[j].x)
      if horizDist > WallFloatRelayMaxHorizDist:
        continue
      if characters[j].y <= characters[i].y:
        continue
      # Relay active: cap Cara's wall-slide speed.
      if characters[i].vy > WallFloatRelaySpeedCap:
        characters[i].vy = WallFloatRelaySpeedCap
      characters[i].wallFloatRelayActive = true
      characters[i].wallFloatRelayPartner = j
      characters[j].wallFloatRelayActive = true
      characters[j].wallFloatRelayPartner = i
      break

  # Character-character collision pass
  for i in 0..<characters.len:
    for j in (i + 1)..<characters.len:
      if characters[i].isDying() or characters[i].isRespawning():
        continue
      if characters[j].isDying() or characters[j].isRespawning():
        continue

      let a = toRect(characters[i])
      let b = toRect(characters[j])
      if not intersects(a, b):
        continue

      let overlapX = min(a.x + a.w - b.x, b.x + b.w - a.x)
      let overlapY = min(a.y + a.h - b.y, b.y + b.h - a.y)

      if overlapY <= overlapX + 4.0:
        # Vertical resolution
        let half = overlapY / 2.0
        if a.y < b.y:
          # A is above B: push A up, B down
          characters[i].y -= half
          characters[j].y += half
          characters[i].grounded = true
          characters[i].vy = 0.0
          characters[i].jumpCount = 0
          characters[i].coyoteTimer = 0.0
        else:
          # B is above A: push B up, A down
          characters[j].y -= half
          characters[i].y += half
          characters[j].grounded = true
          characters[j].vy = 0.0
          characters[j].jumpCount = 0
          characters[j].coyoteTimer = 0.0
      else:
        # Horizontal resolution
        let half = overlapX / 2.0
        if a.x < b.x:
          characters[i].x -= half
          characters[j].x += half
        else:
          characters[i].x += half
          characters[j].x -= half

  # Detect riding relationships.
  for i in 0..<characters.len:
    characters[i].ridingCharacterId = -1
  for i in 0..<characters.len:
    if characters[i].isDying() or characters[i].isRespawning():
      continue
    for j in (i + 1)..<characters.len:
      if characters[j].isDying() or characters[j].isRespawning():
        continue
      # Check if i is riding j or j is riding i.
      for (upper, lower) in [(i, j), (j, i)]:
        if not characters[upper].grounded:
          continue
        let feetY = characters[upper].y + float(characters[upper].height)
        let topY = characters[lower].y
        if abs(feetY - topY) > 2.0:
          continue
        let overlapX = characters[upper].x < characters[lower].x + float(characters[lower].width) and
                       characters[upper].x + float(characters[upper].width) > characters[lower].x
        if overlapX:
          characters[upper].ridingCharacterId = lower

  # Carry riders: process sorted by Y descending (base characters first).
  var order = newSeq[tuple[y: float, idx: int]](characters.len)
  for i in 0..<characters.len:
    order[i] = (y: characters[i].y, idx: i)
  order.sort(proc(a, b: tuple[y: float, idx: int]): int =
    cmp(b.y, a.y))
  for entry in order:
    let idx = entry.idx
    let dx = characters[idx].x - prevX[idx]
    if abs(dx) > 0.0001:
      for r in 0..<characters.len:
        if characters[r].ridingCharacterId == idx:
          characters[r].x += dx

proc applySuperBounce*(characters: var seq[Character], idx: int): SuperBounceResult =
  ## Detect Pip riding Bruno and apply 1.5x jump velocity with Bruno squash.
  result = SuperBounceResult(triggered: false)
  let c = characters[idx]
  if c.colorIndex != 0 or c.ability != doubleJump:
    return
  if not c.grounded:
    return
  let rideIdx = c.ridingCharacterId
  if rideIdx < 0 or rideIdx >= characters.len:
    return
  if characters[rideIdx].colorIndex != 2:
    return
  # Apply super bounce to Pip.
  characters[idx].vy = characters[idx].jumpForce() * SuperBounceMultiplier
  characters[idx].grounded = false
  characters[idx].jumpCount = 1
  characters[idx].triggerJump()
  # Squash Bruno.
  characters[rideIdx].squashX = 1.3
  characters[rideIdx].squashY = 0.7
  # Contact point at Pip's feet / Bruno's top.
  result.triggered = true
  result.contactX = characters[idx].x + float(characters[idx].width) * 0.5
  result.contactY = characters[idx].y + float(characters[idx].height)

proc findComboPartner*(characters: seq[Character], idx: int): int =
  ## Return the index of a valid combo partner for character idx, or -1.
  let ci = characters[idx].colorIndex
  for pair in ComboPairs:
    var partnerColor = -1
    if pair.a == ci: partnerColor = pair.b
    elif pair.b == ci: partnerColor = pair.a
    if partnerColor < 0:
      continue
    for j in 0..<characters.len:
      if j == idx: continue
      if characters[j].colorIndex != partnerColor: continue
      if characters[j].isDying() or characters[j].isRespawning(): continue
      # Check riding relationship.
      if characters[idx].ridingCharacterId == j or characters[j].ridingCharacterId == idx:
        return j
      # Check AABB adjacency: gap < ComboProximity in both axes.
      let ai = toRect(characters[idx])
      let bj = toRect(characters[j])
      let gapX = max(0.0, max(bj.x - (ai.x + ai.w), ai.x - (bj.x + bj.w)))
      let gapY = max(0.0, max(bj.y - (ai.y + ai.h), ai.y - (bj.y + bj.h)))
      if gapX < ComboProximity and gapY < ComboProximity:
        return j
  -1
