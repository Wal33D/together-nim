## Keyboard input handling for Together

import sdl2
import "../game"
import "../entities/character"
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
  of SCANCODE_LEFT, SCANCODE_A:
    game.leftHeld = isDown
  of SCANCODE_RIGHT, SCANCODE_D:
    game.rightHeld = isDown
  of SCANCODE_SPACE:
    if isDown and game.state == playing:
      if game.activeCharacterIndex < game.characters.len:
        var c = game.characters[game.activeCharacterIndex]
        # Double jump for Pip
        if c.ability == doubleJump:
          if c.grounded or c.jumpCount < 2:
            c.vy = c.jumpForce()
            c.grounded = false
            c.jumpCount += 1
            c.triggerJump()
        # Coyote time for Felix
        elif c.ability == coyoteTime:
          if c.grounded or c.coyoteTimer < FELIX_COYOTE_TIME:
            c.vy = c.jumpForce()
            c.grounded = false
            c.jumpCount = 1
            c.coyoteTimer = FELIX_COYOTE_TIME + 1  # consume coyote
            c.triggerJump()
        else:
          if c.grounded:
            c.vy = c.jumpForce()
            c.grounded = false
            c.jumpCount = 1
            c.triggerJump()
        game.characters[game.activeCharacterIndex] = c
      # Skip narration on space
      if game.narrationActive:
        game.narrationRevealed = game.narrationText.len
        game.narrationActive = false
  of SCANCODE_1, SCANCODE_2, SCANCODE_3, SCANCODE_4, SCANCODE_5, SCANCODE_6:
    if isDown:
      let idx = (scancode - SCANCODE_1).int
      if idx < game.characters.len:
        game.activeCharacterIndex = idx
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
