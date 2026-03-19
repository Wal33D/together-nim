# Implement emotional glow and background atmosphere effects

**Area:** effects
**Depends:** 0013, 0012

Extend `src/systems/animation.nim` and `src/systems/particles.nim`:

**Emotional glow** (in `animation.nim`):
- `glowAlpha(characters, character): uint8` — returns 0–80 based on how many other characters are within 100px (0 alone, ~40 for one nearby, ~80 for two or more)
- Renderer draws a slightly larger, semi-transparent circle/rect in the character's color behind the character when `glowAlpha > 0`

**Background atmosphere** (in `particles.nim`):
- `AtmosphereEmitter` type: holds ~20 slow-drifting background dust motes
- `initAtmosphere(emitter, screenW, screenH)` — seed motes at random positions across the screen
- `updateAtmosphere(emitter, dt)` — drift each mote upward/sideways very slowly; wrap around screen edges; no lifetime decay (they persist)
- `renderAtmosphere(renderer, emitter)` — draw as 1–2px dim white/lavender dots at low alpha (20–40)

## Acceptance criteria
- Glow is visible around a character when another character is nearby; absent when alone
- Atmosphere motes drift slowly and wrap; screen never empties of motes
- Unit test: `glowAlpha` returns 0 when no other character is within range, non-zero when one is within 100px
- `make test` passes
