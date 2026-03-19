## Character entity type and factory

import "../constants"

type
  CharacterAbility* = enum
    doubleJump, floatAbility, heavy, wallJump, coyoteTime, gracefulFall

  Character* = object
    id*: string
    x*, y*: float
    width*, height*: int
    color*: Color
    vx*, vy*: float
    grounded*: bool
    facingRight*: bool
    ability*: CharacterAbility

proc newCharacter*(id: string): Character =
  result.x = 0.0
  result.y = 0.0
  result.vx = 0.0
  result.vy = 0.0
  result.grounded = false
  result.facingRight = true
  result.id = id
  case id
  of "pip":
    result.width = 30
    result.height = 30
    result.color = (r: 255'u8, g: 182'u8, b: 193'u8)  # pink
    result.ability = doubleJump
  of "luca":
    result.width = 25
    result.height = 40
    result.color = (r: 255'u8, g: 220'u8, b: 50'u8)   # yellow
    result.ability = floatAbility
  of "bruno":
    result.width = 50
    result.height = 50
    result.color = (r: 139'u8, g: 90'u8, b: 43'u8)    # brown
    result.ability = heavy
  of "cara":
    result.width = 20
    result.height = 45
    result.color = (r: 255'u8, g: 210'u8, b: 220'u8)  # light pink
    result.ability = wallJump
  of "felix":
    result.width = 35
    result.height = 35
    result.color = (r: 210'u8, g: 180'u8, b: 140'u8)  # tan
    result.ability = coyoteTime
  of "ivy":
    result.width = 28
    result.height = 42
    result.color = (r: 0'u8, g: 128'u8, b: 128'u8)    # teal
    result.ability = gracefulFall
  else:
    result.width = CHAR_WIDTH
    result.height = CHAR_HEIGHT
    result.color = (r: 128'u8, g: 128'u8, b: 128'u8)
    result.ability = doubleJump
