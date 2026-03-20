## Gamepad/controller support for Together
## Manages SDL2 game controller lifecycle and maps controller input to game actions.

import sdl2
import sdl2/gamecontroller
import sdl2/joystick
import "../game"
import "audio"

const
  AXIS_DEADZONE* = 8000'i16  ## Stick deadzone threshold

var
  controller*: GameControllerPtr = nil
  controllerConnected*: bool = false
  ## Track axis-based held state so we can clear on release
  padLeftHeld: bool = false
  padRightHeld: bool = false

proc resetPadState*() =
  ## Reset internal pad held state. Useful for tests.
  padLeftHeld = false
  padRightHeld = false

proc openFirstController*() =
  ## Scan for and open the first available game controller.
  let n = numJoysticks()
  for i in 0.cint ..< n:
    if isGameController(i):
      controller = gameControllerOpen(i)
      if controller != nil:
        controllerConnected = true
        return

proc closeController*() =
  if controller != nil:
    controller.close()
    controller = nil
  controllerConnected = false

proc handleControllerButton*(game: var Game, button: uint8, isDown: bool) =
  ## Map controller buttons to game actions.
  case button.GameControllerButton
  of SDL_CONTROLLER_BUTTON_A:
    if isDown:
      if game.state == playing:
        game.pressJump()
      else:
        case game.state
        of menu:
          game.handleKey(SCANCODE_RETURN)
        of levelWin:
          game.handleKey(SCANCODE_RETURN)
        of credits:
          game.handleKey(SCANCODE_RETURN)
        else:
          discard
    elif game.state == playing:
      game.releaseJump()

  of SDL_CONTROLLER_BUTTON_B:
    # B button = restart level
    if isDown:
      game.handleKey(SCANCODE_R)

  of SDL_CONTROLLER_BUTTON_START:
    # Start = pause/unpause
    if isDown:
      game.handleKey(SCANCODE_ESCAPE)

  of SDL_CONTROLLER_BUTTON_LEFTSHOULDER:
    # LB = previous character
    if isDown and game.state == playing and game.cycleActiveCharacter(-1):
      playSound(soundCharSwitch)

  of SDL_CONTROLLER_BUTTON_RIGHTSHOULDER:
    # RB = next character
    if isDown and game.state == playing and game.cycleActiveCharacter(1):
      playSound(soundCharSwitch)

  of SDL_CONTROLLER_BUTTON_DPAD_LEFT:
    game.leftHeld = isDown
    padLeftHeld = isDown

  of SDL_CONTROLLER_BUTTON_DPAD_RIGHT:
    game.rightHeld = isDown
    padRightHeld = isDown

  else: discard

proc handleControllerAxis*(game: var Game, axis: uint8, value: int16) =
  ## Map left stick X axis to left/right movement.
  if axis == SDL_CONTROLLER_AXIS_LEFTX.uint8:
    let newLeft = value < -AXIS_DEADZONE
    let newRight = value > AXIS_DEADZONE
    # Only update held state from stick if d-pad isn't overriding
    if not padLeftHeld:
      game.leftHeld = newLeft
    if not padRightHeld:
      game.rightHeld = newRight

proc handleControllerDevice*(game: var Game, event: Event) =
  ## Handle controller connect/disconnect events.
  case event.kind
  of ControllerDeviceAdded:
    if not controllerConnected:
      let idx = event.cdevice.which
      if isGameController(idx):
        controller = gameControllerOpen(idx)
        if controller != nil:
          controllerConnected = true
  of ControllerDeviceRemoved:
    if controllerConnected and controller != nil:
      controller.close()
      controller = nil
      controllerConnected = false
      # Clear any held gamepad state so character stops moving
      padLeftHeld = false
      padRightHeld = false
      game.leftHeld = false
      game.rightHeld = false
  else: discard
