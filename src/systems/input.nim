## Keyboard input handling for Together

import sdl2
import "../game"
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

const MOVE_SPEED* = 200.0

proc applyMovement(game: var Game) =
  if game.state != playing: return
  if game.activeCharacterIndex >= game.characters.len: return
  var vx = 0.0
  if game.leftHeld: vx -= MOVE_SPEED
  if game.rightHeld: vx += MOVE_SPEED
  game.characters[game.activeCharacterIndex].vx = vx

proc processKey*(game: var Game, scancode: cint, isDown: bool) =
  ## Process a key press or release by scancode. Testable without SDL events.
  case scancode
  of SCANCODE_LEFT, SCANCODE_A:
    game.leftHeld = isDown
    applyMovement(game)
  of SCANCODE_RIGHT, SCANCODE_D:
    game.rightHeld = isDown
    applyMovement(game)
  of SCANCODE_SPACE:
    if isDown and game.state == playing:
      if game.activeCharacterIndex < game.characters.len:
        game.characters[game.activeCharacterIndex].vy = JUMP_VELOCITY
  of SCANCODE_1, SCANCODE_2, SCANCODE_3, SCANCODE_4, SCANCODE_5, SCANCODE_6:
    if isDown:
      let idx = (scancode - SCANCODE_1).int
      if idx < game.characters.len:
        game.activeCharacterIndex = idx
  of SCANCODE_RETURN:
    if isDown:
      case game.state
      of menu: game.state = playing
      else: discard
  of SCANCODE_ESCAPE:
    if isDown:
      case game.state
      of playing: game.state = paused
      of paused: game.state = playing
      else: discard
  else: discard

proc handleInput*(game: var Game, event: Event) =
  ## Process an SDL input event and update game state.
  case event.kind
  of KeyDown:
    game.processKey(event.key.keysym.scancode.cint, true)
  of KeyUp:
    game.processKey(event.key.keysym.scancode.cint, false)
  else: discard
