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
    levelWidth*: float
    levelHeight*: float
