## Level entity types

import
  std/math

type
  Platform* = object
    x*, y*: float
    width*, height*: float

  Hazard* = object
    x*, y*: float
    width*, height*: float

  Exit* = object
    x*, y*: float
    width*, height*: float
    characterId*: string
    sharedExit*: bool

  Button* = object
    x*, y*: float
    width*, height*: float
    doorId*: int
    requiresHeavy*: bool
    active*: bool
    prevActive*: bool

  Door* = object
    id*: int
    x*, y*: float
    width*, height*: float
    isOpen*: bool

  MovingPlatform* = object
    waypoints*: seq[tuple[x, y: float]]
    width*, height*: float
    speed*: float             # px/s
    currentWaypoint*: int     # index of current origin waypoint
    progress*: float          # 0.0-1.0 between current and next waypoint
    pingPong*: bool           # true = reverse, false = loop
    forward*: bool            # direction for ping-pong
    x*, y*: float             # current rendered position
    prevX*, prevY*: float     # previous frame position (for rider displacement)

  StarChallenge* = object
    timeTarget*: float        # seconds to beat for time star (0 = no time challenge)
    secretX*, secretY*: float # position of secret collectible (0,0 = none)

  Level* = object
    id*: int
    name*: string
    narration*: string
    characters*: seq[string]
    platforms*: seq[Platform]
    hazards*: seq[Hazard]
    exits*: seq[Exit]
    buttons*: seq[Button]
    doors*: seq[Door]
    movingPlatforms*: seq[MovingPlatform]
    starChallenge*: StarChallenge
    interLevelNarration*: string
    levelWidth*: float
    levelHeight*: float

proc newMovingPlatform*(startX, startY, endX, endY, width, height, speed: float): MovingPlatform =
  ## Migration constructor: converts old two-point linear params to waypoint system.
  let dx = endX - startX
  let dy = endY - startY
  let dist = sqrt(dx * dx + dy * dy)
  let pxSpeed = if dist > 0.0: speed * dist else: speed
  MovingPlatform(
    waypoints: @[(x: startX, y: startY), (x: endX, y: endY)],
    width: width, height: height,
    speed: pxSpeed, currentWaypoint: 0, progress: 0.0,
    pingPong: true, forward: true,
    x: startX, y: startY,
    prevX: startX, prevY: startY,
  )
