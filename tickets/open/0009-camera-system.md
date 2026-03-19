# Implement smooth follow camera

**Area:** rendering
**Depends:** 0008

Implement `src/systems/camera.nim`:
- Camera type with: x, y, targetX, targetY, viewportWidth, viewportHeight
- `updateCamera(camera, target, dt)` — smooth lerp follow toward active character
- `applyCamera(renderer, camera)` — offset all rendering by camera position
- Viewport bounds clamping to level edges
- Integrate camera into renderer (all draw calls offset by camera)

## Acceptance criteria
- Camera smoothly follows active character
- Switching characters smoothly pans to new target
- Camera doesn't go outside level bounds
- `make test` passes
