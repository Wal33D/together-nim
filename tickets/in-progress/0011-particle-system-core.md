# Implement particle system with landing dust and exit sparkles

**Area:** effects

Create `src/systems/particles.nim`:
- Particle type: x, y, vx, vy, life, maxLife, color, size
- ParticleSystem type: seq of particles, max 200
- `emit(system, x, y, count, color, spread, speed)` — spawn burst of particles
- `update(system, dt)` — move particles, reduce life, remove dead ones
- `render(renderer, system)` — draw particles as small filled rects with alpha fade

Integrate into game:
- On character landing (when grounded transitions from false to true): emit 6 gray dust particles at character feet
- When character is at exit: emit 1 sparkle particle per frame in exit color
- Call update in game.update() and render in renderer after characters

## Acceptance criteria
- Landing creates dust puff
- Exits sparkle when character is in them
- Particles fade out and die
- `make test` passes

**Worktree:** /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0011-particle-system-core
