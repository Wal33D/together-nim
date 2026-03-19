## Game state machine and update logic for Together

type
  GameState* = enum
    menu, playing, paused, credits

  Character* = object
    x*, y*: float
    colorIndex*: int

  Game* = object
    state*: GameState
    currentLevel*: int
    characters*: seq[Character]
    activeCharacterIndex*: int
    deltaTime*: float

const
  SCANCODE_RETURN* = 40.cint
  SCANCODE_ESCAPE* = 41.cint

proc newGame*(): Game =
  Game(
    state: menu,
    currentLevel: 0,
    characters: @[],
    activeCharacterIndex: 0,
    deltaTime: 0.0
  )

proc handleKey*(game: var Game, scancode: cint) =
  case game.state
  of menu:
    if scancode == SCANCODE_RETURN:
      game.state = playing
  of playing:
    if scancode == SCANCODE_ESCAPE:
      game.state = paused
  of paused:
    if scancode == SCANCODE_ESCAPE:
      game.state = playing
  of credits:
    discard

proc update*(game: var Game, dt: float) =
  game.deltaTime = dt
