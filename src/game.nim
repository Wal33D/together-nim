## Game state machine, update logic, and level management

import
  std/[math, random, tables],
  windy,
  vmath,
  constants,
  entities/character,
  entities/level,
  systems/levels,
  systems/physics,
  systems/camera,
  systems/atmosphere,
  systems/audio,
  systems/save
import systems/[particles, animation, screenEffects]

type
  GameState* = enum
    menu, playing, paused, levelWin, credits, actTitle, settings, levelSelect, won, storyBeat

  ActDef* = object
    number*: int
    name*: string
    startLevel*: int
    endLevel*: int
    themeColor*: Color

  MenuBgChar* = object
    pos*: Vec2
    vel*: Vec2
    scale*: float       # 0.5–1.0 for parallax depth
    colorAlpha*: float  # 0.6 for muted appearance
    charIndex*: int

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
    exitEmitTimers*: seq[float]
    charDimTimer*: float
    prevActiveCharacterIndex*: int
    triggeredMoments*: set[uint8]
    finaleTimer*: float
    finaleActive*: bool
    finalePhase*: int              # 0=inactive, 1=extra hold, 2=narration, 3=post-narration, 4=warm fade
    finaleNarrationRevealed*: int
    screenBrightness*: float
    screenEffects*: ScreenEffects
    prevFullGroup*: bool
    levelStartTime*: float
    deathOccurred*: bool
    secretCollected*: bool
    earnedStars*: array[3, bool]
    previousState*: GameState
    settingsCursor*: int
    settingsWindowPreset*: int
    fullscreenEnabled*: bool
    vsyncEnabled*: bool
    pendingSettingsApply*: bool
    creditsTimer*: float
    dynamicTimeScale*: float
    slowMotionTimer*: float
    levelSelectRow*: int
    levelSelectCol*: int
    levelSelectRejectTimer*: float
    wonTimer*: float
    wonThankYouShown*: bool
    totalDeaths*: int
    wonLevelsCompleted*: int
    wonTotalTime*: float
    storyBeatText*: string
    storyBeatRevealed*: int
    storyBeatTimer*: float
    charactersMet*: set[uint8]
    gameFrozen*: bool
    introTimer*: float
    introCharacterIdx*: int
    introQueue*: seq[int]
    introPhase*: int                  # 0=pre-delay, 1=showing, 2=post-narration
    thoughtBubble*: tuple[text: string, charIdx: int, timer: float, fadeIn: float, fadeOut: float]
    thoughtCooldowns*: Table[string, float]
    comboActive*: bool
    comboCooldown*: float
    comboReadyTimer*: float
    charFlashTimers*: array[6, float]
    glideShimmerTimer*: float
    menuBgChars*: array[6, MenuBgChar]

  ThoughtEntry = object
    pair: string
    thoughts: seq[string]

const
  ThoughtTable: seq[ThoughtEntry] = @[
    ThoughtEntry(pair: "bruno-pip", thoughts: @[
      "He's so big... I feel safe.",
      "I could see everything from up there.",
      "Must be gentle. She's so small.",
      "She makes the quiet feel less heavy."]),
    ThoughtEntry(pair: "luca-pip", thoughts: @[
      "How does he float like that?",
      "I want to drift too.",
      "She bounces so high. I just... float."]),
    ThoughtEntry(pair: "bruno-cara", thoughts: @[
      "She climbs so fast. I can barely look up.",
      "He's like a mountain. Mountains don't need to climb."]),
    ThoughtEntry(pair: "felix-ivy", thoughts: @[
      "She falls so gracefully. I just stand and wait.",
      "He never rushes. I never rush. We understand each other."]),
    ThoughtEntry(pair: "bruno-felix", thoughts: @[
      "He stands so still. Like a tall tree.",
      "He's solid. I can lean on that."]),
    ThoughtEntry(pair: "bruno-ivy", thoughts: @[
      "She moves like water. I'm just stone.",
      "He reminds me of the ground. Steady."]),
    ThoughtEntry(pair: "bruno-luca", thoughts: @[
      "He drifts so easily. Must be nice.",
      "Bruno's like an anchor. I need that."]),
    ThoughtEntry(pair: "cara-felix", thoughts: @[
      "He waits so long. I'd climb the walls.",
      "She's already up there. I'll catch up."]),
    ThoughtEntry(pair: "cara-ivy", thoughts: @[
      "She's so calm in the air. I grip the wall.",
      "She climbs like it's nothing. I just watch."]),
    ThoughtEntry(pair: "cara-luca", thoughts: @[
      "He floats. I climb. Same height, different paths.",
      "She's always moving. I just drift."]),
    ThoughtEntry(pair: "cara-pip", thoughts: @[
      "She's smaller than me! That's rare.",
      "She's so fast on walls. I want to try."]),
    ThoughtEntry(pair: "felix-luca", thoughts: @[
      "We both take our time. That's okay.",
      "He's patient. Like the pause between waves."]),
    ThoughtEntry(pair: "felix-pip", thoughts: @[
      "She never stops. I always stop.",
      "He's so tall and so still. Like a lighthouse."]),
    ThoughtEntry(pair: "ivy-luca", thoughts: @[
      "We both float, in different ways.",
      "She falls like she's flying."]),
    ThoughtEntry(pair: "ivy-pip", thoughts: @[
      "So much energy in something so small.",
      "She moves like a leaf. So gentle."]),
  ]
  ProximityNear* = 80.0
  ProximityFar* = 200.0
  ProximityGlowRange* = 120.0

  FinalLevel* = 29
  FinaleNarrationText* = "They were different shapes. Different sizes. Different colors. But they had found each other in the dark, and the dark wasn't dark anymore. Together, they were home."
  FinaleNarrationSpeed = 20.0  # chars per second

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

