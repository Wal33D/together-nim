## Together - A narrative puzzle-platformer
## Platform layer: Windy + Boxy + Silky, with SDL2 for audio/controllers.

import sdl2
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

type
  WindowModeState = object
    pseudoFullscreen: bool
    hasWindowedBounds: bool
    windowedPos: IVec2
    windowedSize: IVec2
    windowedStyle: WindowStyle

proc handleKeyboardInput(window: Window, game: var Game, ui: UiRenderer) =
  case game.state
  of menu:
    if window.buttonPressed[KeyLeft] or window.buttonPressed[KeyA]:
      ui.cycleMenuSpotlight(-1)
      playSound(soundCharSwitch)
    if window.buttonPressed[KeyRight] or window.buttonPressed[KeyD]:
      ui.cycleMenuSpotlight(1)
      playSound(soundCharSwitch)
    if window.buttonPressed[KeyEnter] or window.buttonPressed[KeySpace]:
      ui.activateFocusedAction(game)
    return
  of paused:
    if window.buttonPressed[KeyLeft] or window.buttonPressed[KeyA] or
       window.buttonPressed[KeyUp] or window.buttonPressed[KeyW]:
      ui.cyclePauseSelection(-1)
      playSound(soundCharSwitch)
    if window.buttonPressed[KeyRight] or window.buttonPressed[KeyD] or
       window.buttonPressed[KeyDown] or window.buttonPressed[KeyS]:
      ui.cyclePauseSelection(1)
      playSound(soundCharSwitch)
    if window.buttonPressed[KeyEnter] or window.buttonPressed[KeySpace]:
      ui.activateFocusedAction(game)
    if window.buttonPressed[KeyEscape]:
      game.handleKey(KeyEscape)
    return
  of actTitle:
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

proc main() =
  if sdl2.init(INIT_AUDIO or INIT_GAMECONTROLLER) != SdlSuccess:
    echo "SDL2 init failed: ", sdl2.getError()
    quit(1)

  var fullscreenEnabled = loadSave().fullscreen
  var windowMode = WindowModeState()

  let window = newWindow(
    "Together v" & GameVersion,
    ivec2(DEFAULT_WINDOW_WIDTH, DEFAULT_WINDOW_HEIGHT),
    vsync = true,
    openglVersion = OpenGL4Dot1
  )
  makeContextCurrent(window)
  loadExtensions()

  if not fullscreenEnabled:
    window.size = window.defaultWindowSize()

  if fullscreenEnabled:
    window.setFullscreen(windowMode, true)

  initAudio()
  openFirstController()

  let renderer = newRenderer()
  let ui = newUiRenderer()
  var g = newGame()
  var accumulator = 0.0
  var lastTime = epochTime()

  while not window.closeRequested:
    pollEvents()

    let currentTime = epochTime()
    let frameTime = min(currentTime - lastTime, 0.25)
    lastTime = currentTime
    accumulator += frameTime

    if window.buttonPressed[KeyF11]:
      fullscreenEnabled = not fullscreenEnabled
      window.setFullscreen(windowMode, fullscreenEnabled)
      saveFullscreen(fullscreenEnabled)

    handleKeyboardInput(window, g, ui)
    pollControllerInput(g)

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
  sdl2.quit()

when isMainModule:
  main()
