## Together - A narrative puzzle-platformer
## Rebuilt in Nim with SDL2

import sdl2
import times
import game
import constants
import systems/renderer
import systems/input
import systems/audio
import systems/save

proc main() =
  if sdl2.init(INIT_VIDEO or INIT_AUDIO) != SdlSuccess:
    echo "SDL2 init failed: ", sdl2.getError()
    quit(1)

  var saveData = loadSave()

  let window = createWindow(
    "Together",
    SDL_WINDOWPOS_CENTERED,
    SDL_WINDOWPOS_CENTERED,
    DEFAULT_WIDTH.cint, DEFAULT_HEIGHT.cint,
    SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE
  )
  if window == nil:
    echo "Window creation failed: ", sdl2.getError()
    quit(1)

  let sdlRenderer = createRenderer(window, -1,
    Renderer_Accelerated or Renderer_PresentVsync)
  if sdlRenderer == nil:
    echo "Renderer creation failed: ", sdl2.getError()
    quit(1)

  # Logical size maintains 800x500 aspect ratio at any window/fullscreen size
  discard sdlRenderer.setLogicalSize(DEFAULT_WIDTH.cint, DEFAULT_HEIGHT.cint)

  # Enable alpha blending
  sdlRenderer.setDrawBlendMode(BlendMode_Blend)

  # Apply saved fullscreen preference
  var isFullscreen = saveData.fullscreen
  if isFullscreen:
    discard window.setFullscreen(SDL_WINDOW_FULLSCREEN_DESKTOP)

  initAudio()

  var g = newGame()
  var running = true
  var event = defaultEvent
  var accumulator = 0.0
  var lastTime = epochTime()

  while running:
    let currentTime = epochTime()
    let frameTime = min(currentTime - lastTime, 0.25)
    lastTime = currentTime
    accumulator += frameTime

    while pollEvent(event):
      case event.kind
      of QuitEvent:
        running = false
      of KeyDown:
        let scancode = event.key.keysym.scancode.cint
        let mods = event.key.keysym.modstate.int
        # F11 or Alt+Enter toggles fullscreen
        if scancode == SCANCODE_F11 or
           (scancode == SCANCODE_RETURN and (mods and 0x0300) != 0):
          isFullscreen = not isFullscreen
          if isFullscreen:
            discard window.setFullscreen(SDL_WINDOW_FULLSCREEN_DESKTOP)
          else:
            discard window.setFullscreen(0)
          saveData.fullscreen = isFullscreen
          writeSave(saveData)
        else:
          g.handleInput(event)
      of KeyUp:
        g.handleInput(event)
      of WindowEvent:
        discard  # SDL_RenderSetLogicalSize handles resize scaling automatically
      else:
        discard

    while accumulator >= FIXED_TIMESTEP:
      g.update(FIXED_TIMESTEP)
      accumulator -= FIXED_TIMESTEP

    renderGame(sdlRenderer, g)
    sdlRenderer.present()

  shutdownAudio()
  sdlRenderer.destroy()
  window.destroy()
  sdl2.quit()

when isMainModule:
  main()