var
  transitionAlpha*: float = 0.0
  transitionColor*: Color = (r: 255'u8, g: 255'u8, b: 255'u8)
  transitionPool: TweenPool = initTweenPool()
  transitionPendingNextLevel: bool = false


proc thoughtBubbleAlpha*(game: Game): float =
  ## Return the current opacity (0.0..1.0) for the thought bubble.
  let t = game.thoughtBubble.timer
  if t <= 0.0 or game.thoughtBubble.text.len == 0:
    return 0.0
  let totalDur = 3.5
  if t > totalDur - game.thoughtBubble.fadeIn:
    return (totalDur - t) / game.thoughtBubble.fadeIn
  if t < game.thoughtBubble.fadeOut:
    return t / game.thoughtBubble.fadeOut
  1.0

proc thoughtPairKey(a, b: string): string =
  ## Build a sorted pair key for the thought table.
  if a < b: a & "-" & b
  else: b & "-" & a

proc thoughtsForPair(key: string): seq[string] =
  ## Look up thoughts for a character pair.
  for entry in ThoughtTable:
    if entry.pair == key:
      return entry.thoughts
  @[]

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
      let isSecondJump = c.jumpCount >= 1
      c.vy = c.jumpForce()
      c.grounded = false
      if c.jumpCount < 1:
        c.jumpCount = 1
      else:
        inc c.jumpCount
      c.coyoteTimer = graceWindow + 1.0
      c.jumpBufferTimer = 0.0
      c.triggerJump(isSecondJump)
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

const CharFlashDuration = 0.15

proc emitJumpParticles(game: var Game, idx: int) =
  let c = game.characters[idx]
  let charColor = CHAR_COLORS[c.colorIndex mod 6]
  if c.ability == doubleJump and c.jumpCount >= 2:
    game.particles.emitDoubleJump(c.characterFeetX(), c.characterFeetY(),
                                  charColor)
    game.particles.emitDoubleJumpRing(c.characterFeetX(), c.characterFeetY(),
                                      float(CHAR_WIDTH), charColor)
    game.charFlashTimers[idx mod 6] = CharFlashDuration
  else:
    game.particles.emitJump(c.characterFeetX(), c.characterFeetY(), charColor)

proc emitLandingParticles(game: var Game, idx: int,
                          ability: CharacterAbility, fallSpeed: float) =
  let c = game.characters[idx]
  game.particles.emitLanding(c.characterFeetX(), c.characterFeetY(),
                             CHAR_COLORS[c.colorIndex mod 6],
                             ability, fallSpeed)

proc emitDeathParticles(game: var Game, idx: int) =
  let c = game.characters[idx]
  game.particles.emitDeathDissolve(c.characterCenterX(), c.characterCenterY(),
                                   CHAR_COLORS[c.colorIndex mod 6])

proc emitRespawnParticles(game: var Game, idx: int) =
  let c = game.characters[idx]
  game.particles.emitRespawnReform(c.spawnX + float(c.width) * 0.5,
                                   c.spawnY + float(c.height) * 0.5,
                                   CHAR_COLORS[c.colorIndex mod 6])

proc emitExitParticles(game: var Game, idx: int) =
  let c = game.characters[idx]
  for e in game.currentLevelState.exits:
    if e.sharedExit or e.characterId == c.id:
      game.particles.emitExit(e.x + e.width * 0.5, e.y + e.height * 0.5,
                              CHAR_COLORS[c.colorIndex mod 6])
      break

proc emitCompletionParticles(game: var Game) =
  for c in game.characters:
    let topX = c.characterCenterX()
    let topY = c.drawY()
    game.particles.emitConfetti(topX, topY,
                                CHAR_COLORS[c.colorIndex mod 6])

proc emitSwitchParticles(game: var Game, idx: int) =
  ## Emit a white ring on the newly active character.
  let c = game.characters[idx]
  let whiteColor: Color = (r: 255'u8, g: 255'u8, b: 255'u8)
  game.particles.emitSwitchRing(
    c.x + float(c.width) * 0.5,
    c.y + float(c.height) * 0.5,
    float(c.width), float(c.height), whiteColor)

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

  # Skip overview pan on any jump input.
  if game.camera.isOverviewActive():
    skipOverview(game.camera)
    return

  if game.activeCharacterIndex < game.characters.len:
    let ac = game.characters[game.activeCharacterIndex]
    if ac.isDying() or ac.isRespawning():
      discard
    elif game.comboCooldown <= 0.0 and
         (ac.grounded or ac.coyoteTimer < jumpGraceWindow(ac)) and
         findComboPartner(game.characters, game.activeCharacterIndex) >= 0:
      # Pip-Bruno super bounce: 1.5x velocity, squash Bruno, special particles+sound.
      let sbResult = applySuperBounce(game.characters, game.activeCharacterIndex)
      if sbResult.triggered:
        game.characters[game.activeCharacterIndex].coyoteTimer = jumpGraceWindow(ac) + 1.0
        game.characters[game.activeCharacterIndex].jumpBufferTimer = 0.0
        game.particles.emitSuperBounce(sbResult.contactX, sbResult.contactY)
        playSound(soundSuperBounce)
      else:
        # Generic combo jump for other pairs.
        game.characters[game.activeCharacterIndex].vy = ac.jumpForce() * ComboJumpMultiplier
        game.characters[game.activeCharacterIndex].grounded = false
        game.characters[game.activeCharacterIndex].jumpCount = 1
        game.characters[game.activeCharacterIndex].coyoteTimer = jumpGraceWindow(ac) + 1.0
        game.characters[game.activeCharacterIndex].jumpBufferTimer = 0.0
        game.characters[game.activeCharacterIndex].triggerJump()
        game.emitJumpParticles(game.activeCharacterIndex)
        playSound(CharJumpSounds[game.activeCharacterIndex])
      game.comboActive = true
      game.comboCooldown = ComboCooldownTime
      game.accentJump()
    elif attemptCharacterJump(game.characters[game.activeCharacterIndex]):
      game.emitJumpParticles(game.activeCharacterIndex)
      game.accentJump()
      let ci = game.activeCharacterIndex
      if game.characters[ci].ability == doubleJump and game.characters[ci].jumpCount >= 2:
        playSound(soundJumpPipDouble)
      else:
        playSound(CharJumpSounds[ci])
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
  game.prevActiveCharacterIndex = previousIdx
  game.charDimTimer = 0.3
  game.accentCharacterSwitch(previousIdx, idx)
  game.emitSwitchParticles(idx)
  playSound(soundCharSwitch)
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
  game.prevActiveCharacterIndex = currentIdx
  game.charDimTimer = 0.3
  game.accentCharacterSwitch(currentIdx, newIdx)
  game.emitSwitchParticles(newIdx)
  playSound(soundCharSwitch)
  true

proc updateCharactersMet*(game: var Game) =
  ## Derive charactersMet bitmask from currentLevel.
  game.charactersMet = {0'u8}  # Pip is always met.
  let levelNum = game.currentLevel + 1
  if levelNum >= 5: game.charactersMet.incl(1'u8)   # Luca
  if levelNum >= 6: game.charactersMet.incl(2'u8)   # Bruno
  if levelNum >= 8: game.charactersMet.incl(3'u8)   # Cara
  if levelNum >= 13:
    game.charactersMet.incl(4'u8)  # Felix
    game.charactersMet.incl(5'u8)  # Ivy

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
    c.idleFidgetTimer = float(i) * 0.5
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
  game.exitEmitTimers = newSeq[float](level.exits.len)

  # Detect new characters before updating charactersMet.
  let oldMet = game.charactersMet
  game.updateCharactersMet()
  game.introQueue = @[]
  for i, c in game.characters:
    let ci = uint8(c.colorIndex)
    if ci notin oldMet and ci in game.charactersMet:
      let narr = introNarration(c.id)
      if narr.len > 0:
        game.introQueue.add(i)
  game.introTimer = 0.0
  game.introPhase = 0
  game.introCharacterIdx = -1
  game.gameFrozen = false

  # Narration
  game.narrationText = level.narration
  game.narrationRevealed = 0
  game.narrationTimer = 0.0
  game.narrationActive = level.narration.len > 0
  game.finaleActive = false
  game.finaleTimer = 0.0
  game.finalePhase = 0
  game.finaleNarrationRevealed = 0
  game.screenBrightness = 0.0
  game.levelWinTimer = 0.0
  game.dynamicTimeScale = 1.0
  game.slowMotionTimer = 0.0
  game.comboActive = false
  game.comboCooldown = 0.0
  game.comboReadyTimer = 0.0
  game.jumpPressed = false
  game.levelStartTime = game.elapsedTime
  game.deathOccurred = false
  game.secretCollected = false
  game.earnedStars = [false, false, false]
  # Set tonal palette for this act.
  let levelNum = idx + 1
  for ai, act in Acts:
    if levelNum >= act.startLevel and levelNum <= act.endLevel:
      if ai < ActPalettes.len:
        setActPalette(ActPalettes[ai])
        setActOscConfig(ActOscillatorParams[ai + 1])
      break

  # Snap camera to active character, then start overview pan.
  if game.characters.len > 0:
    let ch = game.characters[0]
    snapCamera(game.camera, ch.x, ch.y, float(ch.width), float(ch.height),
               level.levelWidth, level.levelHeight)
    startOverview(game.camera, level.levelWidth, level.levelHeight,
                  ch.x, ch.y, float(ch.width), float(ch.height))

const
  MenuBgCharMaxSpeed = 30.0

proc initMenuBgChars*(game: var Game) =
  ## Populate 6 background character shapes with random positions and depth-scaled velocity.
  for i in 0 ..< 6:
    let s = 0.5 + rand(0.5)  # scale 0.5..1.0
    let sz = s * 56.0
    game.menuBgChars[i] = MenuBgChar(
      pos: vec2(rand(DEFAULT_WIDTH.float - sz), rand(DEFAULT_HEIGHT.float - sz)),
      vel: vec2((rand(2.0) - 1.0) * MenuBgCharMaxSpeed * s,
                (rand(2.0) - 1.0) * MenuBgCharMaxSpeed * s),
      scale: s,
      colorAlpha: 0.6,
      charIndex: i,
    )

proc updateMenuBgChars*(game: var Game, dt: float) =
  ## Drift and bounce background character shapes off screen edges.
  for i in 0 ..< 6:
    game.menuBgChars[i].pos += game.menuBgChars[i].vel * dt
    let sz = game.menuBgChars[i].scale * 56.0
    if game.menuBgChars[i].pos.x < 0.0:
      game.menuBgChars[i].pos.x = 0.0
      game.menuBgChars[i].vel.x = -game.menuBgChars[i].vel.x
    elif game.menuBgChars[i].pos.x + sz > DEFAULT_WIDTH.float:
      game.menuBgChars[i].pos.x = DEFAULT_WIDTH.float - sz
      game.menuBgChars[i].vel.x = -game.menuBgChars[i].vel.x
    if game.menuBgChars[i].pos.y < 0.0:
      game.menuBgChars[i].pos.y = 0.0
      game.menuBgChars[i].vel.y = -game.menuBgChars[i].vel.y
    elif game.menuBgChars[i].pos.y + sz > DEFAULT_HEIGHT.float:
      game.menuBgChars[i].pos.y = DEFAULT_HEIGHT.float - sz
      game.menuBgChars[i].vel.y = -game.menuBgChars[i].vel.y

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
    camera: newCamera(),
    atmosphere: newAtmosphere(@[]),
    particles: ParticleSystem(particles: @[]),
    menuTime: 0.0,
    elapsedTime: 0.0,
    menuAtmosphere: newMenuAtmosphere(),
    screenEffects: initScreenEffects(),
    dynamicTimeScale: 1.0,
  )
  result.initMenuBgChars()

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
  let ai = actForLevel(levelIdx)
  if ai >= 0:
    fadeOutAmbient(0.3)
    playActTransitionStinger(ai)

proc checkScriptedMoments*(game: var Game) =
  ## Check and trigger scripted emotional moments after physics each frame.
  let levelNum = game.currentLevel + 1

  # Level 7: Bruno's first button press triggers celebration bounce.
  if levelNum == 7 and 7'u8 notin game.triggeredMoments:
    for b in game.currentLevelState.buttons:
      if b.active and not b.prevActive:
        game.triggeredMoments.incl(7'u8)
        for j in 0..<game.characters.len:
          if game.characters[j].grounded:
            game.characters[j].vy = -100.0
        break

  # Level 13: All 6 at exits triggers special narration.
  if levelNum == 13 and 13'u8 notin game.triggeredMoments:
    if game.characters.len > 0:
      var allAtExit = true
      for c in game.characters:
        if not c.atExit:
          allAtExit = false
          break
      if allAtExit:
        game.triggeredMoments.incl(13'u8)
        game.narrationText = "Together. Finally, together."
        game.narrationRevealed = 0
        game.narrationTimer = 0.0
        game.narrationActive = true

  # Level 19: Pip reaching other characters triggers reunion narration.
  if levelNum == 19 and 19'u8 notin game.triggeredMoments:
    var pipIdx = -1
    for i, c in game.characters:
      if c.id == "pip":
        pipIdx = i
        break
    if pipIdx >= 0 and game.characters.len > 1:
      let pip = game.characters[pipIdx]
      let pipCx = pip.x + float(pip.width) * 0.5
      let pipCy = pip.y + float(pip.height) * 0.5
      var nearAny = false
      for i, c in game.characters:
        if i == pipIdx: continue
        let cx = c.x + float(c.width) * 0.5
        let cy = c.y + float(c.height) * 0.5
        let dx = pipCx - cx
        let dy = pipCy - cy
        if dx * dx + dy * dy < 80.0 * 80.0:
          nearAny = true
          break
      if nearAny:
        game.triggeredMoments.incl(19'u8)
        game.narrationText = "They were waiting. They had always been waiting."
        game.narrationRevealed = 0
        game.narrationTimer = 0.0
        game.narrationActive = true

  # Level 30 finale is now handled in the levelWin state handler.

proc startGame*(game: var Game) =
  game.triggeredMoments = {}
  if isFirstLevelOfAct(0):
    game.showActTitle(0)
  else:
    game.state = playing
    game.loadLevel(0)

proc continueGame*(game: var Game) =
  ## Resume from the furthest completed level.
  let resumeLevel = min(savedContinueLevel(), allLevels.len - 1)
  game.triggeredMoments = {}
  if isFirstLevelOfAct(resumeLevel):
    game.showActTitle(resumeLevel)
  else:
    game.state = playing
    game.loadLevel(resumeLevel)

proc restartLevel*(game: var Game) =
  game.loadLevel(game.currentLevel)

proc enterCredits*(game: var Game) =
  ## Transition to the credits sequence.
  game.state = credits
  game.creditsTimer = 0.0
  game.screenBrightness = 0.0

proc enterWon*(game: var Game) =
  ## Transition to the end-game celebration screen.
  game.state = won
  game.wonTimer = 0.0
  game.wonThankYouShown = false
  game.wonTotalTime = game.elapsedTime
  let saveData = loadSave()
  game.wonLevelsCompleted = saveData.levelStars.len
  game.particles.emitWinConfetti()

proc nextLevel*(game: var Game) =
  if game.currentLevel == FinalLevel:
    game.enterWon()
    return
  let nextIdx = game.currentLevel + 1
  if nextIdx < allLevels.len:
    if isFirstLevelOfAct(nextIdx):
      game.showActTitle(nextIdx)
    else:
      let nextLevelData = allLevels[nextIdx]
      if nextLevelData.interLevelNarration.len > 0:
        game.loadLevel(nextIdx)
        game.state = storyBeat
        game.storyBeatText = nextLevelData.interLevelNarration
        game.storyBeatRevealed = 0
        game.storyBeatTimer = 0.0
      else:
        game.loadLevel(nextIdx)
        game.state = playing
  else:
    game.enterCredits()

proc openSettings*(game: var Game) =
  ## Enter the settings screen, remembering where to return.
  game.previousState = game.state
  game.settingsCursor = 0
  game.state = settings

proc launchSelectedLevel*(game: var Game) =
  ## Launch the level at the current cursor position, or reject if locked.
  let
    LevelsPerAct = 6
    levelIdx = game.levelSelectRow * LevelsPerAct + game.levelSelectCol
  if levelIdx < 0 or levelIdx >= allLevels.len:
    return
  if not levelAvailable(levelIdx):
    game.levelSelectRejectTimer = 0.25
    playSound(soundMenuBack)
    return
  game.triggeredMoments = {}
  if isFirstLevelOfAct(levelIdx):
    game.showActTitle(levelIdx)
  else:
    game.state = playing
    game.loadLevel(levelIdx)
  playSound(soundMenuSelect)

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
      playSound(soundMenuBack)
  of levelWin:
    discard
  of credits:
    game.state = menu
  of actTitle:
    discard
  of settings:
    discard
  of levelSelect:
    if button == KeyEscape:
      game.state = menu
      playSound(soundMenuBack)
  of storyBeat:
    if button == KeySpace or button == KeyEnter:
      if game.storyBeatRevealed < game.storyBeatText.len:
        game.storyBeatRevealed = game.storyBeatText.len
      else:
        game.state = playing
  of won:
    if game.wonThankYouShown:
      game.state = menu
    else:
      game.wonThankYouShown = true

proc update*(game: var Game, dt: float) =
  let baseDt = dt * TIME_SCALE
  let scaledDt = baseDt * game.dynamicTimeScale
  game.deltaTime = scaledDt
  game.elapsedTime += scaledDt

  case game.state
  of menu:
    game.menuTime += scaledDt
    game.menuAtmosphere.update(scaledDt)
    game.updateMenuBgChars(scaledDt)
  of playing:
    # Intro sequence for first-meeting characters.
    if game.introQueue.len > 0:
      game.introTimer += scaledDt
      case game.introPhase
      of 0:
        # Pre-delay: 2s for first intro, 1s gap for subsequent.
        let delay = if game.introCharacterIdx < 0: 2.0 else: 1.0
        if game.introTimer >= delay:
          game.introCharacterIdx = game.introQueue[0]
          game.gameFrozen = true
          game.introPhase = 1
          game.introTimer = 0.0
          # Snap camera to the new character.
          game.queueCameraSnapToCharacter(game.introCharacterIdx)
          # Start narration.
          let charId = game.characters[game.introCharacterIdx].id
          game.narrationText = introNarration(charId)
          game.narrationRevealed = 0
          game.narrationTimer = 0.0
          game.narrationActive = true
      of 1:
        # Showing intro: tween glow up over 0.5s while narration plays.
        if game.introCharacterIdx >= 0 and game.introCharacterIdx < game.characters.len:
          game.characters[game.introCharacterIdx].introGlowBoost =
            min(2.0, game.characters[game.introCharacterIdx].introGlowBoost + 4.0 * scaledDt)
        if not game.narrationActive:
          game.introPhase = 2
          game.introTimer = 0.0
      of 2:
        # Post-narration 0.5s delay before unfreeze.
        if game.introTimer >= 0.5:
          game.gameFrozen = false
          if game.introCharacterIdx >= 0 and game.introCharacterIdx < game.characters.len:
            game.charactersMet.incl(uint8(game.characters[game.introCharacterIdx].colorIndex))
          game.introQueue.delete(0)
          game.introPhase = 0
          game.introTimer = 0.0
      else: discard

    # Decay introGlowBoost for all characters (fade out after intro ends).
    for i in 0..<game.characters.len:
      if game.introPhase != 1 or i != game.introCharacterIdx:
        game.characters[i].introGlowBoost =
          max(0.0, game.characters[i].introGlowBoost - 4.0 * scaledDt)

    if not game.gameFrozen and not game.camera.isOverviewActive():
      # Apply movement to active character (blocked during death/respawn)
      if game.activeCharacterIndex < game.characters.len:
        let ac = game.characters[game.activeCharacterIndex]
        if ac.isDying() or ac.isRespawning():
          game.characters[game.activeCharacterIndex].inputDir = 0
        else:
          var dir = 0
          if game.leftHeld: dir -= 1
          if game.rightHeld: dir += 1
          game.characters[game.activeCharacterIndex].inputDir = dir
          if dir > 0: game.characters[game.activeCharacterIndex].facingRight = true
          elif dir < 0: game.characters[game.activeCharacterIndex].facingRight = false

    # Physics (blocked during overview pan).
    if not game.gameFrozen and not game.camera.isOverviewActive() and
       game.currentLevel >= 0 and game.currentLevel < allLevels.len:
      let result = updatePhysics(game.characters, game.currentLevelState, scaledDt)
      let level = game.currentLevelState

      # Animate button pressedAmount toward target each frame.
      for bi in 0..<game.currentLevelState.buttons.len:
        let target = if game.currentLevelState.buttons[bi].active: 1.0 else: 0.0
        let rate = if game.currentLevelState.buttons[bi].active: 15.0 * scaledDt else: 10.0 * scaledDt
        game.currentLevelState.buttons[bi].pressedAmount +=
          (target - game.currentLevelState.buttons[bi].pressedAmount) * min(1.0, rate)

      # Hazard contact flash-shake — fires on spike contact just before death
      for hazId in result.hazardCharacters:
        let hazardRed: Color = (r: 180'u8, g: 30'u8, b: 30'u8)
        game.screenEffects.triggerShake(game.camera, 4.0, 0.15)
        game.screenEffects.triggerFlash(hazardRed, 0.05)

      # Handle deaths — start death animation phase (500ms)
      for deadId in result.deadCharacters:
        for i in 0..<game.characters.len:
          if game.characters[i].id == deadId and not game.characters[i].isDying() and not game.characters[i].isRespawning():
            game.characters[i].deathTimer = 0.5
            game.characters[i].deathFlashCount = 0
            game.characters[i].vx = 0
            game.characters[i].vy = 0
            game.deathOccurred = true
            game.totalDeaths += 1
            game.emitDeathParticles(i)
            game.accentDeath(i)
            game.screenEffects.triggerShake(game.camera, 6.0, 0.25)
            playSound(soundDeath)

      # Landing sound and shake
      if result.landedCharacters.len > 0:
        for landed in result.landedCharacters:
          let idx = game.findCharacterIndex(landed.id)
          if idx >= 0:
            game.emitLandingParticles(idx, landed.ability, landed.fallVelocity)
            game.accentLanding(idx)
            game.characters[idx].lastLandingTime = game.elapsedTime
          playLandingSound(landed.fallVelocity, landed.ability)
          # Velocity-scaled landing shake (up to 3px/0.15s)
          let normV = min(1.0, abs(landed.fallVelocity) / MAX_FALL_SPEED)
          if normV > 0.4:
            let landIntensity = normV * 3.0
            game.screenEffects.triggerShake(game.camera, landIntensity, 0.15)

        # Felix-Ivy graceful landing combo: both land within 0.15s of each other.
        block gracefulLandingCheck:
          var felixIdx = -1
          var ivyIdx = -1
          for i in 0..<game.characters.len:
            if game.characters[i].id == "felix": felixIdx = i
            elif game.characters[i].id == "ivy": ivyIdx = i
          if felixIdx < 0 or ivyIdx < 0:
            break gracefulLandingCheck
          let ft = game.characters[felixIdx].lastLandingTime
          let it = game.characters[ivyIdx].lastLandingTime
          if ft < 0.0 or it < 0.0:
            break gracefulLandingCheck
          if abs(ft - it) > GracefulLandingWindow:
            break gracefulLandingCheck
          # Both must have just landed this frame (at least one in the current batch).
          var justLanded = false
          for landed in result.landedCharacters:
            if landed.id == "felix" or landed.id == "ivy":
              justLanded = true
              break
          if not justLanded:
            break gracefulLandingCheck
          # Grant invulnerability to both.
          game.characters[felixIdx].invulnTimer = GracefulLandingInvuln
          game.characters[ivyIdx].invulnTimer = GracefulLandingInvuln
          # Intensify glows.
          game.characters[felixIdx].glowAlpha = 0.4
          game.characters[felixIdx].glowScale = 2.5
          game.characters[ivyIdx].glowAlpha = 0.4
          game.characters[ivyIdx].glowScale = 2.5
          # Golden ring at midpoint.
          let midX = (characterCenterX(game.characters[felixIdx]) +
                      characterCenterX(game.characters[ivyIdx])) / 2.0
          let midY = (characterCenterY(game.characters[felixIdx]) +
                      characterCenterY(game.characters[ivyIdx])) / 2.0
          game.particles.emitGracefulLandingRing(midX, midY)
          # Harmonic chime.
          playSound(soundGracefulLanding)
          # Reset landing times to prevent re-triggering.
          game.characters[felixIdx].lastLandingTime = -1.0
          game.characters[ivyIdx].lastLandingTime = -1.0

      # Mark exits — play chime when a character newly reaches their exit
      for i in 0..<game.characters.len:
        let wasAtExit = game.characters[i].atExit
        game.characters[i].atExit = game.characters[i].id in result.exitedCharacters
        if game.characters[i].atExit and not wasAtExit:
          game.emitExitParticles(i)
          playSound(soundExitReached)

      # Wall-slide sparks for Cara
      for i in 0..<game.characters.len:
        var c = game.characters[i]
        # wallSliding requires: airborne, touching wall, holding input toward wall
        c.wallSliding = c.wallTouching and not c.grounded and (
          (c.wallTouchDir == -1 and game.rightHeld) or
          (c.wallTouchDir == 1 and game.leftHeld))
        if c.wallSliding:
          let wallOnRight = c.wallTouchDir == -1
          let sparkX = if wallOnRight: c.x + float(c.width) else: c.x
          game.particles.emitWallSpark(sparkX, c.y, float(c.height), wallOnRight)
        game.characters[i] = c

      # Luca glide shimmer trail — emit while airborne, falling, and jump held
      block glideShimmer:
        for i in 0..<game.characters.len:
          let c = game.characters[i]
          if c.ability == floatAbility and not c.grounded and c.vy > 0.0 and game.jumpPressed:
            game.glideShimmerTimer -= scaledDt
            if game.glideShimmerTimer <= 0.0:
              let shimmerX = c.x + float(c.width) / 2.0
              let shimmerY = c.y
              game.particles.emitGlideShimmer(shimmerX, shimmerY, c.color, game.elapsedTime)
              game.glideShimmerTimer = GlideShimmerInterval
            break glideShimmer
        game.glideShimmerTimer = 0.0

      # Button activation shimmer and rumble — emit on false→true edge
      for b in game.currentLevelState.buttons:
        if b.active and not b.prevActive:
          let cx = b.x + b.width * 0.5
          let cy = b.y + b.height * 0.5
          let buttonColor: Color = (r: 255'u8, g: 255'u8, b: 80'u8)
          game.particles.emitButtonShimmer(cx, cy, buttonColor)
          game.screenEffects.triggerShake(game.camera, 1.0, 0.08)

      # Exit beckoning particles — continuous emission per exit
      if game.exitEmitTimers.len < level.exits.len:
        game.exitEmitTimers = newSeq[float](level.exits.len)
      for ei in 0..<level.exits.len:
        let e = level.exits[ei]
        let ecx = e.x + e.width * 0.5
        let ecy = e.y + e.height * 0.5
        var near = false
        for c in game.characters:
          let dx = characterCenterX(c) - ecx
          let dy = characterCenterY(c) - ecy
          if sqrt(dx * dx + dy * dy) < 100.0:
            near = true
            break
        let interval = if near: 0.15 else: 0.3
        game.exitEmitTimers[ei] += scaledDt
        if game.exitEmitTimers[ei] >= interval:
          game.exitEmitTimers[ei] -= interval
          var exitColor: Color = (r: 128'u8, g: 128'u8, b: 128'u8)
          for ci, charId in level.characters:
            if charId == e.characterId:
              exitColor = CHAR_COLORS[game.characters[ci].colorIndex mod 6]
              break
          game.particles.emitExitBeckoning(e.x, e.y, e.width, e.height, exitColor)

      # Secret orb ambient sparkle emission
      if not game.secretCollected:
        let sc = level.starChallenge
        if sc.secretX != 0.0 or sc.secretY != 0.0:
          if rand(60) < 2:
            let orbSparkleColor: Color = (r: 255'u8, g: 255'u8, b: 255'u8)
            game.particles.emitSparkle(sc.secretX, sc.secretY, orbSparkleColor)

      # Secret collectible overlap check
      if not game.secretCollected:
        let sc = level.starChallenge
        if sc.secretX != 0.0 or sc.secretY != 0.0:
          let secretRadius = 8.0
          for c in game.characters:
            if c.isDying() or c.isRespawning():
              continue
            let cx = c.x + float(c.width) * 0.5
            let cy = c.y + float(c.height) * 0.5
            let dx = cx - sc.secretX
            let dy = cy - sc.secretY
            if dx * dx + dy * dy < (secretRadius + float(c.width) * 0.5) * (secretRadius + float(c.width) * 0.5):
              game.secretCollected = true
              game.particles.emitExit(sc.secretX, sc.secretY,
                  (r: 255'u8, g: 245'u8, b: 157'u8))
              playSound(soundExitReached)
              break

      # Combo cooldown decrement.
      if game.comboCooldown > 0.0:
        game.comboCooldown -= scaledDt
        if game.comboCooldown < 0.0:
          game.comboCooldown = 0.0
          game.comboActive = false

      # Combo-ready indicator particles (2 per second between valid pairs).
      if game.activeCharacterIndex < game.characters.len:
        let partnerIdx = findComboPartner(game.characters, game.activeCharacterIndex)
        if partnerIdx >= 0 and game.comboCooldown <= 0.0:
          game.comboReadyTimer += scaledDt
          if game.comboReadyTimer >= 0.5:
            game.comboReadyTimer -= 0.5
            let ac = game.characters[game.activeCharacterIndex]
            let pc = game.characters[partnerIdx]
            let midX = (characterCenterX(ac) + characterCenterX(pc)) / 2.0
            let midY = (characterCenterY(ac) + characterCenterY(pc)) / 2.0
            let c1 = CHAR_COLORS[ac.colorIndex mod 6]
            let c2 = CHAR_COLORS[pc.colorIndex mod 6]
            game.particles.emitComboReady(midX, midY, c1, c2)
        else:
          game.comboReadyTimer = 0.0

      # Buffered jump: if the active character landed this frame, spend the buffer immediately.
      if game.activeCharacterIndex < game.characters.len and
         game.characters[game.activeCharacterIndex].jumpBufferTimer > 0.0 and
         attemptCharacterJump(game.characters[game.activeCharacterIndex]):
        game.emitJumpParticles(game.activeCharacterIndex)
        game.accentJump()
        let ci = game.activeCharacterIndex
        if game.characters[ci].ability == doubleJump and game.characters[ci].jumpCount >= 2:
          playSound(soundJumpPipDouble)
        else:
          playSound(CharJumpSounds[ci])

      # Scripted emotional moments
      checkScriptedMoments(game)

      # Check win — all characters at their exits
      if game.characters.len > 0:
        var allAtExit = true
        for c in game.characters:
          if not c.atExit:
            allAtExit = false
            break
        if allAtExit and game.state == playing:
          game.accentLevelComplete()
          game.state = levelWin
          game.levelWinTimer = 0.0
          game.dynamicTimeScale = 0.5
          game.slowMotionTimer = 0.4
          # Award stars
          let elapsed = game.elapsedTime - game.levelStartTime
          let sc = level.starChallenge
          if sc.timeTarget > 0.0 and elapsed <= sc.timeTarget:
            game.earnedStars[0] = true
          if not game.deathOccurred:
            game.earnedStars[1] = true
          if game.secretCollected:
            game.earnedStars[2] = true
          # Save star progress
          var saveData = loadSave()
          if not saveData.levelStars.hasKey(game.currentLevel):
            saveData.levelStars[game.currentLevel] = [false, false, false]
          for si in 0 ..< 3:
            if game.earnedStars[si]:
              saveData.levelStars[game.currentLevel][si] = true
          writeSave(saveData)
          playLevelCompleteFanfare(actForLevel(game.currentLevel))

      # Update camera: overview pan or normal follow.
      if game.camera.isOverviewActive():
        updateOverview(game.camera, level.levelWidth, level.levelHeight, scaledDt)
      elif game.activeCharacterIndex < game.characters.len:
        let ch = game.characters[game.activeCharacterIndex]
        updateCamera(game.camera, ch.x, ch.y, float(ch.width), float(ch.height),
                     ch.vx, ch.vy, ch.facingRight, level.levelWidth,
                     level.levelHeight, scaledDt)

    if not game.gameFrozen:
      # Tick death/respawn timers
      for i in 0..<game.characters.len:
        if game.characters[i].isDying():
          # Track flash count based on elapsed time (50ms on, 50ms off = 100ms per flash)
          let elapsed = 0.5 - game.characters[i].deathTimer
          game.characters[i].deathFlashCount = min(3, int(elapsed / 0.1))
          game.characters[i].deathTimer -= scaledDt
          if game.characters[i].deathTimer <= 0.0:
            game.characters[i].deathTimer = 0.0
            game.characters[i].dead = false
            game.characters[i].x = game.characters[i].spawnX
            game.characters[i].y = game.characters[i].spawnY
            game.characters[i].vx = 0
            game.characters[i].vy = 0
            game.characters[i].respawnTimer = 0.3
            game.emitRespawnParticles(i)
            if i == game.activeCharacterIndex:
              game.camera.hold(0.10)
              game.queueCameraSnapToCharacter(i)
        elif game.characters[i].isRespawning():
          game.characters[i].respawnTimer -= scaledDt
          if game.characters[i].respawnTimer <= 0.0:
            game.characters[i].respawnTimer = 0.0

      # Update animations for all characters
      for i in 0..<game.characters.len:
        updateAnimation(game.characters[i], scaledDt)
        if game.characters[i].jumpBufferTimer > 0.0:
          game.characters[i].jumpBufferTimer =
            max(0.0, game.characters[i].jumpBufferTimer - scaledDt)

    # Footstep sounds for the active character.
    block footsteps:
      let ai = game.activeCharacterIndex
      let speed = abs(game.characters[ai].vx)
      if game.characters[ai].grounded and speed >= FootstepSpeedThreshold:
        game.characters[ai].footstepTimer -= scaledDt
        if game.characters[ai].footstepTimer <= 0.0:
          playFootstepSound(game.characters[ai].id)
          let maxSpeed = game.characters[ai].moveSpeed()
          let speedT = clamp((speed - FootstepSpeedThreshold) /
                             (maxSpeed - FootstepSpeedThreshold), 0.0, 1.0)
          game.characters[ai].footstepTimer =
            FootstepMaxInterval - (FootstepMaxInterval - FootstepMinInterval) * speedT
      else:
        game.characters[ai].footstepTimer = 0.0

    # Precompute pairwise distances — reused by all proximity systems.
    let n = game.characters.len
    var distMatrix = newSeq[float](n * n)
    for i in 0..<n:
      for j in (i + 1)..<n:
        let ci = game.characters[i]
        let cj = game.characters[j]
        let dx = characterCenterX(cj) - characterCenterX(ci)
        let dy = characterCenterY(cj) - characterCenterY(ci)
        let d = sqrt(dx * dx + dy * dy)
        distMatrix[i * n + j] = d
        distMatrix[j * n + i] = d

    # Character proximity emotional system
    for i in 0..<n:
      if game.characters[i].isDying() or game.characters[i].isRespawning():
        game.characters[i].proximityTarget = -1
        continue

      var nearAny = false
      var closestDist = 1e9
      var closestIdx = -1
      var bestApproach = 0.0

      for j in 0..<n:
        if i == j: continue
        if game.characters[j].isDying() or game.characters[j].isRespawning():
          continue
        let dist = distMatrix[i * n + j]
        if dist < closestDist:
          closestDist = dist
          closestIdx = j

        # Near: build contentment
        if dist < ProximityNear:
          nearAny = true
          game.characters[i].contentment = min(1.0, game.characters[i].contentment + 1.5 * scaledDt)

        # Anticipation: moving toward another character
        if dist > 0.001:
          let dx = characterCenterX(game.characters[j]) - characterCenterX(game.characters[i])
          let dy = characterCenterY(game.characters[j]) - characterCenterY(game.characters[i])
          let dot = game.characters[i].vx * (dx / dist) + game.characters[i].vy * (dy / dist)
          if dot > 0.0:
            bestApproach = max(bestApproach, min(1.0, dot / 150.0))

      # Proximity lean toward nearest character
      if closestIdx >= 0 and closestDist < ProximityNear:
        game.characters[i].proximityTarget = closestIdx
        let clampedDist = max(20.0, closestDist)
        let targetLean = 2.0 * (ProximityNear - clampedDist) / (ProximityNear - 20.0)
        game.characters[i].proximityLean += (targetLean - game.characters[i].proximityLean) * min(1.0, 3.0 * scaledDt)
        # Pupil offset toward proximity target
        let target = game.characters[closestIdx]
        let targetCx = target.x + float(target.width) * 0.5
        let selfCx = game.characters[i].x + float(game.characters[i].width) * 0.5
        let targetPupil = if targetCx > selfCx: 1.0 else: -1.0
        game.characters[i].pupilOffset += (targetPupil - game.characters[i].pupilOffset) * min(1.0, 10.0 * scaledDt)
      else:
        game.characters[i].proximityTarget = -1
        game.characters[i].proximityLean += (0.0 - game.characters[i].proximityLean) * min(1.0, 3.0 * scaledDt)
        # Smooth revert pupil to facing direction over ~0.3s
        let facingPupil = if game.characters[i].lookDir != 0: float(game.characters[i].lookDir)
                          elif game.characters[i].facingRight: 1.0
                          else: -1.0
        game.characters[i].pupilOffset += (facingPupil - game.characters[i].pupilOffset) * min(1.0, 3.3 * scaledDt)

      # Detect new proximity contact — emit sparkle burst at midpoint
      const SparkleCount = 5
      if game.characters[i].proximityTarget >= 0 and
         game.characters[i].prevProximityTarget < 0:
        let other = game.characters[game.characters[i].proximityTarget]
        let midX = (characterCenterX(game.characters[i]) + characterCenterX(other)) / 2.0
        let midY = (characterCenterY(game.characters[i]) + characterCenterY(other)) / 2.0
        let sparkColor: Color = (r: 255'u8, g: 240'u8, b: 180'u8)
        for _ in 0 ..< SparkleCount:
          emitSparkle(game.particles, midX, midY, sparkColor)
      game.characters[i].prevProximityTarget = game.characters[i].proximityTarget

      # Anticipation build/decay
      if bestApproach > 0.0:
        game.characters[i].anticipation = min(1.0, game.characters[i].anticipation + bestApproach * 2.0 * scaledDt)
      else:
        game.characters[i].anticipation = max(0.0, game.characters[i].anticipation - 1.0 * scaledDt)

      # Contentment from exit
      if game.characters[i].atExit:
        game.characters[i].contentment = min(1.0, game.characters[i].contentment + 2.0 * scaledDt)

      # Contentment decay — faster when far from all others
      if not nearAny:
        let rate = if game.characters.len > 1 and closestDist > ProximityFar: 0.8 else: 0.5
        game.characters[i].contentment = max(0.0, game.characters[i].contentment - rate * scaledDt)

    # Proximity glow blending
    block:
      var minDists = newSeq[float](n)
      var nearbyCounts = newSeq[int](n)
      for i in 0..<n:
        minDists[i] = 1e9
        if game.characters[i].isDying() or game.characters[i].isRespawning():
          continue
        for j in 0..<n:
          if i == j: continue
          if game.characters[j].isDying() or game.characters[j].isRespawning():
            continue
          let dist = distMatrix[i * n + j]
          if dist < minDists[i]:
            minDists[i] = dist
          if dist <= ProximityGlowRange:
            nearbyCounts[i] += 1

      # Feed per-character distances to harmonic proximity oscillators.
      for i in 0..<n:
        if game.characters[i].isDying() or game.characters[i].isRespawning():
          setCharacterActive(i, false)
        else:
          setCharacterDistance(i, minDists[i])

      # Full group: all active characters within range of at least one other.
      var fullGroup = true
      var activeCount = 0
      for i in 0..<n:
        if game.characters[i].isDying() or game.characters[i].isRespawning():
          continue
        activeCount += 1
        if nearbyCounts[i] == 0:
          fullGroup = false
      if activeCount < 2:
        fullGroup = false

      # Rising-edge detection: flash when full group forms for the first time.
      if fullGroup and not game.prevFullGroup:
        let warmAmber: Color = (r: 255'u8, g: 220'u8, b: 130'u8)
        game.screenEffects.triggerFlash(warmAmber, 0.35)
      game.prevFullGroup = fullGroup

      let lerpRate = min(1.0, 4.0 * scaledDt)
      for i in 0..<n:
        if game.characters[i].isDying() or game.characters[i].isRespawning():
          continue
        var targetScale: float
        var targetAlpha: float
        if minDists[i] > ProximityGlowRange:
          # Alone: dim and small.
          targetScale = 1.2
          targetAlpha = 0.08
        else:
          # Companion: expand and brighten with closeness.
          let t = 1.0 - minDists[i] / ProximityGlowRange
          targetScale = 1.8 + 1.0 * t
          targetAlpha = 0.15 + 0.10 * t
        var targetGoldMix = 0.0
        if fullGroup:
          targetGoldMix = 0.15
          targetAlpha = min(0.25, targetAlpha * 1.3)
        # Blow-out prevention when more than 3 characters nearby.
        if nearbyCounts[i] > 3:
          targetAlpha = targetAlpha / sqrt(float(nearbyCounts[i]))
        game.characters[i].glowScale += (targetScale - game.characters[i].glowScale) * lerpRate
        game.characters[i].glowAlpha += (targetAlpha - game.characters[i].glowAlpha) * lerpRate
        game.characters[i].glowGoldMix += (targetGoldMix - game.characters[i].glowGoldMix) * lerpRate
        # Isolation timer: increment when no neighbour within ProximityFar, reset on contact.
        if minDists[i] > ProximityFar:
          game.characters[i].isolationTimer += scaledDt
          # Ramp desaturation toward 1.0 over ~10s of isolation.
          let targetSat = min(1.0, game.characters[i].isolationTimer * 0.1)
          game.characters[i].isolationSat += (targetSat - game.characters[i].isolationSat) * 2.0 * scaledDt
        else:
          game.characters[i].isolationTimer = 0.0
          # Bloom back to full colour quickly on reconnect.
          game.characters[i].isolationSat *= max(0.0, 1.0 - 4.0 * scaledDt)

    # Thought bubble system — idle pair proximity triggers.
    if game.thoughtBubble.timer > 0.0:
      game.thoughtBubble.timer -= scaledDt
      if game.thoughtBubble.timer <= 0.0:
        game.thoughtBubble.timer = 0.0
        game.thoughtBubble.text = ""
    else:
      # Check all pairs for idle proximity.
      block findThought:
        for i in 0..<n:
          if game.characters[i].isDying() or game.characters[i].isRespawning():
            continue
          if game.characters[i].idleTimer < 3.0:
            continue
          for j in (i + 1)..<n:
            if game.characters[j].isDying() or game.characters[j].isRespawning():
              continue
            if game.characters[j].idleTimer < 3.0:
              continue
            if distMatrix[i * n + j] > ProximityNear:
              continue
            let pairKey = thoughtPairKey(game.characters[i].id, game.characters[j].id)
            if game.thoughtCooldowns.hasKey(pairKey) and game.thoughtCooldowns[pairKey] > 0.0:
              continue
            let thoughts = thoughtsForPair(pairKey)
            if thoughts.len == 0:
              continue
            let thought = thoughts[rand(thoughts.len - 1)]
            let thinker = if rand(1) == 0: i else: j
            game.thoughtBubble = (text: thought, charIdx: thinker,
                                  timer: 3.5, fadeIn: 0.3, fadeOut: 0.5)
            game.thoughtCooldowns[pairKey] = 15.0
            break findThought

    # Tick thought cooldowns.
    var expiredKeys: seq[string] = @[]
    for key, val in game.thoughtCooldowns.mpairs:
      val -= scaledDt
      if val <= 0.0:
        expiredKeys.add(key)
    for key in expiredKeys:
      game.thoughtCooldowns.del(key)

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

    # Character switch dim timer
    if game.charDimTimer > 0.0:
      game.charDimTimer = max(0.0, game.charDimTimer - scaledDt)

    # Character flash timers (double-jump body flash)
    for fi in 0 ..< game.charFlashTimers.len:
      if game.charFlashTimers[fi] > 0.0:
        game.charFlashTimers[fi] = max(0.0, game.charFlashTimers[fi] - scaledDt)

  of levelWin:
    let isFinale = game.currentLevel == FinalLevel
    # Tick slow-motion beat using real time.
    if game.slowMotionTimer > 0.0:
      game.slowMotionTimer = max(0.0, game.slowMotionTimer - baseDt)
      if game.slowMotionTimer <= 0.0:
        game.dynamicTimeScale = 1.0
        for i in 0 ..< game.characters.len:
          game.characters[i].celebrateTimer = float(i) * 0.1 + 0.001
          if isFinale:
            game.characters[i].celebrateSquash = 0.65
        game.emitCompletionParticles()
        let flashWhite: Color = (r: 255'u8, g: 255'u8, b: 255'u8)
        game.screenEffects.triggerFlash(flashWhite, 0.5)
        playSound(soundTransitionSwoosh)
        if isFinale:
          # Begin finale sequence: extra 2s hold with bounces.
          game.finalePhase = 1
          game.finaleTimer = 0.0
        else:
          transitionColor = CHAR_COLORS[
              game.characters[game.activeCharacterIndex].colorIndex mod 6]
          discard startTween(transitionPool, 0.0, 1.0, 0.4, easeOutCubic,
              proc(v: float) = transitionAlpha = v,
              proc() = transitionPendingNextLevel = true)

    # Finale sequence phases for level 30.
    if isFinale and game.finalePhase > 0:
      game.finaleTimer += scaledDt
      case game.finalePhase
      of 1:
        # Extra hold with happy bounces (2s).
        if game.finaleTimer >= 2.0:
          game.finalePhase = 2
          game.finaleTimer = 0.0
          game.finaleNarrationRevealed = 0
      of 2:
        # Typewriter narration at 20 chars/sec.
        let target = int(game.finaleTimer * FinaleNarrationSpeed)
        game.finaleNarrationRevealed = min(target, FinaleNarrationText.len)
        if game.finaleNarrationRevealed >= FinaleNarrationText.len:
          game.finalePhase = 3
          game.finaleTimer = 0.0
      of 3:
        # Post-narration hold (1s).
        if game.finaleTimer >= 1.0:
          game.finalePhase = 4
          game.finaleTimer = 0.0
          # Warm white fade over 2s.
          transitionColor = (r: 255'u8, g: 250'u8, b: 240'u8)
          discard startTween(transitionPool, 0.0, 1.0, 2.0, easeOutCubic,
              proc(v: float) = transitionAlpha = v,
              proc() =
                transitionPendingNextLevel = false)
      of 4:
        # Fading to warm white (2s tween running).
        if game.finaleTimer >= 2.0:
          game.finalePhase = 0
          game.enterCredits()
      else:
        discard

    game.levelWinTimer += scaledDt
    for i in 0 ..< game.characters.len:
      game.characters[i].updateAnimation(scaledDt)
    if game.currentLevel >= 0 and game.currentLevel < allLevels.len and
       game.activeCharacterIndex < game.characters.len:
      let ch = game.characters[game.activeCharacterIndex]
      let level = game.currentLevelState
      updateCamera(game.camera, ch.x, ch.y, float(ch.width), float(ch.height),
                   ch.vx, ch.vy, ch.facingRight, level.levelWidth,
                   level.levelHeight, scaledDt)

  of actTitle:
    let prevT = game.actTitleTimer
    game.actTitleTimer += scaledDt
    # At the 0.8s mark the stinger completes; resume ambient with new palette.
    if prevT < 0.8 and game.actTitleTimer >= 0.8:
      let ai = actForLevel(game.actTitleTarget)
      if ai >= 0:
        setActPalette(ActPalettes[clamp(ai, 0, ActPalettes.high)])
        fadeInAmbient(0.5)
    if game.actTitleTimer >= ActTitleDuration:
      game.loadLevel(game.actTitleTarget)
      game.state = playing

  of storyBeat:
    game.storyBeatTimer += scaledDt
    if game.storyBeatTimer >= 0.025:
      game.storyBeatTimer -= 0.025
      if game.storyBeatRevealed < game.storyBeatText.len:
        game.storyBeatRevealed += 1

  of credits:
    game.creditsTimer += scaledDt

  of settings:
    game.updateMenuBgChars(scaledDt)

  of levelSelect:
    if game.levelSelectRejectTimer > 0:
      game.levelSelectRejectTimer = max(0.0, game.levelSelectRejectTimer - scaledDt)
    game.updateMenuBgChars(scaledDt)

  of won:
    game.wonTimer += scaledDt
    if not game.wonThankYouShown and game.wonTimer >= 5.0:
      game.wonThankYouShown = true
    game.particles.update(scaledDt)
    if rand(1.0) < 0.3:
      game.particles.emitWinSparkle()
    game.updateMenuBgChars(scaledDt)

  else:
    discard

  updateTweens(transitionPool, scaledDt)
  if transitionPendingNextLevel:
    transitionPendingNextLevel = false
    game.nextLevel()
    discard startTween(transitionPool, 1.0, 0.0, 0.4, easeOutCubic,
        proc(v: float) = transitionAlpha = v)

  game.camera.updateShake(scaledDt)
  game.screenEffects.updateScreenEffects(scaledDt)
  game.particles.update(scaledDt)
