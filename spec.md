# Together — Narrative Puzzle-Platformer in Nim

## Game Overview

A narrative puzzle-platformer inspired by Thomas Was Alone. Players guide a family of 6 sentient colored rectangles through 30 levels across 5 acts. Each character has a unique ability. No character can reach every exit alone — cooperation is the core mechanic and message.

Reference: original TypeScript version at `~/Documents/GitHub/candycomp`

---

## Characters

| # | Name | Color | Hex | Size | Ability | Personality |
|---|------|-------|-----|------|---------|-------------|
| 1 | Pip | Pink | #FF6B9D | 30×30 | Double jump | Curious explorer. First introduced. |
| 2 | Luca | Yellow | #FFD93D | 25×40 | Float/glide | Dreamer. Drifts gently when falling. |
| 3 | Bruno | Brown | #6B4423 | 50×50 | Heavy — activates weight-sensitive buttons | Slow but strong. |
| 4 | Cara | Light Pink | #FF9FF3 | 20×45 | Wall jump | Climbs where others can't. |
| 5 | Felix | Tan | #D4A574 | 35×35 | Extended coyote time | Patient, never rushed. |
| 6 | Ivy | Teal | #A8D8EA | 28×42 | Graceful fall (slow fall speed) | Lands in peace. |

---

## Technical Architecture

**Stack:** Pure Nim + SDL2. No JS/web dependencies.

**Build:**
```
nim c -o:together -d:release src/together.nim
```
Requirements: nim >= 2.0.0, `sdl2` nimble package, SDL2 system library.

### Source Modules (`src/`)

| File | Responsibility |
|------|---------------|
| `together.nim` | Entry point, game loop, SDL2 init/shutdown |
| `game.nim` | Game state machine (menu, playing, paused, credits); orchestrates all systems |
| `constants.nim` | Physics constants, colors, dimensions, timing values |
| `entities/character.nim` | Character type: position, velocity, dimensions, color, ability, emotional state |
| `entities/level.nim` | Level type: platforms, hazards, exits, buttons, doors, narration |
| `systems/physics.nim` | Gravity, AABB collision detection & resolution, per-character physics |
| `systems/input.nim` | Keyboard input, character switching (keys 1–6) |
| `systems/camera.nim` | Smooth-follow camera centered on active character |
| `systems/renderer.nim` | SDL2 rendering: backgrounds, platforms, characters (colored rects), hazards, exits, UI |
| `systems/levels.nim` | All 30 level definitions and level loader |
| `systems/narration.nim` | Typewriter text-reveal for story narration |
| `systems/audio.nim` | SDL2 audio: sound effects and ambient music |
| `systems/particles.nim` | Particle system: landing dust, proximity sparkles |
| `systems/animation.nim` | Squash/stretch, idle sway, emotional glow |

---

## Game Mechanics

### Physics
- Gravity: 980 px/s²
- Jump velocity: −450 px/s
- AABB collision for all entities

### Per-Character Physics
- **Pip** — double jump allowed once mid-air
- **Luca** — reduced fall speed (glide) when holding jump
- **Bruno** — heavier mass; activates weight-sensitive pressure plates
- **Cara** — wall jump: jump off vertical surfaces
- **Felix** — extended coyote time (longer grace window after walking off edge)
- **Ivy** — graceful fall: reduced terminal velocity / fall speed

### Level Elements
- **Platforms** — static collision surfaces
- **Buttons (pressure plates)** — activated by standing on them; some require Bruno's weight
- **Doors** — open/close based on button state
- **Exits** — per-character zones; all characters must reach their exit to complete a level
- **Hazards (spikes)** — kill on contact; respawn character at level start
- **Moving platforms** — introduced in Act 3

---

## Level Structure (5 Acts, 30 Levels)

| Act | Levels | Title | Focus |
|-----|--------|-------|-------|
| 1 | 1–6 | Awakening | Introduce Pip alone, then Luca, then Bruno. Simple platforming. |
| 2 | 7–12 | Belonging | Add Cara. Multi-character cooperation with buttons and doors. |
| 3 | 13–18 | Challenge | Add Felix and Ivy. Hazards, moving platforms, harder puzzles. |
| 4 | 19–24 | Separation | Split paths requiring trust. Characters separated across the level. |
| 5 | 25–30 | Transcendence | All 6 characters. Complex cooperation. Final level: one exit for all. |

---

## Quality Gates

| Command | What it runs |
|---------|-------------|
| `make test` | `tests/test_*.nim` — unit tests for physics, collision, level validation, character abilities |
| `make integration-test` | `tests/integration_*.nim` — currently a placeholder that passes |

---

## Implementation Order

Start with the core loop, then expand:

1. `together.nim` — SDL2 init, window, game loop, shutdown
2. `constants.nim` — physics constants, colors, sizes
3. `entities/character.nim` — character data type
4. `entities/level.nim` — level data type
5. `systems/physics.nim` — gravity, AABB collision, basic resolution
6. `systems/input.nim` — keyboard polling, character switch (1–6)
7. `systems/renderer.nim` — draw colored rects, platforms, UI
8. `systems/camera.nim` — smooth follow camera
9. `game.nim` — state machine wiring everything together
10. `systems/levels.nim` — level 1 definition; Pip moving through a simple level
11. Expand: remaining levels, narration, audio, particles, animation

**Milestone 0:** Pip moves through a single flat level, collides with platforms, and reaches an exit.
