import
  unittest,
  windy,
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

  test "AxisDeadzone constant is reasonable":
    check AxisDeadzone > 0
    check AxisDeadzone < 16000

  test "polling snapshot starts game from menu on A press":
    var g = newGame()
    check g.state == menu
    applyControllerSnapshot(g, true, false, false, false, false, false, false, false, false, 0'i16)
    check g.state == actTitle

  test "polling snapshot keeps stick input active when dpad releases":
    var g = newGame()
    g.startGame()
    g.skipActTitle()

    applyControllerSnapshot(g, false, false, false, false, false, true, false, false, false, -20000'i16)
    check g.leftHeld == true
    check g.rightHeld == false

    applyControllerSnapshot(g, false, false, false, false, false, false, false, false, false, -20000'i16)
    check g.leftHeld == true
    check g.rightHeld == false

  # --- Settings navigation tests ---

  test "d-pad down moves settings cursor forward":
    var g = newGame()
    g.openSettings()
    check g.settingsCursor == 0
    handleControllerButton(g, ButtonDpadDown, true)
    check g.settingsCursor == 1

  test "d-pad up moves settings cursor backward":
    var g = newGame()
    g.openSettings()
    g.settingsCursor = 2
    handleControllerButton(g, ButtonDpadUp, true)
    check g.settingsCursor == 1

  test "d-pad up wraps from 0 to 4":
    var g = newGame()
    g.openSettings()
    check g.settingsCursor == 0
    handleControllerButton(g, ButtonDpadUp, true)
    check g.settingsCursor == 4

  test "d-pad down wraps from 4 to 0":
    var g = newGame()
    g.openSettings()
    g.settingsCursor = 4
    handleControllerButton(g, ButtonDpadDown, true)
    check g.settingsCursor == 0

  test "B exits settings to previous state":
    var g = newGame()
    g.state = menu
    g.openSettings()
    check g.state == settings
    handleControllerButton(g, ButtonB, true)
    check g.state == menu

  test "Start exits settings to previous state":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    g.handleKey(KeyEscape)  # Pause.
    g.openSettings()
    check g.state == settings
    handleControllerButton(g, ButtonStart, true)
    check g.state == paused

  test "A on back row exits settings":
    var g = newGame()
    g.state = menu
    g.openSettings()
    g.settingsCursor = 4
    handleControllerButton(g, ButtonA, true)
    check g.state == menu

  test "d-pad right on window size cycles preset forward and sets pending":
    var g = newGame()
    g.openSettings()
    g.settingsCursor = 0
    g.settingsWindowPreset = 0
    handleControllerButton(g, ButtonDpadRight, true)
    check g.settingsWindowPreset == 1
    check g.pendingSettingsApply == true

  test "d-pad left on window size cycles preset backward with wrap":
    var g = newGame()
    g.openSettings()
    g.settingsCursor = 0
    g.settingsWindowPreset = 0
    handleControllerButton(g, ButtonDpadLeft, true)
    check g.settingsWindowPreset == WindowPresets.len - 1
    check g.pendingSettingsApply == true

  test "A on fullscreen row sets pending apply":
    var g = newGame()
    g.openSettings()
    g.settingsCursor = 1
    handleControllerButton(g, ButtonA, true)
    check g.pendingSettingsApply == true

  # --- One-shot press flag tests ---

  test "snapshot sets padUpPressed on rising edge":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    clearPadPressed()
    applyControllerSnapshot(g, false, false, false, false, false, false, false, true, false, 0'i16)
    check padUpPressed == true
    check padDownPressed == false

  test "snapshot sets padDownPressed on rising edge":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    clearPadPressed()
    applyControllerSnapshot(g, false, false, false, false, false, false, false, false, true, 0'i16)
    check padDownPressed == true
    check padUpPressed == false

  test "clearPadPressed resets one-shot flags":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    clearPadPressed()
    applyControllerSnapshot(g, false, false, false, false, false, true, true, true, true, 0'i16)
    check padUpPressed == true
    check padDownPressed == true
    check padLeftPressed == true
    check padRightPressed == true
    clearPadPressed()
    check padUpPressed == false
    check padDownPressed == false
    check padLeftPressed == false
    check padRightPressed == false

suite "normalizeAxis":
  test "minimum input maps to -32768":
    check normalizeAxis(0, 0, 255) == -32768'i16

  test "maximum input maps to 32767":
    check normalizeAxis(255, 0, 255) == 32767'i16

  test "midpoint maps near zero":
    let mid = normalizeAxis(128, 0, 255)
    check mid > -512'i16
    check mid < 512'i16

  test "zero span returns zero":
    check normalizeAxis(5, 5, 5) == 0'i16

  test "negative span returns zero":
    check normalizeAxis(5, 10, 5) == 0'i16

  test "non-zero-based range normalizes correctly":
    check normalizeAxis(100, 100, 200) == -32768'i16
    check normalizeAxis(200, 100, 200) == 32767'i16
