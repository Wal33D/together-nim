## Smooth follow camera for Together

import "../constants"

const LERP_FACTOR* = 0.08

type
  Camera* = object
    x*, y*: float        # current world coord of screen top-left
    targetX*, targetY*: float

proc newCamera*(): Camera =
  Camera(x: 0.0, y: 0.0, targetX: 0.0, targetY: 0.0)

proc updateCamera*(cam: var Camera, charX, charY, charW, charH: float,
                   levelWidth, levelHeight: float) =
  # Center screen on character
  cam.targetX = charX + charW * 0.5 - float(DEFAULT_WIDTH) * 0.5
  cam.targetY = charY + charH * 0.5 - float(DEFAULT_HEIGHT) * 0.5

  # Lerp toward target
  cam.x += (cam.targetX - cam.x) * LERP_FACTOR
  cam.y += (cam.targetY - cam.y) * LERP_FACTOR

  # Clamp to level bounds
  let maxX = max(0.0, levelWidth - float(DEFAULT_WIDTH))
  let maxY = max(0.0, levelHeight - float(DEFAULT_HEIGHT))
  if cam.x < 0.0: cam.x = 0.0
  elif cam.x > maxX: cam.x = maxX
  if cam.y < 0.0: cam.y = 0.0
  elif cam.y > maxY: cam.y = maxY

proc snapCamera*(cam: var Camera, charX, charY, charW, charH: float,
                 levelWidth, levelHeight: float) =
  ## Instantly position camera on character (no lerp) — use on level load
  cam.targetX = charX + charW * 0.5 - float(DEFAULT_WIDTH) * 0.5
  cam.targetY = charY + charH * 0.5 - float(DEFAULT_HEIGHT) * 0.5

  let maxX = max(0.0, levelWidth - float(DEFAULT_WIDTH))
  let maxY = max(0.0, levelHeight - float(DEFAULT_HEIGHT))
  cam.x = max(0.0, min(cam.targetX, maxX))
  cam.y = max(0.0, min(cam.targetY, maxY))
