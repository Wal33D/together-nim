import unittest
import "../src/game"

suite "game state machine":
  test "game starts in menu state":
    let g = newGame()
    check g.state == menu

  test "enter transitions menu to playing and loads level":
    var g = newGame()
    g.handleKey(SCANCODE_RETURN)
    check g.state == playing
    check g.characters.len > 0

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

  test "startGame loads level 0 with pip":
    var g = newGame()
    g.startGame()
    check g.characters.len == 1
    check g.characters[0].id == "pip"
