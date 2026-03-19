# Implement SDL2 renderer for game elements

**Area:** rendering
**Depends:** 0004, 0002, 0003

Implement `src/systems/renderer.nim`:
- `renderGame(renderer, game)` proc
- Dark blue/purple background (26, 26, 46)
- Platforms as gray filled rectangles
- Characters as colored filled rectangles (using their character color)
- Active character outline highlight (white border)
- Hazards as red filled rectangles
- Exits as character-colored outlined rectangles
- Buttons as small colored rectangles (lit when pressed)
- Doors as semi-transparent rectangles (disappear when open)
- Simple character bar at bottom showing all available characters with highlight on active

## Acceptance criteria
- All game elements render visually
- Active character is visually distinct
- Character bar shows available characters
- Game is playable with visual feedback
- `make test` passes

**Worktree:** /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0008-renderer
