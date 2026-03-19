## Game state machine, update logic, and level management

import constants
import entities/character
import entities/level
import systems/levels
import systems/physics
import systems/particles

type
  GameState* = enum
    menu, playing, paused, levelWin, credits

  Game* = object
    state*: GameState
    currentLevel*: int
    characters*: seq[Character]
    activeCharacterIndex*: int
    deltaTime*: float
    leftHeld*, rightHeld*: bool
    jumpPressed*: bool
    narrationText*: string
    narrationRevealed*: int
    narrationTimer*: float
    narrationActive*: bool
    levelWinTimer*: float
    particles*: ParticleSystem

const
  SCANCODE_RETURN* = 40.cint
  SCANCODE_ESCAPE* = 41.cint
  SCANCODE_R* = 21.cint

proc loadLevel*(game: var Game, idx: int) =
  if idx < 0 or idx >= allLevels.len:
    return
  game.currentLevel = idx
  let level = allLevels[idx]
  game.characters = @[]
  game.activeCharacterIndex = 0
  for i, charId in level.characters:
    var c = newCharacter(charId)
    # Spawn characters spread on the first platform
    c.x = 50.0 + float(i) * 60.0
    c.y = level.platforms[0].y - float(c.height) - 2.0
    c.spawnX = c.x
    c.spawnY = c.y
    game.characters.add(c)
  # Narration
  game.narrationText = level.narration
  game.narrationRevealed = 0
  game.narrationTimer = 0.0
  game.narrationActive = level.narration.len > 0
  game.levelWinTimer = 0.0

proc newGame*(): Game =
  result = Game(
    state: menu,
    currentLevel: 0,
    characters: @[],
    activeCharacterIndex: 0,
    deltaTime: 0.0,
    narrationText: "",
    narrationRevealed: 0,
    narrationActive: false,
  )

proc startGame*(game: var Game) =
  game.state = playing
  game.loadLevel(0)

proc restartLevel*(game: var Game) =
  game.loadLevel(game.currentLevel)

proc nextLevel*(game: var Game) =
  if game.currentLevel + 1 < allLevels.len:
    game.loadLevel(game.currentLevel + 1)
    game.state = playing
  else:
    game.state = credits

proc handleKey*(game: var Game, scancode: cint) =
  case game.state
  of menu:
    if scancode == SCANCODE_RETURN:
      game.startGame()
  of playing:
    if scancode == SCANCODE_ESCAPE:
      game.state = paused
    elif scancode == SCANCODE_R:
      game.restartLevel()
  of paused:
    if scancode == SCANCODE_ESCAPE:
      game.state = playing
  of levelWin:
    if scancode == SCANCODE_RETURN:
      game.nextLevel()
  of credits:
    if scancode == SCANCODE_RETURN:
      game.state = menu

proc update*(game: var Game, dt: float) =
  let scaledDt = dt * TIME_SCALE
  game.deltaTime = scaledDt

  case game.state
  of playing:
    # Apply movement to active character
    if game.activeCharacterIndex < game.characters.len:
      var speed = game.characters[game.activeCharacterIndex].moveSpeed()
      var vx = 0.0
      if game.leftHeld: vx -= speed
      if game.rightHeld: vx += speed
      game.characters[game.activeCharacterIndex].vx = vx
      if vx > 0: game.characters[game.activeCharacterIndex].facingRight = true
      elif vx < 0: game.characters[game.activeCharacterIndex].facingRight = false

    # Physics
    if game.currentLevel >= 0 and game.currentLevel < allLevels.len:
      let level = allLevels[game.currentLevel]

      # Capture grounded state before physics for landing detection
      var wasGrounded: seq[bool] = @[]
      for c in game.characters:
        wasGrounded.add(c.grounded)

      let result = updatePhysics(game.characters, level, scaledDt)

      # Handle deaths — respawn at spawn point
      for deadId in result.deadCharacters:
        for i in 0..<game.characters.len:
          if game.characters[i].id == deadId:
            game.characters[i].x = game.characters[i].spawnX
            game.characters[i].y = game.characters[i].spawnY
            game.characters[i].vx = 0
            game.characters[i].vy = 0
            game.characters[i].dead = false

      # Mark exits
      for i in 0..<game.characters.len:
        game.characters[i].atExit = game.characters[i].id in result.exitedCharacters

      # Particle effects
      let dustColor: Color = (r: 160'u8, g: 160'u8, b: 170'u8)
      for i in 0..<game.characters.len:
        let c = game.characters[i]
        # Landing dust: transition from airborne to grounded
        if i < wasGrounded.len and not wasGrounded[i] and c.grounded:
          let footX = c.x + float(c.width) * 0.5
          let footY = c.y + float(c.height)
          emit(game.particles, footX, footY, 6, dustColor, 20.0, 55.0)
        # Exit sparkles: one particle per frame while at exit
        if c.atExit:
          let exitColor = CHAR_COLORS[c.colorIndex mod 6]
          let centerX = c.x + float(c.width) * 0.5
          let centerY = c.y + float(c.height) * 0.5
          emit(game.particles, centerX, centerY, 1, exitColor, 24.0, 40.0)

      # Check win — all characters at their exits
      if game.characters.len > 0:
        var allAtExit = true
        for c in game.characters:
          if not c.atExit:
            allAtExit = false
            break
        if allAtExit:
          game.state = levelWin
          game.levelWinTimer = 0.0

    # Update particles
    update(game.particles, scaledDt)

    # Narration typewriter
    if game.narrationActive:
      game.narrationTimer += scaledDt
      if game.narrationTimer >= 0.04:
        game.narrationTimer -= 0.04
        if game.narrationRevealed < game.narrationText.len:
          game.narrationRevealed += 1
        else:
          game.narrationActive = false

  of levelWin:
    game.levelWinTimer += scaledDt

  else:
    discard
