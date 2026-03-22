import unittest
import windy
import "../src/game"
import "../src/constants"
import "../src/systems/input"
import "../src/entities/character"

proc skipActTitle(game: var Game) =
  if game.state == actTitle:
    let scaledStep = FIXED_TIMESTEP * TIME_SCALE
    let steps = int(ActTitleDuration / scaledStep) + 2
    for _ in 0 ..< steps:
      game.update(FIXED_TIMESTEP)

suite "input system":
  test "left arrow sets leftHeld":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    processKey(g, KeyLeft, true)
    check g.leftHeld == true

  test "right arrow sets rightHeld":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    processKey(g, KeyRight, true)
    check g.rightHeld == true

  test "releasing left clears leftHeld":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    processKey(g, KeyLeft, true)
    processKey(g, KeyLeft, false)
    check g.leftHeld == false

  test "space triggers jump on grounded character":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    g.characters[0].grounded = true
    processKey(g, KeySpace, true)
    check g.characters[0].vy < 0.0

  test "releasing space cuts jump height":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    g.characters[0].grounded = true
    processKey(g, KeySpace, true)
    let fullJumpVy = g.characters[0].vy
    processKey(g, KeySpace, false)
    check g.characters[0].vy > fullJumpVy
    check g.characters[0].vy < 0.0

  test "enter starts game from menu":
    var g = newGame()
    processKey(g, KeyEnter, true)
    check g.state == actTitle

  test "escape pauses playing game":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    processKey(g, KeyEscape, true)
    check g.state == paused

  test "escape resumes paused game":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    processKey(g, KeyEscape, true)
    processKey(g, KeyEscape, true)
    check g.state == playing

  test "key 1 switches active character":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    g.activeCharacterIndex = 1
    processKey(g, Key1, true)
    check g.activeCharacterIndex == 0

  test "F11 does not affect gameplay input state":
    var g = newGame()
    g.startGame()
    g.skipActTitle()
    processKey(g, KeyF11, true)
    check g.state == playing
    check g.leftHeld == false
    check g.rightHeld == false
