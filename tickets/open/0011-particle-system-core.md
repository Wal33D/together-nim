# Implement particle system with landing dust

**Area:** effects
**Depends:** 0008, 0002

Implement `src/systems/particles.nim`:
- `Particle` type with: x, y, vx, vy, lifetime, maxLifetime, color, size
- `ParticleEmitter` type holding a seq of Particle
- `updateParticles(emitter, dt)` proc — advance positions, decay lifetime, remove dead particles
- `renderParticles(renderer, emitter)` proc — draw each particle as a small filled rect, alpha-faded by remaining lifetime
- `emitLandingDust(emitter, x, y, color)` proc — spawn 6–10 small gray/tan particles fanning outward when a character lands (call when character transitions to grounded)

## Acceptance criteria
- Particles spawn, move, and fade out correctly
- Landing dust appears at the character's feet when they land on a platform
- Unit test: emit particles, step forward, verify count decreases as lifetime expires
- `make test` passes
