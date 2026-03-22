import std/math
import unittest
import "../src/systems/physics"
import "../src/entities/character"
import "../src/entities/level"
import "../src/constants"

suite "intersects (AABB)":
  test "overlapping rects intersect":
    let a = Rect(x: 0.0, y: 0.0, w: 10.0, h: 10.0)
    let b = Rect(x: 5.0, y: 5.0, w: 10.0, h: 10.0)
    check intersects(a, b) == true

  test "touching edge rects do not intersect":
    let a = Rect(x: 0.0, y: 0.0, w: 10.0, h: 10.0)
    let b = Rect(x: 10.0, y: 0.0, w: 10.0, h: 10.0)
    check intersects(a, b) == false

  test "separated rects do not intersect":
    let a = Rect(x: 0.0, y: 0.0, w: 10.0, h: 10.0)
    let b = Rect(x: 20.0, y: 20.0, w: 10.0, h: 10.0)
    check intersects(a, b) == false

  test "one rect inside another intersects":
    let a = Rect(x: 0.0, y: 0.0, w: 100.0, h: 100.0)
    let b = Rect(x: 10.0, y: 10.0, w: 10.0, h: 10.0)
    check intersects(a, b) == true

  test "identical rects intersect":
    let a = Rect(x: 5.0, y: 5.0, w: 20.0, h: 20.0)
    check intersects(a, a) == true

  test "horizontal separation means no intersection":
    let a = Rect(x: 0.0, y: 0.0, w: 10.0, h: 10.0)
    let b = Rect(x: 11.0, y: 0.0, w: 10.0, h: 10.0)
    check intersects(a, b) == false

  test "vertical separation means no intersection":
    let a = Rect(x: 0.0, y: 0.0, w: 10.0, h: 10.0)
    let b = Rect(x: 0.0, y: 11.0, w: 10.0, h: 10.0)
    check intersects(a, b) == false

suite "gravity":
  test "vy increases with gravity each frame":
    var chars = @[newCharacter("pip")]
    chars[0].x = 100.0
    chars[0].y = 0.0
    var level = Level(platforms: @[], hazards: @[], exits: @[], buttons: @[], doors: @[])
    let dt = FIXED_TIMESTEP
    discard updatePhysics(chars, level, dt)
    check chars[0].vy > 0.0

  test "gravity accumulates over multiple frames":
    var chars = @[newCharacter("pip")]
    chars[0].x = 100.0
    chars[0].y = 0.0
    var level = Level(platforms: @[], hazards: @[], exits: @[], buttons: @[], doors: @[])
    let dt = FIXED_TIMESTEP
    discard updatePhysics(chars, level, dt)
    let vy1 = chars[0].vy
    discard updatePhysics(chars, level, dt)
    check chars[0].vy > vy1

  test "vy is clamped to MAX_FALL_SPEED":
    var chars = @[newCharacter("pip")]
    chars[0].vy = MAX_FALL_SPEED - 1.0
    var level = Level(platforms: @[], hazards: @[], exits: @[], buttons: @[], doors: @[])
    discard updatePhysics(chars, level, 1.0)
    check chars[0].vy <= MAX_FALL_SPEED

suite "platform collision":
  test "character lands on platform from above":
    var chars = @[newCharacter("pip")]
    # Position the character just above the platform, falling downward
    let platY = 400.0
    chars[0].x = 100.0
    chars[0].y = platY - float(chars[0].height) - 1.0
    chars[0].vy = 200.0  # falling
    var level = Level(
      platforms: @[Platform(x: 0.0, y: platY, width: 1280.0, height: 20.0)],
      hazards: @[], exits: @[], buttons: @[], doors: @[]
    )
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    check chars[0].grounded == true
    check chars[0].y == platY - float(chars[0].height)
    check chars[0].vy == 0.0

  test "grounded is false when airborne":
    var chars = @[newCharacter("pip")]
    chars[0].x = 100.0
    chars[0].y = 0.0
    var level = Level(platforms: @[], hazards: @[], exits: @[], buttons: @[], doors: @[])
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    check chars[0].grounded == false

  test "character does not pass through platform floor":
    var chars = @[newCharacter("pip")]
    chars[0].x = 50.0
    chars[0].y = 380.0
    chars[0].vy = 500.0  # fast fall
    let platform = Platform(x: 0.0, y: 400.0, width: 500.0, height: 20.0)
    var level = Level(platforms: @[platform], hazards: @[], exits: @[], buttons: @[], doors: @[])
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    check chars[0].y <= platform.y - float(chars[0].height) + 0.01

  test "horizontal movement is blocked by wall platform":
    var chars = @[newCharacter("pip")]
    # Thin vertical wall to the right
    chars[0].x = 90.0
    chars[0].y = 100.0
    chars[0].vx = 200.0
    chars[0].vy = 0.0
    let wall = Platform(x: 100.0, y: 0.0, width: 20.0, height: 200.0)
    var level = Level(platforms: @[wall], hazards: @[], exits: @[], buttons: @[], doors: @[])
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    # Character should not have passed through the wall
    check chars[0].x + float(chars[0].width) <= wall.x + 1.0

