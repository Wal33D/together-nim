## Keyboard input handling for Together

import sdl2
import "../game"
import "audio"
import "../constants"

const
  SCANCODE_LEFT* = 80.cint
  SCANCODE_RIGHT* = 79.cint
  SCANCODE_A* = 4.cint
  SCANCODE_D* = 7.cint
  SCANCODE_SPACE* = 44.cint
  SCANCODE_1* = 30.cint
  SCANCODE_2* = 31.cint
  SCANCODE_3* = 32.cint
  SCANCODE_4* = 33.cint
  SCANCODE_5* = 34.cint
  SCANCODE_6* = 35.cint

proc processKey*(game: var Game, scancode: cint, isDown: bool) =
  case scancode
  of SCANCODE_F11:
    discard
  of SCANCODE_LEFT, SCANCODE_A:
    game.leftHeld = isDown
  of SCANCODE_RIGHT, SCANCODE_D:
    game.rightHeld = isDown
  of SCANCODE_SPACE:
    if isDown:
      game.pressJump()
    else:
      game.releaseJump()
  of SCANCODE_1, SCANCODE_2, SCANCODE_3, SCANCODE_4, SCANCODE_5, SCANCODE_6:
    if isDown:
      let idx = (scancode - SCANCODE_1).int
      if game.selectActiveCharacter(idx):
        playSound(soundCharSwitch)
  of SCANCODE_RETURN:
    if isDown:
      game.handleKey(SCANCODE_RETURN)
  of SCANCODE_ESCAPE:
    if isDown:
      game.handleKey(SCANCODE_ESCAPE)
  of SCANCODE_R:
    if isDown:
      game.handleKey(SCANCODE_R)
  else: discard

proc handleInput*(game: var Game, event: Event) =
  case event.kind
  of KeyDown:
    game.processKey(event.key.keysym.scancode.cint, true)
  of KeyUp:
    game.processKey(event.key.keysym.scancode.cint, false)
  else: discard
