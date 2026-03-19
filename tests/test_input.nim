import unittest
import "../src/game"
import "../src/systems/input"

suite "input system":
  test "left arrow sets leftHeld":
    var g = newGame()
    processKey(g, SCANCODE_LEFT, true)
    check g.leftHeld == true

  test "right arrow sets rightHeld":
    var g = newGame()
    processKey(g, SCANCODE_RIGHT, true)
    check g.rightHeld == true

  test "A key sets leftHeld":
    var g = newGame()
    processKey(g, SCANCODE_A, true)
    check g.leftHeld == true

  test "D key sets rightHeld":
    var g = newGame()
    processKey(g, SCANCODE_D, true)
    check g.rightHeld == true

  test "releasing left clears leftHeld":
    var g = newGame()
    processKey(g, SCANCODE_LEFT, true)
    processKey(g, SCANCODE_LEFT, false)
    check g.leftHeld == false

  test "releasing right clears rightHeld":
    var g = newGame()
    processKey(g, SCANCODE_RIGHT, true)
    processKey(g, SCANCODE_RIGHT, false)
    check g.rightHeld == false

  test "character moves left when left held in playing state":
    var g = newGame()
    g.state = playing
    g.characters.add(Character(x: 0.0, y: 0.0, colorIndex: 0))
    processKey(g, SCANCODE_LEFT, true)
    check g.characters[0].vx < 0.0

  test "character moves right when right held in playing state":
    var g = newGame()
    g.state = playing
    g.characters.add(Character(x: 0.0, y: 0.0, colorIndex: 0))
    processKey(g, SCANCODE_RIGHT, true)
    check g.characters[0].vx > 0.0

  test "character stops when left released":
    var g = newGame()
    g.state = playing
    g.characters.add(Character(x: 0.0, y: 0.0, colorIndex: 0))
    processKey(g, SCANCODE_LEFT, true)
    processKey(g, SCANCODE_LEFT, false)
    check g.characters[0].vx == 0.0

  test "holding both left and right cancels movement":
    var g = newGame()
    g.state = playing
    g.characters.add(Character(x: 0.0, y: 0.0, colorIndex: 0))
    processKey(g, SCANCODE_LEFT, true)
    processKey(g, SCANCODE_RIGHT, true)
    check g.characters[0].vx == 0.0

  test "no movement when not in playing state":
    var g = newGame()
    g.characters.add(Character(x: 0.0, y: 0.0, colorIndex: 0))
    processKey(g, SCANCODE_LEFT, true)
    check g.characters[0].vx == 0.0

  test "space triggers jump on active character":
    var g = newGame()
    g.state = playing
    g.characters.add(Character(x: 0.0, y: 0.0, colorIndex: 0))
    processKey(g, SCANCODE_SPACE, true)
    check g.characters[0].vy < 0.0

  test "space does not jump when not playing":
    var g = newGame()
    g.characters.add(Character(x: 0.0, y: 0.0, colorIndex: 0))
    processKey(g, SCANCODE_SPACE, true)
    check g.characters[0].vy == 0.0

  test "key 2 switches to second character":
    var g = newGame()
    g.state = playing
    g.characters.add(Character(x: 0.0, y: 0.0, colorIndex: 0))
    g.characters.add(Character(x: 0.0, y: 0.0, colorIndex: 1))
    processKey(g, SCANCODE_2, true)
    check g.activeCharacterIndex == 1

  test "key 1 switches to first character":
    var g = newGame()
    g.state = playing
    g.characters.add(Character(x: 0.0, y: 0.0, colorIndex: 0))
    g.characters.add(Character(x: 0.0, y: 0.0, colorIndex: 1))
    g.activeCharacterIndex = 1
    processKey(g, SCANCODE_1, true)
    check g.activeCharacterIndex == 0

  test "number key out of range is ignored":
    var g = newGame()
    g.state = playing
    g.characters.add(Character(x: 0.0, y: 0.0, colorIndex: 0))
    processKey(g, SCANCODE_3, true)
    check g.activeCharacterIndex == 0

  test "enter transitions menu to playing":
    var g = newGame()
    processKey(g, SCANCODE_RETURN, true)
    check g.state == playing

  test "escape pauses playing game":
    var g = newGame()
    g.state = playing
    processKey(g, SCANCODE_ESCAPE, true)
    check g.state == paused

  test "escape resumes paused game":
    var g = newGame()
    g.state = paused
    processKey(g, SCANCODE_ESCAPE, true)
    check g.state == playing

  test "escape in menu does nothing":
    var g = newGame()
    processKey(g, SCANCODE_ESCAPE, true)
    check g.state == menu
