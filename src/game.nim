## Game state machine, update logic, and level management

import constants
import entities/character
import entities/level
import systems/levels
import systems/physics
import systems/camera
import systems/atmosphere
import systems/audio

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
    camera*: Camera
    atmosphere*: Atmosphere
    currentLevelState*: Level
    menuTime*: float
    elapsedTime*: float
    menuAtmosphere*: Atmosphere

const
  SCANCODE_RETURN* = 40.cint
  SCANCODE_ESCAPE* = 41.cint
  SCANCODE_R* = 21.cint

proc jumpGraceWindow(c: Character): float =
  if c.ability == coyoteTime:
    FELIX_COYOTE_TIME
  else:
    COYOTE_TIME

proc attemptCharacterJump(c: var Character): bool =
  let graceWindow = jumpGraceWindow(c)

  case c.ability
  of doubleJump:
    if c.grounded or c.coyoteTimer < graceWindow or c.jumpCount < 2:
      c.vy = c.jumpForce()
      c.grounded = false
      if c.jumpCount < 1:
        c.jumpCount = 1
      else:
        inc c.jumpCount
      c.coyoteTimer = graceWindow + 1.0
      c.jumpBufferTimer = 0.0
      c.triggerJump()
      return true
  of wallJump:
    if c.grounded or c.coyoteTimer < graceWindow:
      c.vy = c.jumpForce()
      c.grounded = false
      c.jumpCount = 1
      c.coyoteTimer = graceWindow + 1.0
      c.jumpBufferTimer = 0.0
      c.triggerJump()
      return true
    if c.wallTouching:
      c.vy = c.jumpForce()
      c.vx = float(c.wallTouchDir) * c.moveSpeed()
      c.grounded = false
      c.wallTouching = false
      c.jumpCount = 1
      c.jumpBufferTimer = 0.0
      c.triggerJump()
      return true
  else:
    if c.grounded or c.coyoteTimer < graceWindow:
      c.vy = c.jumpForce()
      c.grounded = false
      c.jumpCount = 1
      c.coyoteTimer = graceWindow + 1.0
      c.jumpBufferTimer = 0.0
      c.triggerJump()
      return true

  false

proc pressJump*(game: var Game) =
  game.jumpPressed = true

  if game.state != playing:
    return

  if game.activeCharacterIndex < game.characters.len:
    if attemptCharacterJump(game.characters[game.activeCharacterIndex]):
      playSound(soundJump)
    else:
      game.characters[game.activeCharacterIndex].jumpBufferTimer = JUMP_BUFFER_TIME

  if game.narrationActive:
    game.narrationRevealed = game.narrationText.len
    game.narrationActive = false

proc releaseJump*(game: var Game) =
  game.jumpPressed = false

  if game.state != playing:
    return

  if game.activeCharacterIndex < game.characters.len and
     game.characters[game.activeCharacterIndex].vy < 0.0:
    game.characters[game.activeCharacterIndex].vy *= JUMP_CUT_FACTOR

proc selectActiveCharacter*(game: var Game, idx: int): bool =
  if idx < 0 or idx >= game.characters.len or idx == game.activeCharacterIndex:
    return false

  if game.activeCharacterIndex >= 0 and game.activeCharacterIndex < game.characters.len:
    game.characters[game.activeCharacterIndex].jumpBufferTimer = 0.0

  game.activeCharacterIndex = idx
  true

proc cycleActiveCharacter*(game: var Game, delta: int): bool =
  if game.characters.len <= 1:
    return false

  var currentIdx = game.activeCharacterIndex
  if currentIdx < 0 or currentIdx >= game.characters.len:
    currentIdx = 0

  let newIdx = (currentIdx + delta + game.characters.len) mod game.characters.len
  if newIdx == currentIdx:
    return false

  game.characters[currentIdx].jumpBufferTimer = 0.0
  game.activeCharacterIndex = newIdx
  true

