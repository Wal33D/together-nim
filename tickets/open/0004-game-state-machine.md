# Implement game state machine and main loop

**Area:** core-engine
**Depends:** 0001

Refactor `src/together.nim` and create `src/game.nim`:
- GameState enum: menu, playing, paused, credits
- Game object with: state, currentLevel, characters, activeCharacterIndex, deltaTime
- Fixed timestep game loop (60 fps target) with update/render separation
- State transitions: menu->playing, playing->paused, paused->playing, playing->credits
- SDL2 event handling in main loop (quit, key events passed to game)

## Acceptance criteria
- Game starts in menu state
- Pressing Enter transitions to playing state
- Escape toggles pause
- `make test` passes (unit test for state transitions)