suite "applyJump":
  test "jump sets vy to JUMP_VELOCITY when grounded":
    var c = newCharacter("pip")
    c.grounded = true
    applyJump(c)
    check c.vy == JUMP_VELOCITY
    check c.grounded == false

  test "jump does nothing when not grounded":
    var c = newCharacter("pip")
    c.grounded = false
    c.vy = 0.0
    applyJump(c)
    check c.vy == 0.0

suite "hazard collision":
  test "character touching hazard is marked dead":
    var chars = @[newCharacter("pip")]
    chars[0].x = 50.0
    chars[0].y = 50.0
    let hazard = Hazard(x: 40.0, y: 40.0, width: 30.0, height: 30.0)
    var level = Level(platforms: @[], hazards: @[hazard], exits: @[], buttons: @[], doors: @[])
    let res = updatePhysics(chars, level, FIXED_TIMESTEP)
    check "pip" in res.deadCharacters

  test "character not touching hazard is not dead":
    var chars = @[newCharacter("pip")]
    chars[0].x = 0.0
    chars[0].y = 0.0
    let hazard = Hazard(x: 500.0, y: 500.0, width: 30.0, height: 30.0)
    var level = Level(platforms: @[], hazards: @[hazard], exits: @[], buttons: @[], doors: @[])
    let res = updatePhysics(chars, level, FIXED_TIMESTEP)
    check "pip" notin res.deadCharacters

suite "exit detection":
  test "character in their exit zone is marked exited":
    var chars = @[newCharacter("pip")]
    chars[0].x = 100.0
    chars[0].y = 100.0
    let exit = Exit(x: 90.0, y: 90.0, width: 50.0, height: 50.0, characterId: "pip")
    var level = Level(platforms: @[], hazards: @[], exits: @[exit], buttons: @[], doors: @[])
    let res = updatePhysics(chars, level, FIXED_TIMESTEP)
    check "pip" in res.exitedCharacters

  test "character in another character's exit is not marked":
    var chars = @[newCharacter("pip")]
    chars[0].x = 100.0
    chars[0].y = 100.0
    let exit = Exit(x: 90.0, y: 90.0, width: 50.0, height: 50.0, characterId: "luca")
    var level = Level(platforms: @[], hazards: @[], exits: @[exit], buttons: @[], doors: @[])
    let res = updatePhysics(chars, level, FIXED_TIMESTEP)
    check "pip" notin res.exitedCharacters

  test "character not in exit zone is not marked":
    var chars = @[newCharacter("pip")]
    chars[0].x = 0.0
    chars[0].y = 0.0
    let exit = Exit(x: 500.0, y: 500.0, width: 50.0, height: 50.0, characterId: "pip")
    var level = Level(platforms: @[], hazards: @[], exits: @[exit], buttons: @[], doors: @[])
    let res = updatePhysics(chars, level, FIXED_TIMESTEP)
    check "pip" notin res.exitedCharacters

