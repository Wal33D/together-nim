## Game state machine, update logic, and level management

import
  windy,
  constants,
  entities/character,
  entities/level,
  systems/levels,
  systems/physics,
  systems/camera,
  systems/atmosphere,
  systems/audio
import systems/particles

type
  GameState* = enum
    menu, playing, paused, levelWin, credits, actTitle

  ActDef* = object
    number*: int
    name*: string
    startLevel*: int
    endLevel*: int
    themeColor*: Color

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
    particles*: ParticleSystem
    currentLevelState*: Level
    menuTime*: float
    elapsedTime*: float
    menuAtmosphere*: Atmosphere
    actTitleTimer*: float
    actTitleTarget*: int

const
  ActTitleFadeIn* = 1.0
  ActTitleHold* = 2.0
  ActTitleFadeOut* = 1.0
  ActTitleDuration* = ActTitleFadeIn + ActTitleHold + ActTitleFadeOut

  Acts*: array[5, ActDef] = [
    ActDef(number: 1, name: "Awakening",      startLevel: 1,  endLevel: 6,  themeColor: PIP_COLOR),
    ActDef(number: 2, name: "Belonging",       startLevel: 7,  endLevel: 12, themeColor: LUCA_COLOR),
    ActDef(number: 3, name: "Challenge",       startLevel: 13, endLevel: 18, themeColor: BRUNO_COLOR),
    ActDef(number: 4, name: "Separation",      startLevel: 19, endLevel: 24, themeColor: CARA_COLOR),
    ActDef(number: 5, name: "Transcendence",   startLevel: 25, endLevel: 30, themeColor: IVY_COLOR),
  ]


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

proc characterCenterX(c: Character): float =
  c.x + float(c.width) * 0.5

proc characterCenterY(c: Character): float =
  c.y + float(c.height) * 0.5

proc characterFeetX(c: Character): float =
  c.x + float(c.width) * 0.5

proc characterFeetY(c: Character): float =
  c.y + float(c.height) - 2.0

proc findCharacterIndex(game: Game, characterId: string): int =
  for i, c in game.characters:
    if c.id == characterId:
      return i
  -1

proc emitJumpParticles(game: var Game, idx: int) =
  let c = game.characters[idx]
  let charColor = CHAR_COLORS[c.colorIndex mod 6]
  if c.ability == doubleJump and c.jumpCount >= 2:
    game.particles.emitDoubleJump(c.characterFeetX(), c.characterFeetY(),
                                  charColor)
  else:
    game.particles.emitJump(c.characterFeetX(), c.characterFeetY(), charColor)

proc emitLandingParticles(game: var Game, idx: int) =
  let c = game.characters[idx]
  game.particles.emitLanding(c.characterFeetX(), c.characterFeetY(),
                             CHAR_COLORS[c.colorIndex mod 6])

proc emitDeathParticles(game: var Game, idx: int) =
  let c = game.characters[idx]
  game.particles.emitDeath(c.characterCenterX(), c.characterCenterY(),
                           CHAR_COLORS[c.colorIndex mod 6])

proc emitExitParticles(game: var Game, idx: int) =
  let c = game.characters[idx]
  for e in game.currentLevelState.exits:
    if e.characterId == c.id:
      game.particles.emitExit(e.x + e.width * 0.5, e.y + e.height * 0.5,
                              CHAR_COLORS[c.colorIndex mod 6])
      break

proc emitCompletionParticles(game: var Game) =
  let completionColor: Color = (r: 248'u8, g: 232'u8, b: 178'u8)
  for c in game.characters:
    game.particles.emitCompletion(c.characterCenterX(), c.characterCenterY(),
                                  completionColor)

proc accentCharacterSwitch(game: var Game, previousIdx, newIdx: int) =
  game.camera.boostResponse(0.18)

  if previousIdx < 0 or previousIdx >= game.characters.len or
     newIdx < 0 or newIdx >= game.characters.len:
    return

  let dx = game.characters[newIdx].characterCenterX() -
    game.characters[previousIdx].characterCenterX()
  game.camera.addImpulse(max(-12.0, min(12.0, dx * 0.12)), -4.0)

proc accentJump(game: var Game) =
  game.camera.boostResponse(0.05)
  game.camera.addImpulse(0.0, -10.0)

proc accentLanding(game: var Game, idx: int) =
  if idx != game.activeCharacterIndex:
    return
  game.camera.boostResponse(0.08)
  game.camera.addImpulse(0.0, 12.0)

proc accentDeath(game: var Game, idx: int) =
  if idx != game.activeCharacterIndex:
    return
  game.camera.boostResponse(0.22)
  game.camera.addImpulse(0.0, 8.0)

proc accentLevelComplete(game: var Game) =
  game.camera.boostResponse(0.14)
  game.camera.addImpulse(0.0, -8.0)
  game.camera.hold(0.18)

proc queueCameraSnapToCharacter(game: var Game, idx: int) =
  if idx < 0 or idx >= game.characters.len:
    return
  if game.currentLevel < 0 or game.currentLevel >= allLevels.len:
    return

  let ch = game.characters[idx]
  queueSnap(game.camera, ch.x, ch.y, float(ch.width), float(ch.height),
            game.currentLevelState.levelWidth, game.currentLevelState.levelHeight)

proc pressJump*(game: var Game) =
  game.jumpPressed = true

  if game.state != playing:
    return

  if game.activeCharacterIndex < game.characters.len:
    if attemptCharacterJump(game.characters[game.activeCharacterIndex]):
      game.emitJumpParticles(game.activeCharacterIndex)
      game.accentJump()
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

  let previousIdx = game.activeCharacterIndex
  if game.activeCharacterIndex >= 0 and game.activeCharacterIndex < game.characters.len:
    game.characters[game.activeCharacterIndex].jumpBufferTimer = 0.0

  game.activeCharacterIndex = idx
  game.accentCharacterSwitch(previousIdx, idx)
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
  game.accentCharacterSwitch(currentIdx, newIdx)
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
  game.particles = ParticleSystem(particles: @[])

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
    particles: ParticleSystem(particles: @[]),
    menuTime: 0.0,
    elapsedTime: 0.0,
    menuAtmosphere: newAtmosphere(allColors),
  )