proc loadLevel*(game: var Game, idx: int) =
  if idx < 0 or idx >= allLevels.len:
    return
  game.currentLevel = idx
  let level = allLevels[idx]
  game.currentLevelState = level
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
  # Atmosphere — use colors from this level's characters
  var atmColors: seq[Color] = @[]
  for c in game.characters:
    atmColors.add(CHAR_COLORS[c.colorIndex mod 6])
  game.atmosphere = newAtmosphere(atmColors)

  # Narration
  game.narrationText = level.narration
  game.narrationRevealed = 0
  game.narrationTimer = 0.0
  game.narrationActive = level.narration.len > 0
  game.levelWinTimer = 0.0
  game.jumpPressed = false
  # Snap camera to active character immediately
  if game.characters.len > 0:
    let ch = game.characters[0]
    snapCamera(game.camera, ch.x, ch.y, float(ch.width), float(ch.height),
               level.levelWidth, level.levelHeight)

proc newGame*(): Game =
  let allColors = @[PIP_COLOR, LUCA_COLOR, BRUNO_COLOR, CARA_COLOR, FELIX_COLOR, IVY_COLOR]
  result = Game(
    state: menu,
    currentLevel: 0,
    characters: @[],
    activeCharacterIndex: 0,
    deltaTime: 0.0,
    narrationText: "",
    narrationRevealed: 0,
    narrationActive: false,
    camera: newCamera(),
    atmosphere: newAtmosphere(@[]),
    menuTime: 0.0,
    elapsedTime: 0.0,
    menuAtmosphere: newAtmosphere(allColors),
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
  game.elapsedTime += scaledDt

  case game.state
  of menu:
    game.menuTime += scaledDt
    game.menuAtmosphere.update(scaledDt)
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
      let result = updatePhysics(game.characters, game.currentLevelState, scaledDt)
      let level = game.currentLevelState

      # Handle deaths — respawn at spawn point
      for deadId in result.deadCharacters:
        for i in 0..<game.characters.len:
          if game.characters[i].id == deadId:
            game.characters[i].x = game.characters[i].spawnX
            game.characters[i].y = game.characters[i].spawnY
            game.characters[i].vx = 0
            game.characters[i].vy = 0
            game.characters[i].dead = false
            playSound(soundDeath)

      # Landing sound
      if result.landedCharacters.len > 0:
        playSound(soundLand)

      # Mark exits — play chime when a character newly reaches their exit
      for i in 0..<game.characters.len:
        let wasAtExit = game.characters[i].atExit
        game.characters[i].atExit = game.characters[i].id in result.exitedCharacters
        if game.characters[i].atExit and not wasAtExit:
          playSound(soundExitReached)

      # Buffered jump: if the active character landed this frame, spend the buffer immediately.
      if game.activeCharacterIndex < game.characters.len and
         game.characters[game.activeCharacterIndex].jumpBufferTimer > 0.0 and
         attemptCharacterJump(game.characters[game.activeCharacterIndex]):
        playSound(soundJump)

      # Check win — all characters at their exits
      if game.characters.len > 0:
        var allAtExit = true
        for c in game.characters:
          if not c.atExit:
            allAtExit = false
            break
        if allAtExit and game.state == playing:
          game.state = levelWin
          game.levelWinTimer = 0.0
          playSound(soundLevelComplete)

      # Update camera to follow active character
      if game.activeCharacterIndex < game.characters.len:
        let ch = game.characters[game.activeCharacterIndex]
        updateCamera(game.camera, ch.x, ch.y, float(ch.width), float(ch.height),
                     level.levelWidth, level.levelHeight)

    # Update animations for all characters
    for i in 0..<game.characters.len:
      updateAnimation(game.characters[i], scaledDt)
      if game.characters[i].jumpBufferTimer > 0.0:
        game.characters[i].jumpBufferTimer =
          max(0.0, game.characters[i].jumpBufferTimer - scaledDt)

    # Update atmospheric background effects
    game.atmosphere.update(scaledDt)

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
