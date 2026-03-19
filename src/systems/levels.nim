## Level definitions for Together

import "../entities/level"

const level1* = Level(
  id: 1,
  name: "Awakening",
  narration: "Pip woke up. This was unusual, because Pip had never been asleep.",
  characters: @["pip"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 280.0, height: 20.0),   # ground left
    Platform(x: 350.0, y: 420.0, width: 100.0, height: 20.0),   # stepping stone
    Platform(x: 520.0, y: 460.0, width: 280.0, height: 20.0),   # ground right
  ],
  hazards: @[],
  exits: @[
    Exit(x: 720.0, y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
  ],
  buttons: @[],
  doors: @[],
  levelWidth: 800.0,
  levelHeight: 500.0,
)

const level2* = Level(
  id: 2,
  name: "First Steps",
  narration: "Pip discovered she could jump again. Higher this time.",
  characters: @["pip"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 200.0, height: 20.0),   # ground
    Platform(x: 250.0, y: 420.0, width: 80.0,  height: 20.0),   # step 1
    Platform(x: 380.0, y: 460.0, width: 420.0, height: 20.0),   # ground right
  ],
  hazards: @[
    Hazard(x: 200.0, y: 470.0, width: 50.0, height: 10.0),
  ],
  exits: @[
    Exit(x: 720.0, y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
  ],
  buttons: @[],
  doors: @[],
  levelWidth: 800.0,
  levelHeight: 500.0,
)

const level3* = Level(
  id: 3,
  name: "Questions",
  narration: "How high could she go? Pip wanted to find out.",
  characters: @["pip"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 150.0, height: 20.0),   # ground
    Platform(x: 200.0, y: 400.0, width: 80.0,  height: 20.0),   # stair 1
    Platform(x: 350.0, y: 320.0, width: 80.0,  height: 20.0),   # stair 2
    Platform(x: 500.0, y: 240.0, width: 80.0,  height: 20.0),   # stair 3
    Platform(x: 650.0, y: 160.0, width: 120.0, height: 20.0),   # top
  ],
  hazards: @[],
  exits: @[
    Exit(x: 680.0, y: 110.0, width: 40.0, height: 50.0, characterId: "pip"),
  ],
  buttons: @[],
  doors: @[],
  levelWidth: 800.0,
  levelHeight: 500.0,
)

const level4* = Level(
  id: 4,
  name: "Becoming",
  narration: "She was pink. She was small. She was brave.",
  characters: @["pip"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 120.0, height: 20.0),
    Platform(x: 180.0, y: 400.0, width: 80.0,  height: 20.0),
    Platform(x: 320.0, y: 340.0, width: 80.0,  height: 20.0),
    Platform(x: 200.0, y: 260.0, width: 80.0,  height: 20.0),   # double jump needed
    Platform(x: 380.0, y: 200.0, width: 80.0,  height: 20.0),
    Platform(x: 550.0, y: 260.0, width: 80.0,  height: 20.0),
    Platform(x: 650.0, y: 460.0, width: 200.0, height: 20.0),   # landing
    Platform(x: 870.0, y: 460.0, width: 130.0, height: 20.0),   # far ground
  ],
  hazards: @[
    Hazard(x: 120.0, y: 470.0, width: 530.0, height: 10.0),     # pit
  ],
  exits: @[
    Exit(x: 920.0, y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
  ],
  buttons: @[],
  doors: @[],
  levelWidth: 1000.0,
  levelHeight: 500.0,
)

const level5* = Level(
  id: 5,
  name: "Two Minds",
  narration: "Luca was yellow. Luca could float. Together they understood more.",
  characters: @["pip", "luca"],
  platforms: @[
    Platform(x: 0.0,    y: 260.0, width: 240.0, height: 20.0),   # start platform (high)
    Platform(x: 300.0,  y: 340.0, width: 110.0, height: 20.0),   # pip route (double jump)
    Platform(x: 300.0,  y: 410.0, width: 110.0, height: 20.0),   # luca route (float down)
    Platform(x: 500.0,  y: 460.0, width: 110.0, height: 20.0),   # landing
    Platform(x: 630.0,  y: 460.0, width: 170.0, height: 20.0),   # mid ground
    Platform(x: 850.0,  y: 380.0, width: 100.0, height: 20.0),   # upper bridge
    Platform(x: 1000.0, y: 460.0, width: 200.0, height: 20.0),   # far ground
  ],
  hazards: @[
    Hazard(x: 420.0, y: 470.0, width: 70.0,  height: 10.0),
    Hazard(x: 800.0, y: 470.0, width: 50.0,  height: 10.0),
  ],
  exits: @[
    Exit(x: 1080.0, y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 1140.0, y: 410.0, width: 40.0, height: 50.0, characterId: "luca"),
  ],
  buttons: @[],
  doors: @[],
  movingPlatforms: @[
    MovingPlatform(startX: 410.0, startY: 460.0, endX: 620.0, endY: 460.0,
                   width: 100.0, height: 20.0, speed: 0.3,
                   x: 410.0, y: 460.0, prevX: 410.0, prevY: 460.0, forward: true),
  ],
  levelWidth: 1200.0,
  levelHeight: 500.0,
)

