# Implement character entity type and abilities

**Area:** entities
**Depends:** 0001

Implement `src/entities/character.nim`:
- Character object type with: id, x, y, width, height, color, vx, vy, grounded, facingRight
- CharacterAbility variant type for the 6 abilities (doubleJump, float, heavy, wallJump, coyoteTime, gracefulFall)
- Factory proc `newCharacter(id: string): Character` that creates characters with correct dimensions/colors/abilities
- All 6 characters: Pip (30x30 pink), Luca (25x40 yellow), Bruno (50x50 brown), Cara (20x45 light pink), Felix (35x35 tan), Ivy (28x42 teal)

## Acceptance criteria
- Character type compiles with all fields
- `newCharacter("pip")` returns correct pink 30x30 character with double jump
- Unit test validates all 6 characters
- `make test` passes

**Worktree:** /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0002-character-entity

## Prediction
- predicted_difficulty: easy
- predicted_duration_minutes: 12
- reasoning: Single-file implementation with well-specified data (6 characters, known dimensions/colors/abilities) and no cross-module dependencies beyond constants, one attempt expected.
