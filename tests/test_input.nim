import unittest
import "../src/game"
import "../src/constants"
import "../src/systems/input"
import "../src/entities/character"

suite "input system":
  test "left arrow sets leftHeld":
    var g = newGame()
    g.startGame()
    processKey(g, SCANCODE_LEFT, true)
    check g.leftHeld == true

  test "right arrow sets rightHeld":
    var g = newGame()
    g.startGame()
    processKey(g, SCANCODE_RIGHT, true)
    check g.rightHeld == true

  test "releasing left clears leftHeld":
    var g = newGame()
    g.startGame()
    processKey(g, SCANCODE_LEFT, true)
    processKey(g, SCANCODE_LEFT, false)
    check g.leftHeld == false

  test "space triggers jump on grounded character":
    var g = newGame()
    g.startGame()
    g.characters[0].grounded = true
    processKey(g, SCANCODE_SPACE, true)
    check g.characters[0].vy < 0.0

  test "releasing space cuts jump height":
    var g = newGame()
    g.startGame()
    g.characters[0].grounded = true
    processKey(g, SCANCODE_SPACE, true)
    let fullJumpVy = g.characters[0].vy
    processKey(g, SCANCODE_SPACE, false)
    check g.characters[0].vy > fullJumpVy
    check g.characters[0].vy < 0.0

  test "enter starts game from menu":
    var g = newGame()
    processKey(g, SCANCODE_RETURN, true)
    check g.state == playing

  test "escape pauses playing game":
    var g = newGame()
    g.startGame()
    processKey(g, SCANCODE_ESCAPE, true)
    check g.state == paused

  test "escape resumes paused game":
    var g = newGame()
    g.startGame()
    processKey(g, SCANCODE_ESCAPE, true)
    processKey(g, SCANCODE_ESCAPE, true)
    check g.state == playing

  test "key 1 switches active character":
    var g = newGame()
    g.startGame()
    g.activeCharacterIndex = 1
    processKey(g, SCANCODE_1, true)
    check g.activeCharacterIndex == 0

  test "F11 does not affect gameplay input state":
    var g = newGame()
    g.startGame()
    processKey(g, SCANCODE_F11, true)
    check g.state == playing
    check g.leftHeld == false
    check g.rightHeld == false