const level6* = Level(
  id: 6,
  name: "The Weight of Things",
  narration: "Bruno was brown. Bruno was big. Bruno was heavy. He couldn't jump very high.",
  characters: @["pip", "luca", "bruno"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 340.0, height: 20.0),  # left ground
    Platform(x: 420.0, y: 460.0, width: 380.0, height: 20.0),  # right ground
  ],
  hazards: @[],
  exits: @[
    Exit(x: 80.0,  y: 410.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 620.0, y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 700.0, y: 410.0, width: 40.0, height: 50.0, characterId: "luca"),
  ],
  buttons: @[
    Button(x: 250.0, y: 450.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: true),
  ],
  doors: @[
    Door(id: 1, x: 370.0, y: 380.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  levelWidth: 800.0,
  levelHeight: 500.0,
)

const level7* = Level(
  id: 7,
  name: "What Bruno Holds",
  narration: "'I slow everyone down,' Bruno said. 'No,' Pip replied. 'You hold everything together.'",
  characters: @["pip", "luca", "bruno"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 380.0, height: 20.0),  # left ground (button side)
    Platform(x: 480.0, y: 460.0, width: 520.0, height: 20.0),  # right ground (exit side)
    Platform(x: 200.0, y: 340.0, width: 120.0, height: 20.0),  # elevated platform
  ],
  hazards: @[],
  exits: @[
    Exit(x: 140.0, y: 410.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 700.0, y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 800.0, y: 410.0, width: 40.0, height: 50.0, characterId: "luca"),
  ],
  buttons: @[
    Button(x: 280.0, y: 450.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: true),
  ],
  doors: @[
    Door(id: 1, x: 430.0, y: 380.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  movingPlatforms: @[
    MovingPlatform(startX: 850.0, startY: 460.0, endX: 850.0, endY: 300.0,
                   width: 100.0, height: 20.0, speed: 0.35,
                   x: 850.0, y: 460.0, prevX: 850.0, prevY: 460.0, forward: true),
  ],
  levelWidth: 1000.0,
  levelHeight: 500.0,
)

const level8* = Level(
  id: 8,
  name: "Walls",
  narration: "Cara was small. Cara was light pink. Cara could climb where others could not.",
  characters: @["pip", "bruno", "cara"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 800.0, height: 20.0),  # ground
    Platform(x: 340.0, y: 380.0, width: 20.0,  height: 80.0),  # left wall pillar
    Platform(x: 440.0, y: 380.0, width: 20.0,  height: 80.0),  # right wall pillar
    Platform(x: 340.0, y: 200.0, width: 120.0, height: 20.0),  # top platform (button)
    Platform(x: 600.0, y: 360.0, width: 160.0, height: 20.0),  # pip/bruno platform
  ],
  hazards: @[],
  exits: @[
    Exit(x: 60.0,  y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 140.0, y: 410.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 620.0, y: 310.0, width: 40.0, height: 50.0, characterId: "cara"),
  ],
  buttons: @[
    Button(x: 370.0, y: 190.0, width: 30.0, height: 10.0, doorId: 1, requiresHeavy: false),
  ],
  doors: @[
    Door(id: 1, x: 550.0, y: 360.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  levelWidth: 800.0,
  levelHeight: 500.0,
)

const level9* = Level(
  id: 9,
  name: "Apart",
  narration: "Four shapes. Four colors. They were beginning to understand.",
  characters: @["pip", "luca", "bruno", "cara"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 300.0, height: 20.0),  # left ground
    Platform(x: 380.0, y: 460.0, width: 240.0, height: 20.0),  # mid ground
    Platform(x: 700.0, y: 460.0, width: 300.0, height: 20.0),  # right ground
    Platform(x: 100.0, y: 320.0, width: 120.0, height: 20.0),  # left upper
    Platform(x: 500.0, y: 300.0, width: 100.0, height: 20.0),  # mid upper
    Platform(x: 780.0, y: 340.0, width: 140.0, height: 20.0),  # right upper
    Platform(x: 430.0, y: 380.0, width: 20.0,  height: 80.0),  # wall pillar for cara
    Platform(x: 530.0, y: 380.0, width: 20.0,  height: 80.0),  # wall pillar for cara
  ],
  hazards: @[
    Hazard(x: 300.0, y: 470.0, width: 80.0, height: 10.0),   # gap 1
    Hazard(x: 620.0, y: 470.0, width: 80.0, height: 10.0),   # gap 2
  ],
  exits: @[
    Exit(x: 40.0,  y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 160.0, y: 410.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 420.0, y: 410.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 810.0, y: 290.0, width: 40.0, height: 50.0, characterId: "cara"),
  ],
  buttons: @[
    Button(x: 120.0, y: 310.0, width: 30.0, height: 10.0, doorId: 1, requiresHeavy: false),
    Button(x: 800.0, y: 330.0, width: 40.0, height: 10.0, doorId: 2, requiresHeavy: true),
  ],
  doors: @[
    Door(id: 1, x: 330.0, y: 380.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 2, x: 650.0, y: 380.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  movingPlatforms: @[
    MovingPlatform(startX: 300.0, startY: 460.0, endX: 620.0, endY: 460.0,
                   width: 80.0, height: 20.0, speed: 0.4,
                   x: 300.0, y: 460.0, prevX: 300.0, prevY: 460.0, forward: true),
  ],
  levelWidth: 1000.0,
  levelHeight: 500.0,
)

const level10* = Level(
  id: 10,
  name: "Trust",
  narration: "Trust was not a feeling. Trust was a choice.",
  characters: @["pip", "luca", "bruno", "cara"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 280.0, height: 20.0),  # left ground (bruno side)
    Platform(x: 360.0, y: 460.0, width: 440.0, height: 20.0),  # right ground (others)
    Platform(x: 100.0, y: 320.0, width: 120.0, height: 20.0),  # bruno upper platform
    Platform(x: 480.0, y: 340.0, width: 200.0, height: 20.0),  # exit platform
    Platform(x: 420.0, y: 380.0, width: 20.0,  height: 80.0),  # wall for cara
    Platform(x: 340.0, y: 380.0, width: 20.0,  height: 80.0),  # other wall for cara
  ],
  hazards: @[],
  exits: @[
    Exit(x: 40.0,  y: 410.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 520.0, y: 290.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 600.0, y: 290.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 680.0, y: 290.0, width: 40.0, height: 50.0, characterId: "cara"),
  ],
  buttons: @[
    Button(x: 140.0, y: 310.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: true),
  ],
  doors: @[
    Door(id: 1, x: 440.0, y: 300.0, width: 20.0, height: 60.0, isOpen: false),
  ],
  levelWidth: 800.0,
  levelHeight: 500.0,
)

const level11* = Level(
  id: 11,
  name: "Patience",
  narration: "Felix was patient. Felix never rushed. Some edges needed faith.",
  characters: @["pip", "bruno", "felix"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 150.0, height: 20.0),   # start
    Platform(x: 300.0, y: 460.0, width: 100.0, height: 20.0),   # island 1
    Platform(x: 550.0, y: 460.0, width: 100.0, height: 20.0),   # island 2
    Platform(x: 800.0, y: 460.0, width: 200.0, height: 20.0),   # end ground
  ],
  hazards: @[
    Hazard(x: 150.0, y: 470.0, width: 150.0, height: 10.0),     # gap 1
    Hazard(x: 400.0, y: 470.0, width: 150.0, height: 10.0),     # gap 2
    Hazard(x: 650.0, y: 470.0, width: 150.0, height: 10.0),     # gap 3
  ],
  exits: @[
    Exit(x: 860.0, y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 920.0, y: 410.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 950.0, y: 410.0, width: 40.0, height: 50.0, characterId: "felix"),
  ],
  buttons: @[
    Button(x: 330.0, y: 450.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: true),
  ],
  doors: @[
    Door(id: 1, x: 750.0, y: 380.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  levelWidth: 1000.0,
  levelHeight: 500.0,
)

const level12* = Level(
  id: 12,
  name: "The Quiet One",
  narration: "Ivy fell slowly. Ivy fell gracefully. The ground was always kind to Ivy.",
  characters: @["pip", "luca", "ivy"],
  platforms: @[
    Platform(x: 0.0,   y: 100.0, width: 200.0, height: 20.0),   # high start
    Platform(x: 300.0, y: 250.0, width: 120.0, height: 20.0),   # mid ledge
    Platform(x: 500.0, y: 400.0, width: 120.0, height: 20.0),   # lower ledge
    Platform(x: 0.0,   y: 460.0, width: 900.0, height: 20.0),   # ground
  ],
  hazards: @[
    Hazard(x: 200.0, y: 470.0, width: 100.0, height: 10.0),     # gap in ground
  ],
  exits: @[
    Exit(x: 720.0, y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 780.0, y: 410.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 840.0, y: 410.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[],
  doors: @[],
  levelWidth: 900.0,
  levelHeight: 500.0,
)

const level13* = Level(
  id: 13,
  name: "Six",
  narration: "Six shapes. Six colors. Six ways of being in the world.",
  characters: @["pip", "luca", "bruno", "cara", "felix", "ivy"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 350.0, height: 20.0),   # left ground
    Platform(x: 450.0, y: 460.0, width: 350.0, height: 20.0),   # right ground
    Platform(x: 200.0, y: 360.0, width: 120.0, height: 20.0),   # left upper
    Platform(x: 500.0, y: 360.0, width: 120.0, height: 20.0),   # right upper
  ],
  hazards: @[],
  exits: @[
    Exit(x: 40.0,  y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 120.0, y: 410.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 200.0, y: 410.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 500.0, y: 410.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 580.0, y: 410.0, width: 40.0, height: 50.0, characterId: "felix"),
    Exit(x: 660.0, y: 410.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[],
  doors: @[],
  levelWidth: 800.0,
  levelHeight: 500.0,
)

const level14* = Level(
  id: 14,
  name: "Hazards",
  narration: "The world had sharp edges. But they had each other.",
  characters: @["pip", "luca", "bruno", "cara", "felix", "ivy"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 200.0, height: 20.0),   # start ground
    Platform(x: 280.0, y: 400.0, width: 120.0, height: 20.0),   # mid platform 1
    Platform(x: 480.0, y: 340.0, width: 120.0, height: 20.0),   # mid platform 2
    Platform(x: 680.0, y: 460.0, width: 320.0, height: 20.0),   # end ground
  ],
  hazards: @[
    Hazard(x: 200.0, y: 470.0, width: 80.0,  height: 10.0),     # spikes below gap 1
    Hazard(x: 400.0, y: 470.0, width: 80.0,  height: 10.0),     # spikes below gap 2
    Hazard(x: 600.0, y: 470.0, width: 80.0,  height: 10.0),     # spikes below gap 3
  ],
  exits: @[
    Exit(x: 700.0, y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 750.0, y: 410.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 800.0, y: 410.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 850.0, y: 410.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 900.0, y: 410.0, width: 40.0, height: 50.0, characterId: "felix"),
    Exit(x: 950.0, y: 410.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[
    Button(x: 100.0, y: 450.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: true),
  ],
  doors: @[
    Door(id: 1, x: 650.0, y: 380.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  levelWidth: 1000.0,
  levelHeight: 500.0,
)

const level15* = Level(
  id: 15,
  name: "Rising",
  narration: "Up. They had always been going up. They just hadn't noticed.",
  characters: @["pip", "luca", "bruno", "cara", "felix", "ivy"],
  platforms: @[
    Platform(x: 0.0,   y: 960.0, width: 800.0, height: 20.0),   # ground
    Platform(x: 100.0, y: 800.0, width: 200.0, height: 20.0),   # tier 1 left
    Platform(x: 500.0, y: 700.0, width: 200.0, height: 20.0),   # tier 2 right
    Platform(x: 100.0, y: 600.0, width: 200.0, height: 20.0),   # tier 3 left
    Platform(x: 500.0, y: 500.0, width: 200.0, height: 20.0),   # tier 4 right
    Platform(x: 100.0, y: 400.0, width: 200.0, height: 20.0),   # tier 5 left
    Platform(x: 400.0, y: 300.0, width: 300.0, height: 20.0),   # top platform
    # wall-jump pillars for Cara
    Platform(x: 380.0, y: 700.0, width: 20.0,  height: 100.0),  # pillar left
    Platform(x: 420.0, y: 700.0, width: 20.0,  height: 100.0),  # pillar right
  ],
  hazards: @[],
  exits: @[
    Exit(x: 420.0, y: 250.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 480.0, y: 250.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 540.0, y: 250.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 600.0, y: 250.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 460.0, y: 250.0, width: 40.0, height: 50.0, characterId: "felix"),
    Exit(x: 520.0, y: 250.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[],
  doors: @[],
  levelWidth: 800.0,
  levelHeight: 1000.0,
)

const allLevels*: array[15, Level] = [level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, level11, level12, level13, level14, level15]
