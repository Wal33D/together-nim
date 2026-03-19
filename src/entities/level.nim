## Level entity types

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

  Button* = object
    x*, y*: float
    width*, height*: float
    doorId*: int
    requiresHeavy*: bool

  Door* = object
    id*: int
    x*, y*: float
    width*, height*: float
    isOpen*: bool

  MovingPlatform* = object
    startX*, startY*: float
    endX*, endY*: float
    width*, height*: float
    speed*: float          # 0.0-1.0 interpolation speed per second
    currentT*: float       # 0.0-1.0 interpolation parameter
    forward*: bool         # ping-pong direction
    x*, y*: float          # current rendered position
    prevX*, prevY*: float  # previous frame position (for rider displacement)

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
    levelWidth*: float
    levelHeight*: float

proc newMovingPlatform*(startX, startY, endX, endY, width, height, speed: float): MovingPlatform =
  MovingPlatform(
    startX: startX, startY: startY,
    endX: endX, endY: endY,
    width: width, height: height,
    speed: speed, currentT: 0.0, forward: true,
    x: startX, y: startY,
    prevX: startX, prevY: startY,
  )
