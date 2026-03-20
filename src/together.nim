## Together - A narrative puzzle-platformer
## Platform layer: Windy + Boxy + Silky, with SDL2 for audio/controllers.

import sdl2
import windy
import opengl
import times
import build_info
import game
import constants
import systems/renderer
import systems/render_backend
import systems/audio
import systems/gamepad
import systems/save
import systems/ui

proc handleKeyboardInput(window: Window, game: var Game) =
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
    game.handleKey(SCANCODE_RETURN)
  if window.buttonPressed[KeyEscape]:
    game.handleKey(SCANCODE_ESCAPE)
  if window.buttonPressed[KeyR]:
    game.handleKey(SCANCODE_R)

proc main() =
  if sdl2.init(INIT_AUDIO or INIT_GAMECONTROLLER) != SdlSuccess:
    echo "SDL2 init failed: ", sdl2.getError()
    quit(1)

  var fullscreenEnabled = loadSave().fullscreen

  let window = newWindow(
    "Together v" & GameVersion,
    ivec2(DEFAULT_WIDTH, DEFAULT_HEIGHT),
    vsync = true,
    openglVersion = OpenGL4Dot1
  )
  makeContextCurrent(window)
  loadExtensions()

  if fullscreenEnabled:
    window.fullscreen = true

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
      window.fullscreen = fullscreenEnabled
      saveFullscreen(fullscreenEnabled)

    handleKeyboardInput(window, g)
    pollControllerInput(g)

    while accumulator >= FIXED_TIMESTEP:
      g.update(FIXED_TIMESTEP)
      accumulator -= FIXED_TIMESTEP

    let frameSize = window.size
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