suite "button/door mechanics":
  test "grounded character on button opens matching door":
    var chars = @[newCharacter("pip")]
    chars[0].x = 100.0
    chars[0].y = 376.0  # on platform at y=400
    chars[0].grounded = true
    let btn = Button(x: 90.0, y: 390.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: false)
    let door = Door(id: 1, x: 300.0, y: 350.0, width: 20.0, height: 50.0, isOpen: false)
    let platform = Platform(x: 0.0, y: 400.0, width: 500.0, height: 20.0)
    var level = Level(platforms: @[platform], hazards: @[], exits: @[], buttons: @[btn], doors: @[door])
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    check level.doors[0].isOpen == true

  test "heavy button only responds to Bruno":
    # Non-heavy character (pip) should NOT press heavy button
    var chars = @[newCharacter("pip")]
    chars[0].x = 100.0
    chars[0].y = 376.0
    chars[0].grounded = true
    let btn = Button(x: 90.0, y: 390.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: true)
    let door = Door(id: 1, x: 300.0, y: 350.0, width: 20.0, height: 50.0, isOpen: false)
    let platform = Platform(x: 0.0, y: 400.0, width: 500.0, height: 20.0)
    var level = Level(platforms: @[platform], hazards: @[], exits: @[], buttons: @[btn], doors: @[door])
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    check level.doors[0].isOpen == false

  test "Bruno can press heavy button":
    var chars = @[newCharacter("bruno")]
    chars[0].x = 100.0
    chars[0].y = 360.0  # bruno is 40px tall, so y=360 puts bottom at 400
    chars[0].grounded = true
    let btn = Button(x: 90.0, y: 390.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: true)
    let door = Door(id: 1, x: 300.0, y: 350.0, width: 20.0, height: 50.0, isOpen: false)
    let platform = Platform(x: 0.0, y: 400.0, width: 500.0, height: 20.0)
    var level = Level(platforms: @[platform], hazards: @[], exits: @[], buttons: @[btn], doors: @[door])
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    check level.doors[0].isOpen == true

  test "door closes when character leaves button":
    var chars = @[newCharacter("pip")]
    # First frame: on button
    chars[0].x = 100.0
    chars[0].y = 376.0
    chars[0].grounded = true
    let btn = Button(x: 90.0, y: 390.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: false)
    let door = Door(id: 1, x: 300.0, y: 350.0, width: 20.0, height: 50.0, isOpen: false)
    let platform = Platform(x: 0.0, y: 400.0, width: 500.0, height: 20.0)
    var level = Level(platforms: @[platform], hazards: @[], exits: @[], buttons: @[btn], doors: @[door])
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    check level.doors[0].isOpen == true
    # Second frame: move away from button
    chars[0].x = 500.0
    chars[0].grounded = true
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    check level.doors[0].isOpen == false

  test "closed door blocks character":
    var chars = @[newCharacter("pip")]
    chars[0].x = 290.0
    chars[0].y = 376.0
    chars[0].vx = 200.0
    let door = Door(id: 1, x: 300.0, y: 350.0, width: 20.0, height: 80.0, isOpen: false)
    let platform = Platform(x: 0.0, y: 400.0, width: 500.0, height: 20.0)
    var level = Level(platforms: @[platform], hazards: @[], exits: @[], buttons: @[], doors: @[door])
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    check chars[0].x + float(chars[0].width) <= door.x + 1.0

suite "wall jump (Cara)":
  test "Cara detects wall touch when hitting wall while airborne":
    var chars = @[newCharacter("cara")]
    chars[0].x = 95.0  # near wall at x=100
    chars[0].y = 50.0
    chars[0].vx = 200.0
    chars[0].grounded = false
    let wall = Platform(x: 100.0, y: 0.0, width: 20.0, height: 200.0)
    var level = Level(platforms: @[wall], hazards: @[], exits: @[], buttons: @[], doors: @[])
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    check chars[0].wallTouching == true

  test "Cara wall-slide caps vy at 120":
    var chars = @[newCharacter("cara")]
    chars[0].x = 95.0
    chars[0].y = 50.0
    chars[0].vx = 200.0
    chars[0].vy = 300.0  # falling fast
    chars[0].grounded = false
    let wall = Platform(x: 100.0, y: 0.0, width: 20.0, height: 200.0)
    var level = Level(platforms: @[wall], hazards: @[], exits: @[], buttons: @[], doors: @[], movingPlatforms: @[])
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    check chars[0].vy <= 120.0

