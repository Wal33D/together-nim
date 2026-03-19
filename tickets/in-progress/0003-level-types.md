# Implement level data types and first 3 levels

**Area:** entities
**Depends:** 0001

Implement `src/entities/level.nim`:
- Platform type: x, y, width, height
- Hazard type: x, y, width, height
- Exit type: x, y, width, height, characterId
- Button type: x, y, width, height, doorId, requiresHeavy
- Door type: id, x, y, width, height, isOpen
- Level type: id, name, narration, characters (seq[string]), platforms, hazards, exits, buttons, doors

Implement `src/systems/levels.nim` with level definitions for levels 1-3 (Act 1: Awakening):
- Level 1: Just Pip, simple platforms, one exit. "Pip woke up."
- Level 2: Pip + platforms requiring double jump
- Level 3: Pip + Luca, two exits, introduce floating

## Acceptance criteria
- Level types compile
- Levels 1-3 defined with valid platform layouts
- Unit test validates level 1 has correct character list and exit count
- `make test` passes

**Worktree:** /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0003-level-types
