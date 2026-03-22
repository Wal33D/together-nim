import
  unittest,
  game,
  constants,
  systems/gamepad,
  entities/character

proc skipActTitle(game: var Game) =
  if game.state == actTitle:
    let scaledStep = FIXED_TIMESTEP * TIME_SCALE
    let steps = int(ActTitleDuration / scaledStep) + 2
    for _ in 0 ..< steps:
      game.update(FIXED_TIMESTEP)

suite "gamepad system":
  setup:
    resetPadState()

  test "A button triggers jump on grounded character":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    g.characters[0].grounded = true
    handleControllerButton(g, ButtonA, true)
    check g.characters[0].vy < 0.0

  test "A button starts game from menu":
    var g = newGame()
    check g.state == menu
    handleControllerButton(g, ButtonA, true)
    check g.state == actTitle

  test "Start button pauses playing game":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    handleControllerButton(g, ButtonStart, true)
    check g.state == paused

  test "Start button resumes paused game":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    handleControllerButton(g, ButtonStart, true)
    check g.state == paused
    handleControllerButton(g, ButtonStart, true)
    check g.state == playing

  test "B button restarts level":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    # Move character to verify restart resets position
    g.characters[0].x = 999.0
    handleControllerButton(g, ButtonB, true)
    check g.characters[0].x != 999.0

  test "RB switches to next character":
    var g = newGame()
    g.loadLevel(4)  # Level 5 has pip and luca (2 chars)
    g.state = playing
    check g.activeCharacterIndex == 0
    handleControllerButton(g, ButtonRB, true)
    check g.activeCharacterIndex == 1

  test "LB switches to previous character":
    var g = newGame()
    g.loadLevel(4)  # Level 5 has pip and luca
    g.state = playing
    g.activeCharacterIndex = 1
    handleControllerButton(g, ButtonLB, true)
    check g.activeCharacterIndex == 0

  test "LB wraps around from first to last character":
    var g = newGame()
    g.loadLevel(4)  # 2 characters
    g.state = playing
    check g.activeCharacterIndex == 0
    handleControllerButton(g, ButtonLB, true)
    check g.activeCharacterIndex == 1  # wraps to last

  test "D-pad left sets leftHeld":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    handleControllerButton(g, ButtonDpadLeft, true)
    check g.leftHeld == true

  test "D-pad right sets rightHeld":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    handleControllerButton(g, ButtonDpadRight, true)
    check g.rightHeld == true

  test "releasing D-pad left clears leftHeld":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    handleControllerButton(g, ButtonDpadLeft, true)
    handleControllerButton(g, ButtonDpadLeft, false)
    check g.leftHeld == false

  test "left stick axis sets leftHeld":
    resetPadState()
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    handleControllerAxis(g, AxisLeftX, -20000'i16)
    check g.leftHeld == true

  test "left stick axis sets rightHeld":
    resetPadState()
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    handleControllerAxis(g, AxisLeftX, 20000'i16)
    check g.rightHeld == true

  test "left stick within deadzone clears held":
    resetPadState()
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    handleControllerAxis(g, AxisLeftX, 20000'i16)
    check g.rightHeld == true
    handleControllerAxis(g, AxisLeftX, 100'i16)
    check g.rightHeld == false

  test "AXIS_DEADZONE constant is reasonable":
    check AXIS_DEADZONE > 0
    check AXIS_DEADZONE < 16000

  test "polling snapshot starts game from menu on A press":
    var g = newGame()
    check g.state == menu
    applyControllerSnapshot(g, true, false, false, false, false, false, false, 0'i16)
    check g.state == actTitle

  test "polling snapshot keeps stick input active when dpad releases":
    var g = newGame()
    g.startGame()
    g.skipActTitle()

    applyControllerSnapshot(g, false, false, false, false, false, true, false, -20000'i16)
    check g.leftHeld == true
    check g.rightHeld == false

    applyControllerSnapshot(g, false, false, false, false, false, false, false, -20000'i16)
    check g.leftHeld == true
    check g.rightHeld == false