proc actForLevel*(levelIdx: int): int =
  ## Return the act index (0-based) for a given level index, or -1 if none.
  let levelNum = levelIdx + 1
  for i, act in Acts:
    if levelNum >= act.startLevel and levelNum <= act.endLevel:
      return i
  -1

proc isFirstLevelOfAct*(levelIdx: int): bool =
  ## Return true if this level index is the first level of its act.
  let levelNum = levelIdx + 1
  for act in Acts:
    if levelNum == act.startLevel:
      return true
  false

proc actTitleAlpha*(game: Game): float =
  ## Return the current opacity (0.0..1.0) for the act title card.
  let t = game.actTitleTimer
  if t < ActTitleFadeIn:
    t / ActTitleFadeIn
  elif t < ActTitleFadeIn + ActTitleHold:
    1.0
  else:
    let fadeT = t - ActTitleFadeIn - ActTitleHold
    max(0.0, 1.0 - fadeT / ActTitleFadeOut)

proc showActTitle(game: var Game, levelIdx: int) =
  ## Enter the actTitle state before loading the given level.
  game.state = actTitle
  game.actTitleTimer = 0.0
  game.actTitleTarget = levelIdx

proc startGame*(game: var Game) =
  if isFirstLevelOfAct(0):
    game.showActTitle(0)
  else:
    game.state = playing
    game.loadLevel(0)

proc restartLevel*(game: var Game) =
  game.loadLevel(game.currentLevel)

proc nextLevel*(game: var Game) =
  let nextIdx = game.currentLevel + 1
  if nextIdx < allLevels.len:
    if isFirstLevelOfAct(nextIdx):
      game.showActTitle(nextIdx)
    else:
      game.loadLevel(nextIdx)
      game.state = playing
  else:
    game.state = credits

proc handleKey*(game: var Game, button: windy.Button) =
  case game.state
  of menu:
    if button == KeyEnter:
      game.startGame()
  of playing:
    if button == KeyEscape:
      game.state = paused
    elif button == KeyR:
      game.restartLevel()
  of paused:
    if button == KeyEscape:
      game.state = playing
  of levelWin:
    if button == KeyEnter:
      game.nextLevel()
  of credits:
    if button == KeyEnter:
      game.state = menu
  of actTitle:
    discard

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
            game.emitDeathParticles(i)
            game.characters[i].x = game.characters[i].spawnX
            game.characters[i].y = game.characters[i].spawnY
            game.characters[i].vx = 0
            game.characters[i].vy = 0
            game.characters[i].dead = false
            if i == game.activeCharacterIndex:
              game.camera.hold(0.10)
              game.queueCameraSnapToCharacter(i)
            game.accentDeath(i)
            playSound(soundDeath)

      # Landing sound
      if result.landedCharacters.len > 0:
        for landedId in result.landedCharacters:
          let idx = game.findCharacterIndex(landedId)
          if idx >= 0:
            game.emitLandingParticles(idx)
            game.accentLanding(idx)
        playSound(soundLand)

      # Mark exits — play chime when a character newly reaches their exit
      for i in 0..<game.characters.len:
        let wasAtExit = game.characters[i].atExit
        game.characters[i].atExit = game.characters[i].id in result.exitedCharacters
        if game.characters[i].atExit and not wasAtExit:
          game.emitExitParticles(i)
          playSound(soundExitReached)

      # Buffered jump: if the active character landed this frame, spend the buffer immediately.
      if game.activeCharacterIndex < game.characters.len and
         game.characters[game.activeCharacterIndex].jumpBufferTimer > 0.0 and
         attemptCharacterJump(game.characters[game.activeCharacterIndex]):
        game.emitJumpParticles(game.activeCharacterIndex)
        game.accentJump()
        playSound(soundJump)

      # Check win — all characters at their exits
      if game.characters.len > 0:
        var allAtExit = true
        for c in game.characters:
          if not c.atExit:
            allAtExit = false
            break
        if allAtExit and game.state == playing:
          game.emitCompletionParticles()
          game.accentLevelComplete()
          game.state = levelWin
          game.levelWinTimer = 0.0
          playSound(soundLevelComplete)

      # Update camera to follow active character
      if game.activeCharacterIndex < game.characters.len:
        let ch = game.characters[game.activeCharacterIndex]
        updateCamera(game.camera, ch.x, ch.y, float(ch.width), float(ch.height),
                     ch.vx, ch.vy, ch.facingRight, level.levelWidth,
                     level.levelHeight, scaledDt)

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
    if game.currentLevel >= 0 and game.currentLevel < allLevels.len and
       game.activeCharacterIndex < game.characters.len:
      let ch = game.characters[game.activeCharacterIndex]
      let level = game.currentLevelState
      updateCamera(game.camera, ch.x, ch.y, float(ch.width), float(ch.height),
                   ch.vx, ch.vy, ch.facingRight, level.levelWidth,
                   level.levelHeight, scaledDt)

  of actTitle:
    game.actTitleTimer += scaledDt
    if game.actTitleTimer >= ActTitleDuration:
      game.loadLevel(game.actTitleTarget)
      game.state = playing

  else:
    discard

  game.particles.update(scaledDt)
