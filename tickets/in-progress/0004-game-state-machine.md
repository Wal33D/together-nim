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

**Worktree:** /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0004-game-state-machine

## Prediction
- predicted_difficulty: hard
- predicted_duration_minutes: 32
- reasoning: Requires creating a new game.nim module plus refactoring together.nim with a fixed-timestep loop, state machine, SDL2 event handling, and unit tests — multi-file with integration risk across the engine foundation, likely 2 attempts.
