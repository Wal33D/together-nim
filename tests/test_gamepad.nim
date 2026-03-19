import unittest
import sdl2/gamecontroller
import "../src/game"
import "../src/systems/gamepad"
import "../src/entities/character"

suite "gamepad system":
  test "A button triggers jump on grounded character":
    var g = newGame()
    g.startGame()
    g.characters[0].grounded = true
    handleControllerButton(g, SDL_CONTROLLER_BUTTON_A.uint8, true)
    check g.characters[0].vy < 0.0

  test "A button starts game from menu":
    var g = newGame()
    check g.state == menu
    handleControllerButton(g, SDL_CONTROLLER_BUTTON_A.uint8, true)
    check g.state == playing

  test "Start button pauses playing game":
    var g = newGame()
    g.startGame()
    handleControllerButton(g, SDL_CONTROLLER_BUTTON_START.uint8, true)
    check g.state == paused

  test "Start button resumes paused game":
    var g = newGame()
    g.startGame()
    handleControllerButton(g, SDL_CONTROLLER_BUTTON_START.uint8, true)
    check g.state == paused
    handleControllerButton(g, SDL_CONTROLLER_BUTTON_START.uint8, true)
    check g.state == playing

  test "B button restarts level":
    var g = newGame()
    g.startGame()
    # Move character to verify restart resets position
    g.characters[0].x = 999.0
    handleControllerButton(g, SDL_CONTROLLER_BUTTON_B.uint8, true)
    check g.characters[0].x != 999.0

  test "RB switches to next character":
    var g = newGame()
    g.loadLevel(4)  # Level 5 has pip and luca (2 chars)
    g.state = playing
    check g.activeCharacterIndex == 0
    handleControllerButton(g, SDL_CONTROLLER_BUTTON_RIGHTSHOULDER.uint8, true)
    check g.activeCharacterIndex == 1

  test "LB switches to previous character":
    var g = newGame()
    g.loadLevel(4)  # Level 5 has pip and luca
    g.state = playing
    g.activeCharacterIndex = 1
    handleControllerButton(g, SDL_CONTROLLER_BUTTON_LEFTSHOULDER.uint8, true)
    check g.activeCharacterIndex == 0

  test "LB wraps around from first to last character":
    var g = newGame()
    g.loadLevel(4)  # 2 characters
    g.state = playing
    check g.activeCharacterIndex == 0
    handleControllerButton(g, SDL_CONTROLLER_BUTTON_LEFTSHOULDER.uint8, true)
    check g.activeCharacterIndex == 1  # wraps to last

  test "D-pad left sets leftHeld":
    var g = newGame()
    g.startGame()
    handleControllerButton(g, SDL_CONTROLLER_BUTTON_DPAD_LEFT.uint8, true)
    check g.leftHeld == true

  test "D-pad right sets rightHeld":
    var g = newGame()
    g.startGame()
    handleControllerButton(g, SDL_CONTROLLER_BUTTON_DPAD_RIGHT.uint8, true)
    check g.rightHeld == true

  test "releasing D-pad left clears leftHeld":
    var g = newGame()
    g.startGame()
    handleControllerButton(g, SDL_CONTROLLER_BUTTON_DPAD_LEFT.uint8, true)
    handleControllerButton(g, SDL_CONTROLLER_BUTTON_DPAD_LEFT.uint8, false)
    check g.leftHeld == false

  test "left stick axis sets leftHeld":
    resetPadState()
    var g = newGame()
    g.startGame()
    handleControllerAxis(g, SDL_CONTROLLER_AXIS_LEFTX.uint8, -20000'i16)
    check g.leftHeld == true

  test "left stick axis sets rightHeld":
    resetPadState()
    var g = newGame()
    g.startGame()
    handleControllerAxis(g, SDL_CONTROLLER_AXIS_LEFTX.uint8, 20000'i16)
    check g.rightHeld == true

  test "left stick within deadzone clears held":
    resetPadState()
    var g = newGame()
    g.startGame()
    handleControllerAxis(g, SDL_CONTROLLER_AXIS_LEFTX.uint8, 20000'i16)
    check g.rightHeld == true
    handleControllerAxis(g, SDL_CONTROLLER_AXIS_LEFTX.uint8, 100'i16)
    check g.rightHeld == false

  test "AXIS_DEADZONE constant is reasonable":
    check AXIS_DEADZONE > 0
    check AXIS_DEADZONE < 16000
