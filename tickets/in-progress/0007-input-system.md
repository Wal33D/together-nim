# Implement keyboard input handling

**Area:** input
**Depends:** 0004, 0002

Implement `src/systems/input.nim`:
- `handleInput(game, event)` proc processes SDL key events
- Left/Right arrow or A/D for horizontal movement
- Space for jump
- Keys 1-6 to switch active character
- Escape for pause toggle
- Enter to start game from menu
- Track key held state (not just key down) for continuous movement

## Acceptance criteria
- Character moves left/right with arrow keys
- Space triggers jump
- Number keys switch active character
- `make test` passes

**Worktree:** /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0007-input-system
