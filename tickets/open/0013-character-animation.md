# Implement squash/stretch and idle sway animation

**Area:** effects

Characters in entities/character.nim already have squashX, squashY, idleTimer, landingTimer, contentment fields and animation procs (updateAnimation, triggerLanding, triggerJump, drawWidth, drawHeight, drawX, drawY, idleSway).

Wire these into the game:
1. In physics.nim: call `triggerLanding()` when a character transitions from airborne to grounded
2. In physics.nim or game.nim: call `triggerJump()` when jump is triggered in input.nim
3. In game.nim update: call `updateAnimation(c, dt)` for each character every frame
4. In renderer.nim: use `drawX()`, `drawY()`, `drawWidth()`, `drawHeight()` instead of raw x,y,width,height when rendering characters
5. In renderer.nim: apply `idleSway()` as a slight y-offset when drawing idle characters
6. In renderer.nim: render contentment glow (bright additive overlay at low alpha) when contentment > 0.3

## Acceptance criteria
- Characters squash on landing and stretch on jump
- Idle characters gently sway
- Characters glow warmly when at their exit
- Visual feel is smooth and alive
- `make test` passes
