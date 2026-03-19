## Together - A narrative puzzle-platformer
## Rebuilt in Nim with SDL2

import sdl2
import times
import game
import constants
import systems/renderer

proc main() =
  echo "Together - starting up..."

  if sdl2.init(INIT_VIDEO or INIT_AUDIO) != SdlSuccess:
    echo "SDL2 init failed: ", sdl2.getError()
    quit(1)

  let window = createWindow(
    "Together",
    SDL_WINDOWPOS_CENTERED,
    SDL_WINDOWPOS_CENTERED,
    DEFAULT_WIDTH, DEFAULT_HEIGHT,
    SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE
  )
  if window == nil:
    echo "Window creation failed: ", sdl2.getError()
    quit(1)

  let renderer = createRenderer(window, -1,
    Renderer_Accelerated or Renderer_PresentVsync)
  if renderer == nil:
    echo "Renderer creation failed: ", sdl2.getError()
    quit(1)

  echo "Together is running. Close the window to exit."

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
        g.handleKey(event.key.keysym.scancode.cint)
      else:
        discard

    while accumulator >= FIXED_TIMESTEP:
      g.update(FIXED_TIMESTEP)
      accumulator -= FIXED_TIMESTEP

    renderGame(renderer, g)
    renderer.present()

  renderer.destroy()
  window.destroy()
  sdl2.quit()
  echo "Together - goodbye."

when isMainModule:
  main()
