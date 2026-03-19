# Implement character squash/stretch and idle sway animation

**Area:** effects
**Depends:** 0002, 0005

Implement `src/systems/animation.nim`:
- `CharacterAnim` type with fields: scaleX, scaleY (default 1.0), swayOffset, swayTimer
- `updateAnimation(anim, character, dt)` proc:
  - **Squash on land:** when character transitions to grounded, set scaleX=1.3, scaleY=0.7; lerp back to 1.0 over 0.15 seconds
  - **Stretch on jump:** when character leaves ground (vy < 0), set scaleX=0.8, scaleY=1.25; lerp back to 1.0 over 0.2 seconds
  - **Idle sway:** while grounded and not moving horizontally, oscillate scaleX between 0.98 and 1.02 using a sine wave (period ~2 seconds)
- `applyAnim(anim, baseRect): Rect` — return a scaled rect centered on the character's feet

The renderer should use `applyAnim` when drawing characters (wire up in renderer, no renderer ticket changes needed beyond calling this).

## Acceptance criteria
- Squash visibly widens/shortens the character sprite on landing
- Stretch visibly narrows/elongates the character on jumping
- Idle sway is subtle and continuous
- Unit test: trigger land event, verify scaleY < 1.0 immediately after, verify it returns to 1.0 after sufficient time steps
- `make test` passes
