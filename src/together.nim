## Together - A narrative puzzle-platformer
## Rebuilt in Nim with SDL2

import sdl2

proc main() =
  echo "Together - starting up..."

  if sdl2.init(INIT_VIDEO or INIT_AUDIO) != SdlSuccess:
    echo "SDL2 init failed: ", sdl2.getError()
    quit(1)

  let window = createWindow(
    "Together",
    SDL_WINDOWPOS_CENTERED,
    SDL_WINDOWPOS_CENTERED,
    1280, 720,
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

  var running = true
  var event = defaultEvent
  while running:
    while pollEvent(event):
      case event.kind
      of QuitEvent:
        running = false
      else:
        discard

    renderer.setDrawColor(26, 26, 46, 255)
    renderer.clear()
    renderer.present()

  renderer.destroy()
  window.destroy()
  sdl2.quit()
  echo "Together - goodbye."

when isMainModule:
  main()
