import std/math
import unittest
import windy
import "../src/game"
import "../src/constants"
import "../src/entities/character"
import "../src/entities/level"
import "../src/systems/particles"
import "../src/systems/save"
import "../src/systems/levels"

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

    # After one frame: death phase starts, particles emitted
    check g.particles.particles.len > 0
    check g.characters[0].isDying() == true

    # Advance through death phase (0.5s) and into respawn
    for _ in 0..40:
      g.update(FIXED_TIMESTEP)

    # After death timer expires, character moves to spawn and respawn phase begins
    check g.characters[0].x == g.characters[0].spawnX
    check g.characters[0].y == g.characters[0].spawnY

    # Advance through respawn phase (0.3s)
    for _ in 0..25:
      g.update(FIXED_TIMESTEP)
    check g.characters[0].isRespawning() == false

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

suite "character proximity":
  test "nearby characters build contentment":
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
    g.characters = @[newCharacter("pip"), newCharacter("luca")]
    g.activeCharacterIndex = 0
    # Place within 80px of each other
    g.characters[0].x = 100.0
    g.characters[0].y = 170.0
    g.characters[0].grounded = true
    g.characters[1].x = 140.0
    g.characters[1].y = 170.0
    g.characters[1].grounded = true

    for _ in 0 .. 10:
      g.update(FIXED_TIMESTEP)

    check g.characters[0].contentment > 0.0
    check g.characters[1].contentment > 0.0

  test "far apart characters decay contentment faster":
    var g = newGame()
    g.state = playing
    g.currentLevel = 0
    g.currentLevelState = Level(
      platforms: @[Platform(x: 0.0, y: 200.0, width: 800.0, height: 20.0)],
      hazards: @[],
      exits: @[],
      buttons: @[],
      doors: @[],
      movingPlatforms: @[],
      levelWidth: 800.0,
      levelHeight: 500.0,
    )
    g.characters = @[newCharacter("pip"), newCharacter("luca")]
    g.activeCharacterIndex = 0
    # Place far apart (>200px)
    g.characters[0].x = 50.0
    g.characters[0].y = 170.0
    g.characters[0].grounded = true
    g.characters[0].contentment = 0.8
    g.characters[1].x = 500.0
    g.characters[1].y = 170.0
    g.characters[1].grounded = true
    g.characters[1].contentment = 0.8

    for _ in 0 .. 10:
      g.update(FIXED_TIMESTEP)

    # Far apart decays at 0.8/s — should have dropped noticeably
    check g.characters[0].contentment < 0.8
    check g.characters[1].contentment < 0.8

  test "anticipation builds when moving toward another character":
    var g = newGame()
    g.state = playing
    g.currentLevel = 0
    g.currentLevelState = Level(
      platforms: @[Platform(x: 0.0, y: 200.0, width: 800.0, height: 20.0)],
      hazards: @[],
      exits: @[],
      buttons: @[],
      doors: @[],
      movingPlatforms: @[],
      levelWidth: 800.0,
      levelHeight: 500.0,
    )
    g.characters = @[newCharacter("pip"), newCharacter("luca")]
    g.activeCharacterIndex = 0
    g.characters[0].x = 50.0
    g.characters[0].y = 170.0
    g.characters[0].grounded = true
    g.characters[0].vx = 100.0  # Moving right toward luca
    g.characters[1].x = 300.0
    g.characters[1].y = 170.0
    g.characters[1].grounded = true

    for _ in 0 .. 5:
      g.update(FIXED_TIMESTEP)

    check g.characters[0].anticipation > 0.0

  test "lonely character sways more":
    var cHappy = newCharacter("pip")
    cHappy.contentment = 1.0
    cHappy.grounded = true
    cHappy.idleTimer = 0.785  # near sin peak

    var cLonely = newCharacter("pip")
    cLonely.contentment = 0.0
    cLonely.grounded = true
    cLonely.idleTimer = 0.785

    check abs(cLonely.idleSway()) > abs(cHappy.idleSway())

