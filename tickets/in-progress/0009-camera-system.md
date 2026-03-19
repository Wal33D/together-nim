# Implement smooth follow camera for larger levels

**Area:** rendering

The game window is 800x500 but levels can be larger. Implement a camera in `src/systems/camera.nim`:
- Camera type with x, y offset, targetX, targetY
- Smooth lerp follow toward active character (lerp factor ~0.08)
- Camera offset applied to ALL rendering in renderer.nim (platforms, characters, exits, hazards, etc)
- Clamp camera so it doesn't show beyond level bounds
- Level type in entities/level.nim needs `levelWidth` and `levelHeight` fields (default 800x500)
- Update levels.nim — levels 4 and 5 can be wider (e.g. 1000px wide)
- Camera imported and used in game.nim update loop and passed to renderGame

The character bar and narration should render at FIXED screen positions (not affected by camera).

## Acceptance criteria
- Camera smoothly follows active character
- Switching characters pans camera to new target
- Works with current 5 levels
- `make test` passes

**Worktree:** /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0009-camera-system

## Prediction
- predicted_difficulty: hard
- predicted_duration_minutes: 32
- reasoning: Touches 5+ files (camera.nim new, renderer.nim pervasive offset threading, game.nim, level.nim, levels.nim), requires careful coordinate transform logic with fixed-position UI exceptions and level clamping — high integration risk across all rendering paths, likely 2 attempts.
