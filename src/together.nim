## Together - A narrative puzzle-platformer
## Rebuilt in Nim with SDL2

import sdl2
import opengl
import times
import build_info
import game
import constants
import systems/renderer
import systems/render_backend
import systems/input
import systems/audio
import systems/gamepad
import systems/save

proc SDL_SetWindowFullscreen(window: WindowPtr, flags: uint32): cint {.importc: "SDL_SetWindowFullscreen", dynlib: "libSDL2.dylib".}

proc setWindowFullscreen(window: WindowPtr, fullscreen: bool): bool =
  let flags = if fullscreen: SDL_WINDOW_FULLSCREEN_DESKTOP.uint32 else: 0'u32
  result = SDL_SetWindowFullscreen(window, flags) == 0
  if not result:
    echo "Fullscreen toggle failed: ", sdl2.getError()

proc main() =
  if sdl2.init(INIT_VIDEO or INIT_AUDIO or INIT_GAMECONTROLLER) != SdlSuccess:
    echo "SDL2 init failed: ", sdl2.getError()
    quit(1)

  var fullscreenEnabled = loadSave().fullscreen

  discard glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4)
  discard glSetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1)
  discard glSetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE)

  let window = createWindow(
    ("Together v" & GameVersion).cstring,
    SDL_WINDOWPOS_CENTERED,
    SDL_WINDOWPOS_CENTERED,
    DEFAULT_WIDTH.cint, DEFAULT_HEIGHT.cint,
    SDL_WINDOW_SHOWN or SDL_WINDOW_OPENGL
  )
  if window == nil:
    echo "Window creation failed: ", sdl2.getError()
    quit(1)

  let glContext = glCreateContext(window)
  if glContext == nil:
    echo "OpenGL context creation failed: ", sdl2.getError()
    quit(1)

  discard glMakeCurrent(window, glContext)
  loadExtensions()
  discard glSetSwapInterval(1)

  if fullscreenEnabled:
    discard setWindowFullscreen(window, true)

  initAudio()
  openFirstController()

  let renderer = newRenderer()
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
        if event.kind == KeyDown and not event.key.repeat and event.key.keysym.scancode.cint == SCANCODE_F11:
          let desired = not fullscreenEnabled
          if setWindowFullscreen(window, desired):
            fullscreenEnabled = desired
            saveFullscreen(fullscreenEnabled)
        else:
          g.handleInput(event)
      of ControllerButtonDown, ControllerButtonUp:
        let isDown = event.kind == ControllerButtonDown
        g.handleControllerButton(event.cbutton.button, isDown)
      of ControllerAxisMotion:
        g.handleControllerAxis(event.caxis.axis, event.caxis.value)
      of ControllerDeviceAdded, ControllerDeviceRemoved:
        g.handleControllerDevice(event)
      else:
        discard

    while accumulator >= FIXED_TIMESTEP:
      g.update(FIXED_TIMESTEP)
      accumulator -= FIXED_TIMESTEP

    var drawableW, drawableH: cint
    glGetDrawableSize(window, drawableW, drawableH)
    renderer.beginFrame(drawableW.int, drawableH.int)
    renderGame(renderer, g)
    renderer.endFrame()
    glSwapWindow(window)

  closeController()
  shutdownAudio()
  glDeleteContext(glContext)
  window.destroy()
  sdl2.quit()

when isMainModule:
  main()