suite "moving platforms":
  test "moving platform position updates with time":
    var mp = newMovingPlatform(0.0, 0.0, 100.0, 0.0, 80.0, 20.0, 1.0)
    var level = Level(platforms: @[], hazards: @[], exits: @[], buttons: @[], doors: @[],
                      movingPlatforms: @[mp])
    var chars: seq[Character] = @[]
    discard updatePhysics(chars, level, 0.5)
    # After 0.5s at migrated speed, platform should have moved partway.
    check level.movingPlatforms[0].x > 0.0
    check level.movingPlatforms[0].x < 100.0

  test "moving platform ping-pongs at end":
    var mp = newMovingPlatform(0.0, 0.0, 100.0, 0.0, 80.0, 20.0, 1.0)
    mp.progress = 0.95
    mp.x = 95.0
    mp.prevX = 95.0
    var level = Level(platforms: @[], hazards: @[], exits: @[], buttons: @[], doors: @[],
                      movingPlatforms: @[mp])
    var chars: seq[Character] = @[]
    discard updatePhysics(chars, level, 0.1)
    # Should have reached end and reversed
    check level.movingPlatforms[0].forward == false

  test "moving platform ping-pongs at start":
    var mp = newMovingPlatform(0.0, 0.0, 100.0, 0.0, 80.0, 20.0, 1.0)
    mp.currentWaypoint = 1
    mp.progress = 0.95
    mp.forward = false
    mp.x = 5.0
    mp.prevX = 5.0
    var level = Level(platforms: @[], hazards: @[], exits: @[], buttons: @[], doors: @[],
                      movingPlatforms: @[mp])
    var chars: seq[Character] = @[]
    discard updatePhysics(chars, level, 0.1)
    # Should have reached start and reversed
    check level.movingPlatforms[0].forward == true

  test "character lands on moving platform":
    var mp = newMovingPlatform(100.0, 400.0, 100.0, 400.0, 200.0, 20.0, 0.0)
    var chars = @[newCharacter("pip")]
    chars[0].x = 150.0
    chars[0].y = 400.0 - float(chars[0].height) - 1.0
    chars[0].vy = 200.0
    var level = Level(platforms: @[], hazards: @[], exits: @[], buttons: @[], doors: @[],
                      movingPlatforms: @[mp])
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    check chars[0].grounded == true

  test "character rides moving platform horizontally":
    var mp = newMovingPlatform(100.0, 400.0, 300.0, 400.0, 200.0, 20.0, 1.0)
    var chars = @[newCharacter("pip")]
    chars[0].x = 150.0
    chars[0].y = 400.0 - float(chars[0].height)
    chars[0].grounded = true
    chars[0].vy = 0.0
    var level = Level(platforms: @[], hazards: @[], exits: @[], buttons: @[], doors: @[],
                      movingPlatforms: @[mp])
    let startX = chars[0].x
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    # Platform moved right, character should have moved with it
    check chars[0].x > startX

  test "multi-waypoint platform traverses segments":
    var mp = MovingPlatform(
      waypoints: @[(x: 0.0, y: 0.0), (x: 100.0, y: 0.0), (x: 100.0, y: 100.0)],
      width: 80.0, height: 20.0, speed: 200.0,
      pingPong: true, forward: true,
      x: 0.0, y: 0.0, prevX: 0.0, prevY: 0.0,
    )
    var level = Level(platforms: @[], hazards: @[], exits: @[], buttons: @[], doors: @[],
                      movingPlatforms: @[mp])
    var chars: seq[Character] = @[]
    # Advance through most of first segment.
    discard updatePhysics(chars, level, 0.4)
    check level.movingPlatforms[0].x > 0.0
    # Advance past first segment into second.
    for step in 0 ..< 10:
      discard updatePhysics(chars, level, 0.1)
    # Platform should have moved into the vertical segment.
    check level.movingPlatforms[0].y > 0.0

  test "jumping off moving platform stops rider displacement":
    var mp = newMovingPlatform(100.0, 400.0, 300.0, 400.0, 200.0, 20.0, 1.0)
    var chars = @[newCharacter("pip")]
    chars[0].x = 150.0
    chars[0].y = 400.0 - float(chars[0].height)
    chars[0].grounded = true
    chars[0].vy = 0.0
    chars[0].vx = 0.0
    var level = Level(platforms: @[], hazards: @[], exits: @[], buttons: @[], doors: @[],
                      movingPlatforms: @[mp])
    # First frame: establish riding.
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    check chars[0].grounded == true
    check chars[0].x > 150.0  # character moved with platform
    # Jump off the platform.
    applyJump(chars[0])
    check chars[0].grounded == false
    let jumpX = chars[0].x
    # Second frame: platform keeps moving but character should not follow.
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    let platformDx = level.movingPlatforms[0].x - level.movingPlatforms[0].prevX
    check platformDx > 0.0
    check abs(chars[0].x - jumpX) < 1.0

  test "platform reversal while riding follows new direction":
    var mp = newMovingPlatform(0.0, 400.0, 100.0, 400.0, 200.0, 20.0, 1.0)
    mp.progress = 0.9
    mp.x = 90.0
    mp.prevX = 90.0
    var chars = @[newCharacter("pip")]
    chars[0].x = 120.0
    chars[0].y = 400.0 - float(chars[0].height)
    chars[0].grounded = true
    chars[0].vy = 0.0
    chars[0].vx = 0.0
    var level = Level(platforms: @[], hazards: @[], exits: @[], buttons: @[], doors: @[],
                      movingPlatforms: @[mp])
    # Step until the platform reverses direction.
    var reversed = false
    var preReversalX = chars[0].x
    for step in 0 ..< 20:
      discard updatePhysics(chars, level, FIXED_TIMESTEP)
      if not level.movingPlatforms[0].forward:
        reversed = true
        preReversalX = chars[0].x
        break
    check reversed == true
    # After reversal the platform moves left; step a few more frames.
    for step in 0 ..< 5:
      discard updatePhysics(chars, level, FIXED_TIMESTEP)
    # Character should have followed the platform leftward.
    check chars[0].x < preReversalX

