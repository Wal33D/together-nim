# Implement button and door interaction mechanics

**Area:** physics
**Depends:** 0015

In `src/systems/physics.nim`, add button/door interaction:
1. Check if any character is standing on a button (overlapping the button rect while grounded)
2. If button has `requiresHeavy = true`, only Bruno (ability == heavy) can press it
3. When a button is pressed, find the door with matching `doorId` and set `isOpen = true`
4. When no character is on the button, set the door back to `isOpen = false`
5. The level's doors seq needs to be mutable — change `updatePhysics` to take `var Level` or track door state in Game

Also wire wall-jump for Cara:
- Detect when Cara is touching a platform's side while airborne
- Allow jump when touching wall (set vy to jumpForce, flip vx direction)
- Visual: Cara slides slowly down walls (cap vy at 120 px/s when wall-sliding)

## Acceptance criteria
- Buttons open corresponding doors when stood on
- Heavy buttons only respond to Bruno
- Doors close when character leaves button
- Cara can wall-jump off platform sides
- `make test` passes
