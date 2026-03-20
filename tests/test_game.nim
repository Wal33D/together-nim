import unittest
import "../src/game"
import "../src/constants"
import "../src/entities/character"
import "../src/entities/level"
import "../src/systems/particles"

suite "game state machine":
  test "game starts in menu state":
    let g = newGame()
    check g.state == menu

  test "enter transitions menu to playing and loads level":
    var g = newGame()
    g.handleKey(SCANCODE_RETURN)
    check g.state == playing
    check g.characters.len > 0

  test "escape transitions playing to paused":
    var g = newGame()
    g.handleKey(SCANCODE_RETURN)
    g.handleKey(SCANCODE_ESCAPE)
    check g.state == paused

  test "escape transitions paused to playing":
    var g = newGame()
    g.handleKey(SCANCODE_RETURN)
    g.handleKey(SCANCODE_ESCAPE)
    g.handleKey(SCANCODE_ESCAPE)
    check g.state == playing

  test "escape in menu does nothing":
    var g = newGame()
    g.handleKey(SCANCODE_ESCAPE)
    check g.state == menu

  test "startGame loads level 0 with pip":
    var g = newGame()
    g.startGame()
    check g.characters.len == 1
    check g.characters[0].id == "pip"

  test "pressJump allows coyote jump for standard characters":
    var g = newGame()
    g.state = playing
    g.currentLevel = 0
    g.characters = @[newCharacter("luca")]
    g.activeCharacterIndex = 0
    g.characters[0].grounded = false
    g.characters[0].coyoteTimer = COYOTE_TIME * 0.5

    g.pressJump()

    check g.characters[0].vy < 0.0
    check g.characters[0].jumpCount == 1

  test "buffered jump fires as soon as the character lands":
    var g = newGame()
    g.state = playing
    g.currentLevel = 0
    g.currentLevelState = Level(
      platforms: @[Platform(x: 0.0, y: 200.0, width: 400.0, height: 20.0)],
      hazards: @[],
      exits: @[],
      buttons: @[],
      doors: @[],
      movingPlatforms: @[],
      levelWidth: 800.0,
      levelHeight: 500.0,
    )
    g.characters = @[newCharacter("luca")]
    g.activeCharacterIndex = 0
    g.characters[0].x = 100.0
    g.characters[0].y = 171.0
    g.characters[0].vy = 200.0
    g.characters[0].grounded = false
    g.characters[0].coyoteTimer = COYOTE_TIME + 0.05

    g.pressJump()
    check g.characters[0].jumpBufferTimer > 0.0

    g.update(FIXED_TIMESTEP)

    check g.characters[0].vy < 0.0
    check g.characters[0].grounded == false

  test "jump spawns particles":
    var g = newGame()
    g.startGame()
    g.characters[0].grounded = true

    g.pressJump()

    check g.particles.particles.len > 0

  test "landing spawns particles":
    var g = newGame()
    g.state = playing
    g.currentLevel = 0
    g.currentLevelState = Level(
      platforms: @[Platform(x: 0.0, y: 200.0, width: 400.0, height: 20.0)],
      hazards: @[],
      exits: @[],
      buttons: @[],
      doors: @[],
      movingPlatforms: @[],
      levelWidth: 800.0,
      levelHeight: 500.0,
    )
    g.characters = @[newCharacter("luca")]
    g.activeCharacterIndex = 0
    g.characters[0].x = 100.0
    g.characters[0].y = 171.0
    g.characters[0].vy = 200.0
    g.characters[0].grounded = false
    g.characters[0].coyoteTimer = COYOTE_TIME + 0.05

    g.update(FIXED_TIMESTEP)

    check g.particles.particles.len > 0

  test "death spawns particles":
    var g = newGame()
    g.state = playing
    g.currentLevel = 0
    g.currentLevelState = Level(
      platforms: @[],
      hazards: @[Hazard(x: 0.0, y: 0.0, width: 100.0, height: 100.0)],
      exits: @[],
      buttons: @[],
      doors: @[],
      movingPlatforms: @[],
      levelWidth: 800.0,
      levelHeight: 500.0,
    )
    g.characters = @[newCharacter("luca")]
    g.activeCharacterIndex = 0
    g.characters[0].x = 20.0
    g.characters[0].y = 20.0
    g.characters[0].spawnX = 20.0
    g.characters[0].spawnY = 20.0

    g.update(FIXED_TIMESTEP)

    check g.particles.particles.len > 0
    check g.characters[0].x == g.characters[0].spawnX
    check g.characters[0].y == g.characters[0].spawnY

  test "exit reach spawns particles":
    var g = newGame()
    g.state = playing
    g.currentLevel = 0
    g.currentLevelState = Level(
      platforms: @[],
      hazards: @[],
      exits: @[Exit(x: 10.0, y: 10.0, width: 30.0, height: 40.0, characterId: "luca")],
      buttons: @[],
      doors: @[],
      movingPlatforms: @[],
      levelWidth: 800.0,
      levelHeight: 500.0,
    )
    g.characters = @[newCharacter("luca")]
    g.activeCharacterIndex = 0
    g.characters[0].x = 15.0
    g.characters[0].y = 15.0

    g.update(FIXED_TIMESTEP)

    check g.characters[0].atExit == true
    check g.particles.particles.len > 0

  test "level completion spawns particles":
    var g = newGame()
    g.state = playing
    g.currentLevel = 0
    g.currentLevelState = Level(
      platforms: @[],
      hazards: @[],
      exits: @[Exit(x: 10.0, y: 10.0, width: 30.0, height: 40.0, characterId: "luca")],
      buttons: @[],
      doors: @[],
      movingPlatforms: @[],
      levelWidth: 800.0,
      levelHeight: 500.0,
    )
    g.characters = @[newCharacter("luca")]
    g.activeCharacterIndex = 0
    g.characters[0].x = 15.0
    g.characters[0].y = 15.0

    g.update(FIXED_TIMESTEP)

    check g.state == levelWin
    check g.particles.particles.len > 0
