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
  ## Track the current directional sources separately so d-pad and stick can
  ## coexist without fighting each other.
  dpadLeftHeld: bool = false
  dpadRightHeld: bool = false
  stickLeftHeld: bool = false
  stickRightHeld: bool = false
  prevButtonA: bool = false
  prevButtonB: bool = false
  prevButtonStart: bool = false
  prevButtonLB: bool = false
  prevButtonRB: bool = false
  prevDpadLeft: bool = false
  prevDpadRight: bool = false
  prevStickLeft: bool = false
  prevStickRight: bool = false

proc resetControllerState() =
  dpadLeftHeld = false
  dpadRightHeld = false
  stickLeftHeld = false
  stickRightHeld = false
  prevButtonA = false
  prevButtonB = false
  prevButtonStart = false
  prevButtonLB = false
  prevButtonRB = false
  prevDpadLeft = false
  prevDpadRight = false
  prevStickLeft = false
  prevStickRight = false

proc syncDirectionalHeldState(game: var Game) =
  game.leftHeld = dpadLeftHeld or stickLeftHeld
  game.rightHeld = dpadRightHeld or stickRightHeld

proc resetPadState*() =
  ## Reset internal pad held state. Useful for tests.
  resetControllerState()

proc openFirstController*() =
  ## Scan for and open the first available game controller.
  let n = numJoysticks()
  for i in 0.cint ..< n:
    if isGameController(i):
      controller = gameControllerOpen(i)
      if controller != nil:
        controllerConnected = true
        resetControllerState()
        return

proc closeController*() =
  if controller != nil:
    controller.close()
    controller = nil
  controllerConnected = false
  resetControllerState()

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
    dpadLeftHeld = isDown
    syncDirectionalHeldState(game)

  of SDL_CONTROLLER_BUTTON_DPAD_RIGHT:
    dpadRightHeld = isDown
    syncDirectionalHeldState(game)

  else: discard

proc handleControllerAxis*(game: var Game, axis: uint8, value: int16) =
  ## Map left stick X axis to left/right movement.
  if axis == SDL_CONTROLLER_AXIS_LEFTX.uint8:
    let newLeft = value < -AXIS_DEADZONE
    let newRight = value > AXIS_DEADZONE
    stickLeftHeld = newLeft
    stickRightHeld = newRight
    syncDirectionalHeldState(game)

proc applyControllerSnapshot*(
    game: var Game,
    aPressed, bPressed, startPressed, lbPressed, rbPressed,
    dpadLeftPressed, dpadRightPressed: bool,
    leftX: int16
  ) =
  ## Apply a controller snapshot using edge-triggered updates.
  ##
  ## This is shared by the live polling path and unit tests so we can keep the
  ## transition logic deterministic without requiring hardware.
  if aPressed != prevButtonA:
    handleControllerButton(game, SDL_CONTROLLER_BUTTON_A.uint8, aPressed)
    prevButtonA = aPressed

  if bPressed != prevButtonB:
    if bPressed:
      handleControllerButton(game, SDL_CONTROLLER_BUTTON_B.uint8, true)
    prevButtonB = bPressed

  if startPressed != prevButtonStart:
    if startPressed:
      handleControllerButton(game, SDL_CONTROLLER_BUTTON_START.uint8, true)
    prevButtonStart = startPressed

  if lbPressed != prevButtonLB:
    if lbPressed:
      handleControllerButton(game, SDL_CONTROLLER_BUTTON_LEFTSHOULDER.uint8, true)
    prevButtonLB = lbPressed

  if rbPressed != prevButtonRB:
    if rbPressed:
      handleControllerButton(game, SDL_CONTROLLER_BUTTON_RIGHTSHOULDER.uint8, true)
    prevButtonRB = rbPressed

  if dpadLeftPressed != prevDpadLeft:
    handleControllerButton(game, SDL_CONTROLLER_BUTTON_DPAD_LEFT.uint8, dpadLeftPressed)
    prevDpadLeft = dpadLeftPressed

  if dpadRightPressed != prevDpadRight:
    handleControllerButton(game, SDL_CONTROLLER_BUTTON_DPAD_RIGHT.uint8, dpadRightPressed)
    prevDpadRight = dpadRightPressed

  let newStickLeft = leftX < -AXIS_DEADZONE
  let newStickRight = leftX > AXIS_DEADZONE
  if newStickLeft != prevStickLeft or newStickRight != prevStickRight:
    handleControllerAxis(game, SDL_CONTROLLER_AXIS_LEFTX.uint8, leftX)
    prevStickLeft = newStickLeft
    prevStickRight = newStickRight

proc pollControllerInput*(game: var Game) =
  ## Poll the active SDL game controller once and translate changes into game
  ## actions. Intended for a main loop that no longer depends on SDL events.
  gameControllerUpdate()

  if controller == nil:
    openFirstController()
  if controller == nil:
    return
  if int(getAttached(controller)) == 0:
    closeController()
    return

  let
    aPressed = getButton(controller, SDL_CONTROLLER_BUTTON_A) != 0
    bPressed = getButton(controller, SDL_CONTROLLER_BUTTON_B) != 0
    startPressed = getButton(controller, SDL_CONTROLLER_BUTTON_START) != 0
    lbPressed = getButton(controller, SDL_CONTROLLER_BUTTON_LEFTSHOULDER) != 0
    rbPressed = getButton(controller, SDL_CONTROLLER_BUTTON_RIGHTSHOULDER) != 0
    dpadLeftPressed = getButton(controller, SDL_CONTROLLER_BUTTON_DPAD_LEFT) != 0
    dpadRightPressed = getButton(controller, SDL_CONTROLLER_BUTTON_DPAD_RIGHT) != 0
    leftX = getAxis(controller, SDL_CONTROLLER_AXIS_LEFTX)

  applyControllerSnapshot(
    game,
    aPressed, bPressed, startPressed, lbPressed, rbPressed,
    dpadLeftPressed, dpadRightPressed, leftX
  )

proc handleControllerDevice*(game: var Game, event: Event) =
  ## Handle controller connect/disconnect events for the legacy SDL event path.
  ##
  ## This remains exported so the current SDL-based main loop keeps building
  ## while the Windy migration lands.
  case event.kind
  of ControllerDeviceAdded:
    if not controllerConnected:
      let idx = event.cdevice.which
      if isGameController(idx):
        controller = gameControllerOpen(idx)
        if controller != nil:
          controllerConnected = true
          resetControllerState()
  of ControllerDeviceRemoved:
    if controllerConnected and controller != nil:
      controller.close()
      controller = nil
      controllerConnected = false
      resetControllerState()
      # Clear any held gamepad state so character stops moving.
      game.leftHeld = false
      game.rightHeld = false
  else: discard
