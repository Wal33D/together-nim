# Define core constants and shared types

**Area:** entities

Implement `src/constants.nim` with all game constants:
- Physics: GRAVITY (980.0), JUMP_VELOCITY (-450.0), MAX_FALL_SPEED (800.0), TERMINAL_VELOCITY
- Window: DEFAULT_WIDTH (1280), DEFAULT_HEIGHT (720)
- Character dimensions and colors for all 6 characters
- Timing: FIXED_TIMESTEP (1/60)

Implement basic shared types that other modules will import.

## Acceptance criteria
- `src/constants.nim` compiles and exports all constants
- Unit test in `tests/test_constants.nim` validates key values
- `make test` passes

**Worktree:** /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0001-constants-and-types

## Prediction
- predicted_difficulty: easy
- predicted_duration_minutes: 12
- reasoning: Single-file constants definition with known values, plus a simple test file — no logic complexity or integration risk, one attempt expected.
