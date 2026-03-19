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
