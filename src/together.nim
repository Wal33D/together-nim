## Together - A narrative puzzle-platformer
## Platform layer: Windy + Boxy + Silky.

import windy
import opengl
import times
import math
import build_info
import game
import constants
import systems/renderer
import systems/render_backend
import systems/audio
import systems/gamepad
import systems/save
import systems/ui

when defined(macosx):
  type CGLContextObj = pointer
  proc CGLGetCurrentContext(): CGLContextObj
    {.importc, dynlib: "/System/Library/Frameworks/OpenGL.framework/OpenGL".}
  proc CGLSetParameter(ctx: CGLContextObj, pname: int32, params: ptr int32): int32
    {.importc, dynlib: "/System/Library/Frameworks/OpenGL.framework/OpenGL".}
  const KCGLCPSwapInterval: int32 = 222
elif defined(windows):
  var wglSwapIntervalEXTProc: proc(interval: int32): int32 {.stdcall.}
elif defined(linux):
  proc glXSwapIntervalMESA(interval: int32) {.importc, dynlib: "libGL.so".}

proc setVSync(enabled: bool) =
  ## Set the OpenGL swap interval for VSync control.
  let interval: int32 = if enabled: 1 else: 0
  when defined(macosx):
    let ctx = CGLGetCurrentContext()
    if ctx != nil:
      var val = interval
      discard CGLSetParameter(ctx, KCGLCPSwapInterval, val.addr)
  elif defined(windows):
    if wglSwapIntervalEXTProc != nil:
      discard wglSwapIntervalEXTProc(interval)
  elif defined(linux):
    glXSwapIntervalMESA(interval)
  else:
    discard

type
  WindowModeState = object
    pseudoFullscreen: bool
    hasWindowedBounds: bool
    windowedPos: IVec2
    windowedSize: IVec2
    windowedStyle: WindowStyle