suite "dying character physics":
  test "dying character skips gravity":
    var chars = @[newCharacter("pip")]
    chars[0].x = 100.0
    chars[0].y = 100.0
    chars[0].deathTimer = 0.5
    let startVy = chars[0].vy
    var level = Level(platforms: @[], hazards: @[], exits: @[], buttons: @[], doors: @[])
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    check chars[0].vy == startVy  # vy unchanged, gravity not applied

  test "dying character is invulnerable to hazards":
    var chars = @[newCharacter("pip")]
    chars[0].x = 50.0
    chars[0].y = 50.0
    chars[0].deathTimer = 0.3
    let hazard = Hazard(x: 40.0, y: 40.0, width: 30.0, height: 30.0)
    var level = Level(platforms: @[], hazards: @[hazard], exits: @[], buttons: @[], doors: @[])
    let res = updatePhysics(chars, level, FIXED_TIMESTEP)
    check "pip" notin res.deadCharacters

suite "character-character collision":
  test "overlapping characters are pushed apart horizontally":
    var chars = @[newCharacter("pip"), newCharacter("luca")]
    # Place them overlapping horizontally (tall overlap, narrow horizontal overlap)
    chars[0].x = 100.0
    chars[0].y = 100.0
    chars[1].x = 110.0  # 14px overlap (pip is 24 wide)
    chars[1].y = 100.0
    var level = Level(platforms: @[], hazards: @[], exits: @[], buttons: @[], doors: @[])
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    # They should no longer intersect
    let a = toRect(chars[0])
    let b = toRect(chars[1])
    check not intersects(a, b)
    # Pip should be to the left of Luca
    check chars[0].x + float(chars[0].width) <= chars[1].x + 0.01

  test "character lands on top of another character":
    var chars = @[newCharacter("pip"), newCharacter("luca")]
    # Place Luca on a platform, Pip falling onto Luca
    chars[1].x = 100.0
    chars[1].y = 376.0  # luca (28px tall) sitting at y=376
    chars[1].grounded = true
    chars[1].vy = 0.0
    chars[0].x = 105.0
    chars[0].y = 376.0 - float(chars[0].height) + 2.0  # slightly overlapping from above
    chars[0].vy = 200.0  # falling
    let platform = Platform(x: 0.0, y: 404.0, width: 500.0, height: 20.0)
    var level = Level(platforms: @[platform], hazards: @[], exits: @[], buttons: @[], doors: @[])
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    # Pip should be grounded on top of Luca
    check chars[0].grounded == true
    # They should no longer overlap
    let a2 = toRect(chars[0])
    let b2 = toRect(chars[1])
    check not intersects(a2, b2)

  test "dying characters are skipped in collision":
    var chars = @[newCharacter("pip"), newCharacter("luca")]
    chars[0].x = 100.0
    chars[0].y = 100.0
    chars[0].deathTimer = 0.5  # dying
    chars[1].x = 110.0
    chars[1].y = 100.0
    let origX0 = chars[0].x
    var level = Level(platforms: @[], hazards: @[], exits: @[], buttons: @[], doors: @[])
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    # Dying character should not have been pushed (positions unchanged by collision)
    check chars[0].x == origX0

  test "respawning characters are skipped in collision":
    var chars = @[newCharacter("pip"), newCharacter("luca")]
    chars[0].x = 100.0
    chars[0].y = 100.0
    chars[0].respawnTimer = 0.3  # respawning
    chars[1].x = 110.0
    chars[1].y = 100.0
    let origX0 = chars[0].x
    var level = Level(platforms: @[], hazards: @[], exits: @[], buttons: @[], doors: @[])
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    check chars[0].x == origX0