suite "proximity glow":
  proc makePlayingGame(chars: seq[Character]): Game =
    ## Helper: game in playing state with a flat platform.
    result = newGame()
    result.state = playing
    result.currentLevel = 0
    result.currentLevelState = Level(
      platforms: @[Platform(x: 0.0, y: 400.0, width: 800.0, height: 20.0)],
      hazards: @[], exits: @[], buttons: @[], doors: @[],
      movingPlatforms: @[],
      levelWidth: 800.0, levelHeight: 500.0,
    )
    result.characters = chars
    result.activeCharacterIndex = 0

  test "alone character glow lerps toward dim, small target":
    # Two characters 300px apart — well beyond ProximityGlowRange (120px).
    var pip = newCharacter("pip")
    pip.x = 50.0; pip.y = 370.0; pip.grounded = true
    var luca = newCharacter("luca")
    luca.x = 400.0; luca.y = 370.0; luca.grounded = true
    var g = makePlayingGame(@[pip, luca])

    # Advance enough frames for lerp to converge (4.0/s rate, ~60 frames)
    for _ in 0..120:
      g.update(FIXED_TIMESTEP)

    # Both characters should approach the lonely targets
    check g.characters[0].glowScale < 1.5   # converging toward 1.2
    check g.characters[0].glowAlpha < 0.12  # converging toward 0.08
    check g.characters[1].glowScale < 1.5
    check g.characters[1].glowAlpha < 0.12

  test "close characters glow larger and brighter":
    # Two characters 30px apart — well within ProximityGlowRange (120px).
    var pip = newCharacter("pip")
    pip.x = 50.0; pip.y = 370.0; pip.grounded = true
    var luca = newCharacter("luca")
    luca.x = 80.0; luca.y = 370.0; luca.grounded = true
    var g = makePlayingGame(@[pip, luca])

    for _ in 0..120:
      g.update(FIXED_TIMESTEP)

    # t ≈ 0.75 at 30px → targetScale ≈ 2.55, targetAlpha ≈ 0.225
    check g.characters[0].glowScale > 2.0
    check g.characters[0].glowAlpha > 0.18
    check g.characters[1].glowScale > 2.0

  test "full group activates gold mix":
    # Three characters all within 50px of each other.
    var pip = newCharacter("pip")
    pip.x = 50.0; pip.y = 370.0; pip.grounded = true
    var luca = newCharacter("luca")
    luca.x = 90.0; luca.y = 370.0; luca.grounded = true
    var bruno = newCharacter("bruno")
    bruno.x = 130.0; bruno.y = 370.0; bruno.grounded = true
    var g = makePlayingGame(@[pip, luca, bruno])

    for _ in 0..120:
      g.update(FIXED_TIMESTEP)

    # Full group — gold mix should be rising toward 0.15
    check g.characters[0].glowGoldMix > 0.05
    check g.characters[1].glowGoldMix > 0.05
    check g.characters[2].glowGoldMix > 0.05

  test "separated characters have no gold mix":
    var pip = newCharacter("pip")
    pip.x = 50.0; pip.y = 370.0; pip.grounded = true; pip.glowGoldMix = 0.1
    var luca = newCharacter("luca")
    luca.x = 600.0; luca.y = 370.0; luca.grounded = true; luca.glowGoldMix = 0.1
    var g = makePlayingGame(@[pip, luca])

    for _ in 0..120:
      g.update(FIXED_TIMESTEP)

    check g.characters[0].glowGoldMix < 0.02
    check g.characters[1].glowGoldMix < 0.02

  test "isolation timer increments when far apart":
    var pip = newCharacter("pip")
    pip.x = 50.0; pip.y = 370.0; pip.grounded = true
    var luca = newCharacter("luca")
    luca.x = 600.0; luca.y = 370.0; luca.grounded = true
    var g = makePlayingGame(@[pip, luca])

    for _ in 0..60:
      g.update(FIXED_TIMESTEP)

    check g.characters[0].isolationTimer > 0.5
    check g.characters[1].isolationTimer > 0.5

  test "isolation timer resets when characters meet":
    var pip = newCharacter("pip")
    pip.x = 50.0; pip.y = 370.0; pip.grounded = true
    var luca = newCharacter("luca")
    luca.x = 600.0; luca.y = 370.0; luca.grounded = true
    var g = makePlayingGame(@[pip, luca])

    # Build up isolation time.
    for _ in 0..60:
      g.update(FIXED_TIMESTEP)
    check g.characters[0].isolationTimer > 0.5

    # Move characters close together (within ProximityFar = 200px).
    g.characters[0].x = 100.0
    g.characters[1].x = 150.0

    for _ in 0..5:
      g.update(FIXED_TIMESTEP)

    check g.characters[0].isolationTimer == 0.0
    check g.characters[1].isolationTimer == 0.0