proc primaryScreenSize(window: Window): IVec2 =
  let screens = getScreens()
  if screens.len == 0:
    return window.size

  var selected = screens[0]
  for screen in screens:
    if screen.primary:
      selected = screen
      break

  let scale = max(window.contentScale, 1.0'f32)
  let logicalSize = selected.size
  ivec2(
    round(logicalSize.x.float32 * scale).int32,
    round(logicalSize.y.float32 * scale).int32
  )

proc defaultWindowSize(window: Window): IVec2 =
  let scale = max(window.contentScale, 1.0'f32)
  ivec2(
    round(DEFAULT_WINDOW_WIDTH.float32 * scale).int32,
    round(DEFAULT_WINDOW_HEIGHT.float32 * scale).int32
  )

proc setFullscreen(window: Window, state: var WindowModeState, enabled: bool) =
  when defined(macosx):
    if state.pseudoFullscreen == enabled:
      return

    if enabled:
      state.windowedPos = window.pos
      state.windowedSize = window.size
      state.windowedStyle = window.style
      state.hasWindowedBounds = true

      window.style = Undecorated
      window.pos = ivec2(0, 0)
      window.size = window.primaryScreenSize()
    else:
      if state.hasWindowedBounds:
        window.style = state.windowedStyle
        window.size = state.windowedSize
        window.pos = state.windowedPos
      else:
        window.style = DecoratedResizable
        window.size = window.defaultWindowSize()

      state.hasWindowedBounds = false

    state.pseudoFullscreen = enabled
  else:
    window.fullscreen = enabled

proc applySettingsChange(window: Window, game: var Game,
                          windowMode: var WindowModeState) =
  ## Apply the change for the currently focused settings option.
  case game.settingsCursor
  of 0:
    # Window size — already cycled by caller; apply the preset.
    let preset = WindowPresets[game.settingsWindowPreset]
    let scale = max(window.contentScale, 1.0'f32)
    window.size = ivec2(
      round(preset.w.float32 * scale).int32,
      round(preset.h.float32 * scale).int32
    )
    saveWindowPreset(game.settingsWindowPreset)
    playSound(soundMenuHover)
  of 1:
    # Fullscreen toggle.
    game.fullscreenEnabled = not game.fullscreenEnabled
    window.setFullscreen(windowMode, game.fullscreenEnabled)
    saveFullscreen(game.fullscreenEnabled)
    playSound(soundMenuHover)
  of 2:
    # VSync toggle.
    game.vsyncEnabled = not game.vsyncEnabled
    setVSync(game.vsyncEnabled)
    saveVsync(game.vsyncEnabled)
    playSound(soundMenuHover)
  of 3:
    discard  # Volume is handled directly by adjustVolume.
  else:
    discard

const
  VolumeStep = 0.1

proc adjustVolume(delta: float) =
  ## Nudge master volume by delta, clamp, persist, and play feedback.
  let vol = clamp(getMasterVolume() + delta, 0.0, 1.0)
  setMasterVolume(vol)
  saveMasterVolume(vol)
  playSound(soundMenuHover)

proc handleKeyboardInput(window: Window, game: var Game, ui: UiRenderer,
                          windowMode: var WindowModeState) =
  case game.state
  of menu:
    if window.buttonPressed[KeyLeft] or window.buttonPressed[KeyA] or padLeftPressed:
      ui.cycleMenuSpotlight(-1)
    if window.buttonPressed[KeyRight] or window.buttonPressed[KeyD] or padRightPressed:
      ui.cycleMenuSpotlight(1)
    if window.buttonPressed[KeyUp] or window.buttonPressed[KeyW] or padUpPressed:
      cycleMenuCursor(-1)
    if window.buttonPressed[KeyDown] or window.buttonPressed[KeyS] or padDownPressed:
      cycleMenuCursor(1)
    if window.buttonPressed[KeyEnter] or window.buttonPressed[KeySpace]:
      ui.activateFocusedAction(game)
    if window.buttonPressed[KeyEscape]:
      game.openSettings()
      playSound(soundMenuSelect)
    return
  of paused:
    if window.buttonPressed[KeyLeft] or window.buttonPressed[KeyA] or
       window.buttonPressed[KeyUp] or window.buttonPressed[KeyW]:
      ui.cyclePauseSelection(-1)
    if window.buttonPressed[KeyRight] or window.buttonPressed[KeyD] or
       window.buttonPressed[KeyDown] or window.buttonPressed[KeyS]:
      ui.cyclePauseSelection(1)
    if window.buttonPressed[KeyEnter] or window.buttonPressed[KeySpace]:
      ui.activateFocusedAction(game)
    if window.buttonPressed[KeyEscape]:
      game.handleKey(KeyEscape)
    return
  of settings:
    if window.buttonPressed[KeyUp] or window.buttonPressed[KeyW]:
      game.cycleSettingsCursor(-1)
    if window.buttonPressed[KeyDown] or window.buttonPressed[KeyS]:
      game.cycleSettingsCursor(1)
    if window.buttonPressed[KeyLeft] or window.buttonPressed[KeyA]:
      case game.settingsCursor
      of 0:
        game.settingsWindowPreset = (game.settingsWindowPreset - 1 + WindowPresets.len) mod WindowPresets.len
        applySettingsChange(window, game, windowMode)
      of 1:
        applySettingsChange(window, game, windowMode)
      of 2:
        applySettingsChange(window, game, windowMode)
      of 3:
        adjustVolume(-VolumeStep)
      else: discard
    if window.buttonPressed[KeyRight] or window.buttonPressed[KeyD]:
      case game.settingsCursor
      of 0:
        game.settingsWindowPreset = (game.settingsWindowPreset + 1) mod WindowPresets.len
        applySettingsChange(window, game, windowMode)
      of 1:
        applySettingsChange(window, game, windowMode)
      of 2:
        applySettingsChange(window, game, windowMode)
      of 3:
        adjustVolume(VolumeStep)
      else: discard
    if window.buttonPressed[KeyEnter] or window.buttonPressed[KeySpace]:
      if game.settingsCursor == 4:
        # Back.
        game.state = game.previousState
        playSound(soundMenuBack)
      elif game.settingsCursor >= 0 and game.settingsCursor <= 2:
        applySettingsChange(window, game, windowMode)
    if window.buttonPressed[KeyEscape]:
      game.state = game.previousState
      playSound(soundMenuBack)
    return
  of levelSelect:
    if window.buttonPressed[KeyUp] or window.buttonPressed[KeyW] or padUpPressed:
      game.levelSelectRow = (game.levelSelectRow - 1 + 5) mod 5
      playSound(soundMenuHover)
    if window.buttonPressed[KeyDown] or window.buttonPressed[KeyS] or padDownPressed:
      game.levelSelectRow = (game.levelSelectRow + 1) mod 5
      playSound(soundMenuHover)
    if window.buttonPressed[KeyLeft] or window.buttonPressed[KeyA] or padLeftPressed:
      game.levelSelectCol = (game.levelSelectCol - 1 + 6) mod 6
      playSound(soundMenuHover)
    if window.buttonPressed[KeyRight] or window.buttonPressed[KeyD] or padRightPressed:
      game.levelSelectCol = (game.levelSelectCol + 1) mod 6
      playSound(soundMenuHover)
    if window.buttonPressed[KeyEnter] or window.buttonPressed[KeySpace]:
      game.launchSelectedLevel()
    if window.buttonPressed[KeyEscape]:
      game.state = menu
      playSound(soundMenuBack)
    return
  of actTitle:
    return
  of storyBeat:
    if window.buttonPressed[KeySpace] or window.buttonPressed[KeyEnter]:
      game.handleKey(KeySpace)
    return
  else:
    discard

  game.leftHeld = window.buttonDown[KeyLeft] or window.buttonDown[KeyA]
  game.rightHeld = window.buttonDown[KeyRight] or window.buttonDown[KeyD]

  if window.buttonPressed[KeySpace]:
    game.pressJump()
  if window.buttonReleased[KeySpace]:
    game.releaseJump()

  if window.buttonPressed[Key1] and game.selectActiveCharacter(0):
    playSound(soundCharSwitch)
  if window.buttonPressed[Key2] and game.selectActiveCharacter(1):
    playSound(soundCharSwitch)
  if window.buttonPressed[Key3] and game.selectActiveCharacter(2):
    playSound(soundCharSwitch)
  if window.buttonPressed[Key4] and game.selectActiveCharacter(3):
    playSound(soundCharSwitch)
  if window.buttonPressed[Key5] and game.selectActiveCharacter(4):
    playSound(soundCharSwitch)
  if window.buttonPressed[Key6] and game.selectActiveCharacter(5):
    playSound(soundCharSwitch)

  if window.buttonPressed[KeyEnter]:
    game.handleKey(KeyEnter)
  if window.buttonPressed[KeyEscape]:
    game.handleKey(KeyEscape)
  if window.buttonPressed[KeyR]:
    game.handleKey(KeyR)

proc main() =
  let savedData = loadSave()
  var windowMode = WindowModeState()

  let window = newWindow(
    "Together v" & GameVersion,
    ivec2(DEFAULT_WINDOW_WIDTH, DEFAULT_WINDOW_HEIGHT),
    vsync = true,
    openglVersion = OpenGL4Dot1
  )
  makeContextCurrent(window)
  loadExtensions()

  when defined(windows):
    wglSwapIntervalEXTProc = cast[typeof(wglSwapIntervalEXTProc)](
      wglGetProcAddress("wglSwapIntervalEXT"))

  # Apply saved window preset (clamped to valid range).
  let presetIdx = clamp(savedData.windowPreset, 0, WindowPresets.len - 1)
  let preset = WindowPresets[presetIdx]
  let startScale = max(window.contentScale, 1.0'f32)
  let presetSize = ivec2(
    round(preset.w.float32 * startScale).int32,
    round(preset.h.float32 * startScale).int32
  )
  # Fall back to default if preset exceeds screen.
  let screen = window.primaryScreenSize()
  if presetSize.x > screen.x or presetSize.y > screen.y:
    window.size = window.defaultWindowSize()
  else:
    window.size = presetSize

  if savedData.fullscreen:
    window.setFullscreen(windowMode, true)

  # Apply saved VSync preference.
  if not savedData.vsync:
    setVSync(false)

  initAudio()
  setMasterVolume(savedData.masterVolume)
  openFirstController()

  let renderer = newRenderer()
  let ui = newUiRenderer()
  var g = newGame()
  g.fullscreenEnabled = savedData.fullscreen
  g.vsyncEnabled = savedData.vsync

  g.settingsWindowPreset = presetIdx

  var accumulator = 0.0
  var lastTime = epochTime()

  while not window.closeRequested:
    pollEvents()

    let currentTime = epochTime()
    let frameTime = min(currentTime - lastTime, 0.25)
    lastTime = currentTime
    accumulator += frameTime

    if window.buttonPressed[KeyF11]:
      g.fullscreenEnabled = not g.fullscreenEnabled
      window.setFullscreen(windowMode, g.fullscreenEnabled)
      saveFullscreen(g.fullscreenEnabled)

    handleKeyboardInput(window, g, ui, windowMode)
    pollControllerInput(g)

    if controllerConnected:
      case g.state
      of settings:
        if padUpPressed:
          g.cycleSettingsCursor(-1)
        if padDownPressed:
          g.cycleSettingsCursor(1)
        if padLeftPressed:
          case g.settingsCursor
          of 0:
            g.settingsWindowPreset =
              (g.settingsWindowPreset - 1 + WindowPresets.len) mod WindowPresets.len
            applySettingsChange(window, g, windowMode)
          of 1, 2:
            applySettingsChange(window, g, windowMode)
          of 3:
            adjustVolume(-VolumeStep)
          else: discard
        if padRightPressed:
          case g.settingsCursor
          of 0:
            g.settingsWindowPreset =
              (g.settingsWindowPreset + 1) mod WindowPresets.len
            applySettingsChange(window, g, windowMode)
          of 1, 2:
            applySettingsChange(window, g, windowMode)
          of 3:
            adjustVolume(VolumeStep)
          else: discard
        if padConfirmPressed:
          if g.settingsCursor == 4:
            g.state = g.previousState
            playSound(soundMenuBack)
          elif g.settingsCursor >= 0 and g.settingsCursor <= 2:
            applySettingsChange(window, g, windowMode)
        if padBackPressed:
          g.state = g.previousState
          playSound(soundMenuBack)
      of paused:
        if padUpPressed:
          ui.cyclePauseSelection(-1)
        if padDownPressed:
          ui.cyclePauseSelection(1)
        if padConfirmPressed:
          ui.activateFocusedAction(g)
      else:
        discard

    if g.pendingSettingsApply:
      g.pendingSettingsApply = false
      applySettingsChange(window, g, windowMode)

    while accumulator >= FIXED_TIMESTEP:
      g.update(FIXED_TIMESTEP)
      accumulator -= FIXED_TIMESTEP

    let frameSize = window.size
    if frameSize.x <= 0 or frameSize.y <= 0:
      continue

    renderer.beginFrame(frameSize.x.int, frameSize.y.int)
    renderGame(renderer, g)
    renderer.endFrame()
    renderer.beginOverlay()
    ui.renderOverlay(window, g, frameSize)
    renderer.endOverlay()
    window.swapBuffers()

  closeController()
  shutdownAudio()
  window.close()

when isMainModule:
  main()
