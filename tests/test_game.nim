import unittest
import windy
import "../src/game"
import "../src/constants"
import "../src/entities/character"
import "../src/entities/level"
import "../src/systems/particles"

proc skipActTitle(game: var Game) =
  ## Advance past any act title card into the playing state.
  if game.state == actTitle:
    let scaledStep = FIXED_TIMESTEP * TIME_SCALE
    let steps = int(ActTitleDuration / scaledStep) + 2
    for _ in 0 ..< steps:
      game.update(FIXED_TIMESTEP)

suite "game state machine":
  test "game starts in menu state":
    let g = newGame()
    check g.state == menu

  test "enter transitions menu to actTitle then playing":
    var g = newGame()
    g.handleKey(KeyEnter)
    check g.state == actTitle
    g.skipActTitle()
    check g.state == playing
    check g.characters.len > 0

  test "escape transitions playing to paused":
    var g = newGame()
    g.handleKey(KeyEnter)
    g.skipActTitle()
    g.handleKey(KeyEscape)
    check g.state == paused

  test "escape transitions paused to playing":
    var g = newGame()
    g.handleKey(KeyEnter)
    g.skipActTitle()
    g.handleKey(KeyEscape)
    g.handleKey(KeyEscape)
    check g.state == playing

  test "escape in menu does nothing":
    var g = newGame()
    g.handleKey(KeyEscape)
    check g.state == menu

  test "startGame loads level 0 with pip":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
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
    g.skipActTitle()
    g.characters[0].grounded = true

    g.pressJump()

    check g.particles.particles.len > 0
    check g.camera.impulseY < 0.0

  test "character switching boosts camera response":
    var g = newGame()
    g.state = playing
    g.currentLevel = 0
    g.currentLevelState = Level(
      platforms: @[Platform(x: 0.0, y: 200.0, width: 500.0, height: 20.0)],
      hazards: @[],
      exits: @[],
      buttons: @[],
      doors: @[],
      movingPlatforms: @[],
      levelWidth: 1200.0,
      levelHeight: 500.0,
    )
    g.characters = @[newCharacter("pip"), newCharacter("luca")]
    g.characters[0].x = 80.0
    g.characters[0].y = 170.0
    g.characters[1].x = 260.0
    g.characters[1].y = 170.0
    g.activeCharacterIndex = 0

    let changed = g.selectActiveCharacter(1)

    check changed == true
    check g.activeCharacterIndex == 1
    check g.camera.responseBoost > 0.0

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
    check g.camera.impulseY > 0.0

  test "death spawns particles":
    var g = newGame()
    g.state = playing
    g.currentLevel = 0
    g.currentLevelState = Level(
      platforms: @[],
      hazards: @[Hazard(x: 880.0, y: 0.0, width: 100.0, height: 100.0)],
      exits: @[],
      buttons: @[],
      doors: @[],
      movingPlatforms: @[],
      levelWidth: 1600.0,
      levelHeight: 500.0,
    )
    g.characters = @[newCharacter("luca")]
    g.activeCharacterIndex = 0
    g.characters[0].x = 900.0
    g.characters[0].y = 20.0
    g.characters[0].spawnX = 20.0
    g.characters[0].spawnY = 20.0
    g.camera.x = 400.0

    g.update(FIXED_TIMESTEP)

    # After one frame: dissolve phase starts, particles emitted
    check g.particles.particles.len > 0
    check g.characters[0].dissolving == true

    # Advance through dissolve phase (0.4s) and into respawn
    for _ in 0..30:
      g.update(FIXED_TIMESTEP)

    # After dissolve completes, character moves to spawn and respawn phase begins
    check g.characters[0].x == g.characters[0].spawnX
    check g.characters[0].y == g.characters[0].spawnY

    # Advance through respawn phase (0.3s)
    for _ in 0..25:
      g.update(FIXED_TIMESTEP)
    check g.characters[0].respawning == false

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
    check g.camera.holdTimer > 0.0

suite "act title cards":
  test "startGame shows act title for level 0":
    var g = newGame()
    g.startGame()
    check g.state == actTitle
    check g.actTitleTarget == 0

  test "act title transitions to playing after duration":
    var g = newGame()
    g.startGame()
    check g.state == actTitle

    g.skipActTitle()

    check g.state == playing
    check g.characters.len > 0

  test "actForLevel maps levels to correct acts":
    check actForLevel(0) == 0   # Level 1 -> Act 1
    check actForLevel(5) == 0   # Level 6 -> Act 1
    check actForLevel(6) == 1   # Level 7 -> Act 2
    check actForLevel(11) == 1  # Level 12 -> Act 2

  test "isFirstLevelOfAct identifies act boundaries":
    check isFirstLevelOfAct(0) == true    # Level 1
    check isFirstLevelOfAct(1) == false   # Level 2
    check isFirstLevelOfAct(6) == true    # Level 7

  test "nextLevel shows act title at act boundary":
    var g = newGame()
    g.state = playing
    g.currentLevel = 5  # Level 6, last of Act 1
    g.nextLevel()
    check g.state == actTitle
    check g.actTitleTarget == 6  # Level 7, first of Act 2

  test "nextLevel skips title for mid-act levels":
    var g = newGame()
    g.state = playing
    g.currentLevel = 0  # Level 1
    g.nextLevel()
    check g.state == playing
    check g.currentLevel == 1

  test "act title alpha fades in and out":
    var g = newGame()
    g.state = actTitle
    g.actTitleTimer = 0.0
    check g.actTitleAlpha() == 0.0

    g.actTitleTimer = ActTitleFadeIn * 0.5
    check g.actTitleAlpha() > 0.4
    check g.actTitleAlpha() < 0.6

    g.actTitleTimer = ActTitleFadeIn + 0.5
    check g.actTitleAlpha() == 1.0

    g.actTitleTimer = ActTitleFadeIn + ActTitleHold + ActTitleFadeOut
    check g.actTitleAlpha() == 0.0

  test "act definitions cover correct ranges":
    check Acts[0].number == 1
    check Acts[0].name == "Awakening"
    check Acts[0].startLevel == 1
    check Acts[0].endLevel == 6
    check Acts[4].number == 5
    check Acts[4].name == "Transcendence"
    check Acts[4].startLevel == 25
    check Acts[4].endLevel == 30