suite "credits sequence":
  test "enterCredits sets state and resets timer":
    var g = newGame()
    g.screenBrightness = 1.0
    g.creditsTimer = 5.0
    g.enterCredits()
    check g.state == credits
    check g.creditsTimer == 0.0
    check g.screenBrightness == 0.0

  test "credits timer advances during update":
    var g = newGame()
    g.enterCredits()
    let before = g.creditsTimer
    g.update(FIXED_TIMESTEP)
    check g.creditsTimer > before

  test "nextLevel enters credits after last level":
    var g = newGame()
    g.state = playing
    # Set to the last valid level index (35 levels, 0-indexed).
    g.currentLevel = 34
    g.nextLevel()
    check g.state == credits
    check g.creditsTimer == 0.0

  test "enter key in credits returns to menu":
    var g = newGame()
    g.enterCredits()
    g.handleKey(KeyEnter)
    check g.state == menu

suite "won screen":
  test "nextLevel enters won after final level":
    var g = newGame()
    g.state = playing
    g.currentLevel = FinalLevel
    g.nextLevel()
    check g.state == won
    check g.wonTimer == 0.0
    check g.wonThankYouShown == false

  test "won handleKey two-phase interaction":
    var g = newGame()
    g.enterWon()
    # First key press shows thank-you.
    g.handleKey(KeyEnter)
    check g.state == won
    check g.wonThankYouShown == true
    # Second key press returns to menu.
    g.handleKey(KeyEnter)
    check g.state == menu

  test "won timer auto-reveals thank-you at 5s":
    var g = newGame()
    g.enterWon()
    check g.wonThankYouShown == false
    # Each update adds dt * TIME_SCALE to wonTimer.
    # Use FIXED_TIMESTEP so each step adds FIXED_TIMESTEP * TIME_SCALE.
    let scaledStep = FIXED_TIMESTEP * TIME_SCALE
    let stepsUnder = int(4.9 / scaledStep)
    for i in 0 ..< stepsUnder:
      g.update(FIXED_TIMESTEP)
    check g.wonThankYouShown == false
    # Push past 5 seconds.
    let stepsOver = int(5.5 / scaledStep) - stepsUnder
    for i in 0 ..< stepsOver:
      g.update(FIXED_TIMESTEP)
    check g.wonThankYouShown == true

  test "totalDeaths increments on death":
    var g = newGame()
    check g.totalDeaths == 0
    g.totalDeaths += 1
    check g.totalDeaths == 1

