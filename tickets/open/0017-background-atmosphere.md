# Add atmospheric background effects

**Area:** effects

Create atmospheric background rendering in the renderer or a new `src/systems/atmosphere.nim`:
1. Subtle gradient background instead of flat color — dark blue at top to slightly lighter at bottom
2. Floating particles in background (very slow, very transparent, 10-15 particles)
   - Small dots that drift slowly upward or sideways
   - Colors matching the characters in the current level (very faded, alpha ~20-30)
   - Respawn at random positions when they drift off screen
3. Faint "light shafts" — 2-3 vertical semi-transparent rectangles that slowly drift
4. Update these effects each frame in game.update()
5. Render them BEHIND platforms but AFTER the background clear

## Acceptance criteria
- Background has subtle depth instead of flat color
- Floating particles create a living atmosphere
- Effects are subtle and don't distract from gameplay
- `make test` passes