suite "character stacking and riding":
  test "rider follows base character horizontally":
    var chars = @[newCharacter("pip"), newCharacter("bruno")]
    # Bruno on ground, Pip stacked on top.
    let platform = Platform(x: 0.0, y: 500.0, width: 1000.0, height: 20.0)
    chars[1].x = 200.0
    chars[1].y = 500.0 - float(chars[1].height)  # Bruno feet on platform
    chars[1].grounded = true
    chars[1].vy = 0.0
    chars[1].vx = 300.0  # pre-set velocity for clear displacement
    chars[0].x = 210.0
    chars[0].y = chars[1].y - float(chars[0].height)  # Pip on top of Bruno
    chars[0].grounded = true
    chars[0].vy = 0.0
    chars[0].vx = 0.0
    let pipStartX = chars[0].x
    let brunoStartX = chars[1].x
    var level = Level(platforms: @[platform], hazards: @[], exits: @[], buttons: @[], doors: @[])
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    let brunoDx = chars[1].x - brunoStartX
    let pipDx = chars[0].x - pipStartX
    check brunoDx > 1.0  # Bruno moved meaningfully
    check chars[0].ridingCharacterId == 1
    check abs(pipDx - brunoDx) < 0.05

  test "three-character stack moves together":
    var chars = @[newCharacter("pip"), newCharacter("luca"), newCharacter("bruno")]
    let platform = Platform(x: 0.0, y: 500.0, width: 1000.0, height: 20.0)
    # Bruno at bottom
    chars[2].x = 200.0
    chars[2].y = 500.0 - float(chars[2].height)
    chars[2].grounded = true
    chars[2].vy = 0.0
    chars[2].vx = 300.0
    # Luca on Bruno
    chars[1].x = 206.0
    chars[1].y = chars[2].y - float(chars[1].height)
    chars[1].grounded = true
    chars[1].vy = 0.0
    chars[1].vx = 0.0
    # Pip on Luca
    chars[0].x = 210.0
    chars[0].y = chars[1].y - float(chars[0].height)
    chars[0].grounded = true
    chars[0].vy = 0.0
    chars[0].vx = 0.0
    let brunoStartX = chars[2].x
    let lucaStartX = chars[1].x
    let pipStartX = chars[0].x
    var level = Level(platforms: @[platform], hazards: @[], exits: @[], buttons: @[], doors: @[])
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    let brunoDx = chars[2].x - brunoStartX
    let lucaDx = chars[1].x - lucaStartX
    let pipDx = chars[0].x - pipStartX
    check brunoDx > 1.0
    check abs(lucaDx - brunoDx) < 0.05
    check abs(pipDx - brunoDx) < 0.05

  test "jumping clears riding relationship":
    var chars = @[newCharacter("pip"), newCharacter("bruno")]
    let platform = Platform(x: 0.0, y: 500.0, width: 1000.0, height: 20.0)
    chars[1].x = 200.0
    chars[1].y = 500.0 - float(chars[1].height)
    chars[1].grounded = true
    chars[1].vy = 0.0
    chars[0].x = 210.0
    chars[0].y = chars[1].y - float(chars[0].height)
    chars[0].grounded = true
    chars[0].vy = 0.0
    var level = Level(platforms: @[platform], hazards: @[], exits: @[], buttons: @[], doors: @[])
    # First frame: establish riding
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    check chars[0].ridingCharacterId == 1
    # Now Pip jumps
    applyJump(chars[0])
    check chars[0].vy < 0.0
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    # After jumping, no longer riding
    check chars[0].ridingCharacterId == -1

  test "side-by-side characters do not ride":
    var chars = @[newCharacter("pip"), newCharacter("bruno")]
    let platform = Platform(x: 0.0, y: 500.0, width: 1000.0, height: 20.0)
    # Both on the ground, side by side
    chars[0].x = 100.0
    chars[0].y = 500.0 - float(chars[0].height)
    chars[0].grounded = true
    chars[0].vy = 0.0
    chars[1].x = 200.0
    chars[1].y = 500.0 - float(chars[1].height)
    chars[1].grounded = true
    chars[1].vy = 0.0
    var level = Level(platforms: @[platform], hazards: @[], exits: @[], buttons: @[], doors: @[])
    discard updatePhysics(chars, level, FIXED_TIMESTEP)
    check chars[0].ridingCharacterId == -1
    check chars[1].ridingCharacterId == -1
