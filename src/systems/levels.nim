## Level definitions for Together (Act 1: Awakening)

import "../entities/level"

const level1* = Level(
  id: 1,
  name: "Awakening",
  narration: "Pip woke up.",
  characters: @["pip"],
  platforms: @[
    Platform(x: 0.0,   y: 620.0, width: 1280.0, height: 20.0),  # ground
    Platform(x: 200.0, y: 480.0, width: 200.0,  height: 20.0),  # mid platform
    Platform(x: 500.0, y: 360.0, width: 200.0,  height: 20.0),  # upper platform
  ],
  hazards: @[],
  exits: @[
    Exit(x: 1180.0, y: 570.0, width: 40.0, height: 50.0, characterId: "pip"),
  ],
  buttons: @[],
  doors: @[],
)

const level2* = Level(
  id: 2,
  name: "Higher Ground",
  narration: "Pip discovers her double jump.",
  characters: @["pip"],
  platforms: @[
    Platform(x: 0.0,   y: 620.0, width: 400.0,  height: 20.0),  # ground left
    Platform(x: 500.0, y: 480.0, width: 180.0,  height: 20.0),  # mid 1
    Platform(x: 750.0, y: 340.0, width: 180.0,  height: 20.0),  # mid 2 (requires double jump)
    Platform(x: 1000.0, y: 200.0, width: 280.0, height: 20.0),  # high platform
  ],
  hazards: @[
    Hazard(x: 400.0, y: 600.0, width: 100.0, height: 20.0),     # gap with spikes
  ],
  exits: @[
    Exit(x: 1180.0, y: 150.0, width: 40.0, height: 50.0, characterId: "pip"),
  ],
  buttons: @[],
  doors: @[],
)

const level3* = Level(
  id: 3,
  name: "Together",
  narration: "Pip finds Luca. Together they can reach new places.",
  characters: @["pip", "luca"],
  platforms: @[
    Platform(x: 0.0,   y: 620.0, width: 500.0,  height: 20.0),  # ground left
    Platform(x: 600.0, y: 620.0, width: 680.0,  height: 20.0),  # ground right
    Platform(x: 250.0, y: 460.0, width: 200.0,  height: 20.0),  # mid left
    Platform(x: 700.0, y: 320.0, width: 200.0,  height: 20.0),  # high right (luca floats here)
    Platform(x: 500.0, y: 180.0, width: 280.0,  height: 20.0),  # top center
  ],
  hazards: @[
    Hazard(x: 500.0, y: 600.0, width: 100.0, height: 20.0),     # gap
  ],
  exits: @[
    Exit(x: 80.0,   y: 570.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 1180.0, y: 130.0, width: 40.0, height: 50.0, characterId: "luca"),
  ],
  buttons: @[],
  doors: @[],
)

const allLevels*: array[3, Level] = [level1, level2, level3]
