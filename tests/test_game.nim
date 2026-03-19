import unittest
import "../src/game"

suite "game state machine":
  test "game starts in menu state":
    let g = newGame()
    check g.state == menu

  test "enter transitions menu to playing":
    var g = newGame()
    g.handleKey(SCANCODE_RETURN)
    check g.state == playing

  test "escape transitions playing to paused":
    var g = newGame()
    g.handleKey(SCANCODE_RETURN)
    g.handleKey(SCANCODE_ESCAPE)
    check g.state == paused

  test "escape transitions paused to playing":
    var g = newGame()
    g.handleKey(SCANCODE_RETURN)
    g.handleKey(SCANCODE_ESCAPE)
    g.handleKey(SCANCODE_ESCAPE)
    check g.state == playing

  test "escape in menu does nothing":
    var g = newGame()
    g.handleKey(SCANCODE_ESCAPE)
    check g.state == menu

  test "initial currentLevel is 0":
    let g = newGame()
    check g.currentLevel == 0

  test "initial activeCharacterIndex is 0":
    let g = newGame()
    check g.activeCharacterIndex == 0

  test "update sets deltaTime":
    var g = newGame()
    g.handleKey(SCANCODE_RETURN)
    g.update(1.0 / 60.0)
    check abs(g.deltaTime - 1.0 / 60.0) < 1e-10
