# Implement all 6 character-specific abilities

**Area:** physics
**Depends:** 0005

Extend `src/systems/physics.nim` with full ability implementations:
- Pip: Double jump — can jump once more while airborne (track hasDoubleJumped flag)
- Luca: Float — when holding jump while falling, vy is capped at a slow rate (e.g. -60 px/s fall)
- Bruno: Heavy — higher gravity multiplier (1.5x), lower jump height, can activate heavy-only buttons
- Cara: Wall jump — detect wall contact, allow jumping off walls (reflect vx, set vy)
- Felix: Extended coyote time — can still jump for 200ms after leaving a platform edge
- Ivy: Graceful fall — terminal velocity is much lower (200 px/s vs 800), smooth landing

## Acceptance criteria
- Each ability works as described
- Unit test per ability
- Bruno activates heavy buttons, others don't
- `make test` passes