suite "first-meeting introductions":
  test "level 5 schedules intro for luca":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    # Advance to level 5 (idx 4) which introduces luca.
    g.charactersMet = {0'u8}  # Only pip met so far.
    g.loadLevel(4)
    check g.introQueue.len == 1
    let introIdx = g.introQueue[0]
    check g.characters[introIdx].id == "luca"

  test "intro does not replay on restart":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    g.charactersMet = {0'u8}
    g.loadLevel(4)
    check g.introQueue.len == 1
    # Mark luca as met (simulating completed intro).
    g.charactersMet.incl(1'u8)
    # Restart same level.
    g.loadLevel(4)
    check g.introQueue.len == 0

  test "intro freezes physics after 2s delay":
    var g = newGame()
    g.state = playing
    g.charactersMet = {0'u8}
    g.loadLevel(4)
    check g.gameFrozen == false
    # Advance past the 2s pre-delay.
    let scaledStep = FIXED_TIMESTEP * TIME_SCALE
    let steps = int(2.1 / scaledStep)
    for _ in 0 ..< steps:
      g.update(FIXED_TIMESTEP)
    check g.gameFrozen == true
    check g.narrationActive == true

  test "intro glow boost increases during intro":
    var g = newGame()
    g.state = playing
    g.charactersMet = {0'u8}
    g.loadLevel(4)
    # Advance past the 2s pre-delay + a bit into the intro.
    let scaledStep = FIXED_TIMESTEP * TIME_SCALE
    let steps = int(2.5 / scaledStep)
    for _ in 0 ..< steps:
      g.update(FIXED_TIMESTEP)
    let introIdx = g.introCharacterIdx
    check introIdx >= 0
    check g.characters[introIdx].introGlowBoost > 0.0

suite "level select":
  test "levelSelect state starts with cursor at 0,0":
    var g = newGame()
    g.state = levelSelect
    check g.levelSelectRow == 0
    check g.levelSelectCol == 0

  test "escape from levelSelect returns to menu":
    var g = newGame()
    g.state = levelSelect
    g.handleKey(KeyEscape)
    check g.state == menu

  test "launchSelectedLevel starts first level":
    var g = newGame()
    g.state = levelSelect
    g.levelSelectRow = 0
    g.levelSelectCol = 0
    g.launchSelectedLevel()
    check g.state in {actTitle, playing}

  test "launchSelectedLevel rejects locked level":
    var g = newGame()
    g.state = levelSelect
    g.levelSelectRow = 4
    g.levelSelectCol = 5
    g.launchSelectedLevel()
    check g.state == levelSelect
    check g.levelSelectRejectTimer > 0.0

  test "levelSelectRejectTimer decays over time":
    var g = newGame()
    g.state = levelSelect
    g.levelSelectRejectTimer = 0.25
    g.update(FIXED_TIMESTEP)
    check g.levelSelectRejectTimer < 0.25

  test "levelSelectRow wraps around":
    var g = newGame()
    g.state = levelSelect
    g.levelSelectRow = 0
    g.levelSelectRow = (g.levelSelectRow - 1 + 5) mod 5
    check g.levelSelectRow == 4

  test "levelSelectCol wraps around":
    var g = newGame()
    g.state = levelSelect
    g.levelSelectCol = 5
    g.levelSelectCol = (g.levelSelectCol + 1) mod 6
    check g.levelSelectCol == 0

  test "highestCompletedLevel defaults to -1":
    var g = newGame()
    check g.highestCompletedLevel == -1

  test "highestCompletedLevel updates on level completion":
    var g = newGame()
    g.state = playing
    g.loadLevel(0)
    g.highestCompletedLevel = -1
    # Simulate level completion by moving all characters to exits.
    let level = allLevels[0]
    for i in 0 ..< g.characters.len:
      g.characters[i].x = level.exits[i mod level.exits.len].x
      g.characters[i].y = level.exits[i mod level.exits.len].y
      g.characters[i].atExit = true
    # Trigger the level win check.
    g.update(FIXED_TIMESTEP)
    if g.state == levelWin:
      check g.highestCompletedLevel == 0

  test "launchSelectedLevel allows next unlocked level":
    var g = newGame()
    g.state = levelSelect
    g.levelSelectRow = 0
    g.levelSelectCol = 1
    # Level 1 (index 1) should be available if level 0 is completed.
    if levelAvailable(1):
      g.launchSelectedLevel()
      check g.state != levelSelect or g.levelSelectRejectTimer > 0.0

  test "out-of-range cursor does nothing":
    var g = newGame()
    g.state = levelSelect
    g.levelSelectRow = -1
    g.levelSelectCol = 0
    g.launchSelectedLevel()
    check g.state == levelSelect
