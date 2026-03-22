## Keyboard input handling for Together

import
  windy,
  ../game,
  ./audio,
  ../constants

proc processKey*(game: var Game, button: Button, isDown: bool) =
  case button
  of KeyF11:
    discard
  of KeyLeft, KeyA:
    game.leftHeld = isDown
  of KeyRight, KeyD:
    game.rightHeld = isDown
  of KeySpace:
    if isDown:
      game.pressJump()
    else:
      game.releaseJump()
  of Key1, Key2, Key3, Key4, Key5, Key6:
    if isDown:
      let idx = button.ord - Key1.ord
      if game.selectActiveCharacter(idx):
        playSound(soundCharSwitch)
  of KeyEnter:
    if isDown:
      game.handleKey(KeyEnter)
  of KeyEscape:
    if isDown:
      game.handleKey(KeyEscape)
  of KeyR:
    if isDown:
      game.handleKey(KeyR)
  else: discard
