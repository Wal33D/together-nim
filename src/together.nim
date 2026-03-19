## Together - A narrative puzzle-platformer
## Rebuilt in Nim with SDL2

import sdl2
import times
import game
import constants
import systems/renderer
import systems/input
import systems/audio

proc main() =
  if sdl2.init(INIT_VIDEO or INIT_AUDIO) != SdlSuccess:
    echo "SDL2 init failed: ", sdl2.getError()
    quit(1)

  let window = createWindow(
    "Together",
    SDL_WINDOWPOS_CENTERED,
    SDL_WINDOWPOS_CENTERED,
    DEFAULT_WIDTH.cint, DEFAULT_HEIGHT.cint,
    SDL_WINDOW_SHOWN
  )
  if window == nil:
    echo "Window creation failed: ", sdl2.getError()
    quit(1)

  let sdlRenderer = createRenderer(window, -1,
    Renderer_Accelerated or Renderer_PresentVsync)
  if sdlRenderer == nil:
    echo "Renderer creation failed: ", sdl2.getError()
    quit(1)

  # Enable alpha blending
  sdlRenderer.setDrawBlendMode(BlendMode_Blend)

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
      of KeyDown, KeyUp:
        g.handleInput(event)
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
