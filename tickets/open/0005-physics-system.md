# Implement physics and collision detection

**Area:** physics
**Depends:** 0001, 0002, 0003

Implement `src/systems/physics.nim`:
- `updatePhysics(characters, level, dt)` proc
- Apply gravity to all characters (vy += GRAVITY * dt)
- AABB collision detection: `intersects(a, b: Rect): bool`
- Platform collision resolution: stop falling when landing on platform, block horizontal movement
- Ground detection: set character.grounded when on platform
- Hazard collision: detect contact with spikes, return death flag
- Exit collision: detect character standing in their exit zone
- Basic jump: if grounded, set vy = JUMP_VELOCITY
- Character-specific physics stubs (double jump, float, etc. — full implementation in next ticket)

## Acceptance criteria
- Character falls with gravity and lands on platforms
- AABB collision works correctly
- Hazard contact detected
- Exit overlap detected
- Unit tests for collision detection and gravity
- `make test` passes
