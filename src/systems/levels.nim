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
  starChallenge: StarChallenge(timeTarget: 30.0, secretX: 370.0, secretY: 395.0),
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
  starChallenge: StarChallenge(timeTarget: 35.0, secretX: 270.0, secretY: 395.0),
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
  starChallenge: StarChallenge(timeTarget: 40.0, secretX: 750.0, secretY: 135.0),
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
  starChallenge: StarChallenge(timeTarget: 45.0, secretX: 400.0, secretY: 175.0),
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
    MovingPlatform(waypoints: @[(x: 410.0, y: 460.0), (x: 620.0, y: 460.0)],
                   width: 100.0, height: 20.0, speed: 63.0,
                   pingPong: true, forward: true,
                   x: 410.0, y: 460.0, prevX: 410.0, prevY: 460.0),
  ],
  starChallenge: StarChallenge(timeTarget: 50.0, secretX: 880.0, secretY: 355.0),
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
  starChallenge: StarChallenge(timeTarget: 55.0, secretX: 380.0, secretY: 355.0),
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
    MovingPlatform(waypoints: @[(x: 850.0, y: 460.0), (x: 850.0, y: 300.0)],
                   width: 100.0, height: 20.0, speed: 56.0,
                   pingPong: true, forward: true,
                   x: 850.0, y: 460.0, prevX: 850.0, prevY: 460.0),
  ],
  starChallenge: StarChallenge(timeTarget: 60.0, secretX: 240.0, secretY: 315.0),
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
  starChallenge: StarChallenge(timeTarget: 65.0, secretX: 380.0, secretY: 175.0),
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
    MovingPlatform(waypoints: @[(x: 300.0, y: 460.0), (x: 460.0, y: 440.0), (x: 620.0, y: 460.0)],
                   width: 80.0, height: 20.0, speed: 128.0,
                   pingPong: true, forward: true,
                   x: 300.0, y: 460.0, prevX: 300.0, prevY: 460.0),
  ],
  starChallenge: StarChallenge(timeTarget: 70.0, secretX: 530.0, secretY: 275.0),
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
  starChallenge: StarChallenge(timeTarget: 75.0, secretX: 140.0, secretY: 295.0),
  levelWidth: 800.0,
  levelHeight: 500.0,
)

const level11* = Level(
  id: 11,
  name: "Patience",
  narration: "Felix was patient. Felix never rushed. Some edges needed faith.",
  characters: @["pip", "bruno", "felix"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 160.0, height: 20.0),   # start ground
    Platform(x: 300.0, y: 460.0, width: 100.0, height: 20.0),   # island 1 (long gap)
    Platform(x: 540.0, y: 460.0, width: 100.0, height: 20.0),   # island 2 (long gap)
    Platform(x: 780.0, y: 460.0, width: 220.0, height: 20.0),   # end ground
  ],
  hazards: @[
    Hazard(x: 160.0, y: 470.0, width: 140.0, height: 10.0),     # gap 1
    Hazard(x: 400.0, y: 470.0, width: 140.0, height: 10.0),     # gap 2
    Hazard(x: 640.0, y: 470.0, width: 140.0, height: 10.0),     # gap 3
  ],
  exits: @[
    Exit(x: 820.0, y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 880.0, y: 410.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 940.0, y: 410.0, width: 40.0, height: 50.0, characterId: "felix"),
  ],
  buttons: @[],
  doors: @[],
  starChallenge: StarChallenge(timeTarget: 80.0, secretX: 570.0, secretY: 435.0),
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
    Platform(x: 550.0, y: 400.0, width: 120.0, height: 20.0),   # lower ledge
    Platform(x: 0.0,   y: 460.0, width: 800.0, height: 20.0),   # ground
  ],
  hazards: @[
    Hazard(x: 200.0, y: 470.0, width: 100.0, height: 10.0),     # spikes on ground gaps
    Hazard(x: 420.0, y: 470.0, width: 130.0, height: 10.0),
  ],
  exits: @[
    Exit(x: 680.0, y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 730.0, y: 410.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 580.0, y: 350.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[],
  doors: @[],
  starChallenge: StarChallenge(timeTarget: 85.0, secretX: 170.0, secretY: 75.0),
  levelWidth: 800.0,
  levelHeight: 500.0,
)

const level13* = Level(
  id: 13,
  name: "Six",
  narration: "Six shapes. Six colors. Six ways of being in the world.",
  characters: @["pip", "luca", "bruno", "cara", "felix", "ivy"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 300.0, height: 20.0),   # left ground
    Platform(x: 380.0, y: 460.0, width: 200.0, height: 20.0),   # middle ground
    Platform(x: 660.0, y: 460.0, width: 300.0, height: 20.0),   # right ground
    Platform(x: 150.0, y: 360.0, width: 120.0, height: 20.0),   # left upper
    Platform(x: 500.0, y: 340.0, width: 120.0, height: 20.0),   # middle upper
    Platform(x: 750.0, y: 360.0, width: 120.0, height: 20.0),   # right upper
  ],
  hazards: @[],
  exits: @[
    Exit(x: 40.0,  y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 120.0, y: 410.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 200.0, y: 410.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 700.0, y: 410.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 780.0, y: 410.0, width: 40.0, height: 50.0, characterId: "felix"),
    Exit(x: 860.0, y: 410.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[],
  doors: @[],
  movingPlatforms: @[
    MovingPlatform(waypoints: @[(x: 260.0, y: 460.0), (x: 580.0, y: 460.0)],
                   width: 100.0, height: 20.0, speed: 70.0,
                   pingPong: true, forward: true,
                   x: 260.0, y: 460.0, prevX: 260.0, prevY: 460.0),
  ],
  starChallenge: StarChallenge(timeTarget: 90.0, secretX: 540.0, secretY: 315.0),
  levelWidth: 960.0,
  levelHeight: 500.0,
)

const level14* = Level(
  id: 14,
  name: "Hazards",
  narration: "The world had sharp edges. But they had each other.",
  characters: @["pip", "luca", "bruno", "cara", "felix", "ivy"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 250.0, height: 20.0),   # left ground
    Platform(x: 350.0, y: 380.0, width: 140.0, height: 20.0),   # middle platform
    Platform(x: 590.0, y: 460.0, width: 250.0, height: 20.0),   # right ground
    Platform(x: 100.0, y: 320.0, width: 100.0, height: 20.0),   # left upper
    Platform(x: 650.0, y: 300.0, width: 100.0, height: 20.0),   # right upper
  ],
  hazards: @[
    Hazard(x: 250.0, y: 470.0, width: 100.0, height: 10.0),     # spikes below gap 1
    Hazard(x: 490.0, y: 470.0, width: 100.0, height: 10.0),     # spikes below gap 2
    Hazard(x: 370.0, y: 400.0, width: 100.0, height: 10.0),     # spikes on middle platform
  ],
  exits: @[
    Exit(x: 40.0,  y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 620.0, y: 410.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 700.0, y: 410.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 780.0, y: 410.0, width: 40.0, height: 50.0, characterId: "felix"),
    Exit(x: 670.0, y: 250.0, width: 40.0, height: 50.0, characterId: "ivy"),
    Exit(x: 120.0, y: 270.0, width: 40.0, height: 50.0, characterId: "bruno"),
  ],
  buttons: @[
    Button(x: 160.0, y: 450.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: true),
  ],
  doors: @[
    Door(id: 1, x: 540.0, y: 380.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  movingPlatforms: @[
    MovingPlatform(waypoints: @[(x: 230.0, y: 420.0), (x: 370.0, y: 420.0)],
                   width: 90.0, height: 20.0, speed: 55.0,
                   pingPong: true, forward: true,
                   x: 230.0, y: 420.0, prevX: 230.0, prevY: 420.0),
  ],
  starChallenge: StarChallenge(timeTarget: 95.0, secretX: 130.0, secretY: 295.0),
  levelWidth: 840.0,
  levelHeight: 500.0,
)

const level15* = Level(
  id: 15,
  name: "Rising",
  narration: "Up. They had always been going up. They just hadn't noticed.",
  characters: @["pip", "luca", "bruno", "cara", "felix", "ivy"],
  platforms: @[
    Platform(x: 0.0,   y: 960.0, width: 800.0, height: 20.0),   # ground
    Platform(x: 100.0, y: 860.0, width: 200.0, height: 20.0),   # tier 1 left
    Platform(x: 500.0, y: 780.0, width: 200.0, height: 20.0),   # tier 2 right
    Platform(x: 100.0, y: 680.0, width: 200.0, height: 20.0),   # tier 3 left
    Platform(x: 500.0, y: 580.0, width: 200.0, height: 20.0),   # tier 4 right
    Platform(x: 100.0, y: 480.0, width: 200.0, height: 20.0),   # tier 5 left
    Platform(x: 500.0, y: 380.0, width: 200.0, height: 20.0),   # tier 6 right
    Platform(x: 200.0, y: 280.0, width: 400.0, height: 20.0),   # top platform
    Platform(x: 370.0, y: 460.0, width: 20.0,  height: 200.0),  # wall-jump pillar left
    Platform(x: 430.0, y: 460.0, width: 20.0,  height: 200.0),  # wall-jump pillar right
  ],
  hazards: @[],
  exits: @[
    Exit(x: 240.0, y: 230.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 320.0, y: 230.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 400.0, y: 230.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 480.0, y: 230.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 340.0, y: 230.0, width: 40.0, height: 50.0, characterId: "felix"),
    Exit(x: 440.0, y: 230.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[],
  doors: @[],
  movingPlatforms: @[
    MovingPlatform(waypoints: @[(x: 720.0, y: 940.0), (x: 720.0, y: 350.0)],
                   width: 80.0, height: 20.0, speed: 80.0,
                   pingPong: true, forward: true,
                   x: 720.0, y: 940.0, prevX: 720.0, prevY: 940.0),
  ],
  starChallenge: StarChallenge(timeTarget: 100.0, secretX: 750.0, secretY: 935.0),
  levelWidth: 800.0,
  levelHeight: 1000.0,
)

const level16* = Level(
  id: 16,
  name: "Apart",
  narration: "For the first time, they couldn't see each other.",
  characters: @["pip", "luca", "bruno", "cara", "felix", "ivy"],
  platforms: @[
    Platform(x: 0.0,    y: 460.0, width: 680.0, height: 20.0),   # left ground
    Platform(x: 680.0,  y: 0.0,   width: 20.0,  height: 480.0),  # central wall
    Platform(x: 700.0,  y: 460.0, width: 700.0, height: 20.0),   # right ground
    Platform(x: 300.0,  y: 350.0, width: 150.0, height: 20.0),   # left upper platform
    Platform(x: 900.0,  y: 300.0, width: 20.0,  height: 160.0),  # right pillar left
    Platform(x: 1000.0, y: 300.0, width: 20.0,  height: 160.0),  # right pillar right
    Platform(x: 900.0,  y: 280.0, width: 120.0, height: 20.0),   # right wall-jump top
  ],
  hazards: @[],
  exits: @[
    Exit(x: 50.0,   y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 150.0,  y: 410.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 550.0,  y: 410.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 940.0,  y: 230.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 1200.0, y: 410.0, width: 40.0, height: 50.0, characterId: "felix"),
    Exit(x: 1300.0, y: 410.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[
    Button(x: 350.0,  y: 450.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: true),
    Button(x: 1100.0, y: 450.0, width: 40.0, height: 10.0, doorId: 2, requiresHeavy: false),
  ],
  doors: @[
    Door(id: 1, x: 500.0,  y: 380.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 2, x: 1150.0, y: 380.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  starChallenge: StarChallenge(timeTarget: 105.0, secretX: 650.0, secretY: 435.0),
  levelWidth: 1400.0,
  levelHeight: 500.0,
)

const level17* = Level(
  id: 17,
  name: "Trust Fall",
  narration: "Trust was not a feeling. Trust was a choice.",
  characters: @["pip", "bruno"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 1000.0, height: 20.0),   # full ground
    Platform(x: 480.0, y: 80.0,  width: 20.0,   height: 300.0),   # dividing wall
    Platform(x: 200.0, y: 300.0, width: 120.0,   height: 20.0),   # bruno button platform
    Platform(x: 700.0, y: 300.0, width: 120.0,   height: 20.0),   # pip stepping stone
    Platform(x: 700.0, y: 180.0, width: 120.0,   height: 20.0),   # pip exit platform
  ],
  hazards: @[],
  exits: @[
    Exit(x: 100.0, y: 410.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 730.0, y: 130.0, width: 40.0, height: 50.0, characterId: "pip"),
  ],
  buttons: @[
    Button(x: 240.0, y: 290.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: false),
  ],
  doors: @[
    Door(id: 1, x: 650.0, y: 220.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  starChallenge: StarChallenge(timeTarget: 80.0, secretX: 960.0, secretY: 435.0),
  levelWidth: 1000.0,
  levelHeight: 500.0,
)

const level18* = Level(
  id: 18,
  name: "Bridges",
  narration: "They were bridges for each other. They always had been.",
  characters: @["luca", "cara", "felix"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 1200.0, height: 20.0),   # ground
    Platform(x: 200.0, y: 350.0, width: 100.0,   height: 20.0),   # button platform 1 (felix)
    Platform(x: 520.0, y: 280.0, width: 20.0,    height: 180.0),  # wall-jump pillar left
    Platform(x: 660.0, y: 280.0, width: 20.0,    height: 180.0),  # wall-jump pillar right
    Platform(x: 520.0, y: 260.0, width: 160.0,   height: 20.0),   # button platform 2 (cara)
    Platform(x: 880.0, y: 380.0, width: 100.0,   height: 20.0),   # button platform 3 (luca)
  ],
  hazards: @[],
  exits: @[
    Exit(x: 370.0,  y: 410.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 740.0,  y: 410.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 1100.0, y: 410.0, width: 40.0, height: 50.0, characterId: "felix"),
  ],
  buttons: @[
    Button(x: 220.0, y: 340.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: false),
    Button(x: 570.0, y: 250.0, width: 40.0, height: 10.0, doorId: 2, requiresHeavy: false),
    Button(x: 900.0, y: 370.0, width: 40.0, height: 10.0, doorId: 3, requiresHeavy: false),
  ],
  doors: @[
    Door(id: 1, x: 330.0,  y: 380.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 2, x: 700.0,  y: 380.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 3, x: 1060.0, y: 380.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  starChallenge: StarChallenge(timeTarget: 100.0, secretX: 1150.0, secretY: 435.0),
  levelWidth: 1200.0,
  levelHeight: 500.0,
)

const level19* = Level(
  id: 19,
  name: "Missing",
  narration: "'Where were you?' Pip asked. 'Here,' said Bruno. 'Waiting.'",
  characters: @["pip", "luca", "bruno", "cara", "felix", "ivy"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 1200.0, height: 20.0),   # ground
    Platform(x: 150.0, y: 370.0, width: 80.0,    height: 20.0),   # pip stepping stone
    Platform(x: 350.0, y: 300.0, width: 80.0,    height: 20.0),   # pip upper platform
    Platform(x: 500.0, y: 360.0, width: 100.0,   height: 20.0),   # pip button platform
  ],
  hazards: @[
    Hazard(x: 280.0, y: 470.0, width: 100.0, height: 10.0),      # small gap
  ],
  exits: @[
    Exit(x: 900.0,  y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 960.0,  y: 410.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 1020.0, y: 410.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 1080.0, y: 410.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 940.0,  y: 410.0, width: 40.0, height: 50.0, characterId: "felix"),
    Exit(x: 1000.0, y: 410.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[
    Button(x: 520.0, y: 350.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: false),
  ],
  doors: @[
    Door(id: 1, x: 700.0, y: 380.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  movingPlatforms: @[
    MovingPlatform(waypoints: @[(x: 250.0, y: 430.0), (x: 400.0, y: 430.0)],
                   width: 90.0, height: 20.0, speed: 45.0,
                   pingPong: true, forward: true,
                   x: 250.0, y: 430.0, prevX: 250.0, prevY: 430.0),
  ],
  starChallenge: StarChallenge(timeTarget: 90.0, secretX: 380.0, secretY: 275.0),
  levelWidth: 1200.0,
  levelHeight: 500.0,
)

const level20* = Level(
  id: 20,
  name: "Home",
  narration: "Home was not a place. Home was who you were with.",
  characters: @["pip", "luca", "bruno", "cara", "felix", "ivy"],
  platforms: @[
    Platform(x: 0.0,    y: 560.0, width: 300.0, height: 20.0),   # start ground
    Platform(x: 400.0,  y: 560.0, width: 200.0, height: 20.0),   # platform after door 1
    Platform(x: 700.0,  y: 400.0, width: 20.0,  height: 180.0),  # wall-jump pillar left
    Platform(x: 800.0,  y: 400.0, width: 20.0,  height: 180.0),  # wall-jump pillar right
    Platform(x: 700.0,  y: 380.0, width: 120.0, height: 20.0),   # top of shaft (cara button)
    Platform(x: 900.0,  y: 560.0, width: 150.0, height: 20.0),   # platform after door 2
    Platform(x: 1100.0, y: 460.0, width: 100.0, height: 20.0),   # float target (luca button)
    Platform(x: 1200.0, y: 560.0, width: 200.0, height: 20.0),   # final area ground
    Platform(x: 1250.0, y: 380.0, width: 100.0, height: 20.0),   # high platform (pip double-jump)
  ],
  hazards: @[
    Hazard(x: 300.0,  y: 570.0, width: 100.0, height: 10.0),     # gap before door 1
    Hazard(x: 600.0,  y: 570.0, width: 100.0, height: 10.0),     # gap before wall section
    Hazard(x: 1050.0, y: 570.0, width: 150.0, height: 10.0),     # gap (float section)
  ],
  exits: @[
    Exit(x: 1220.0, y: 510.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 1260.0, y: 510.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 1300.0, y: 510.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 1340.0, y: 510.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 1240.0, y: 510.0, width: 40.0, height: 50.0, characterId: "felix"),
    Exit(x: 1280.0, y: 510.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[
    Button(x: 150.0,  y: 550.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: true),
    Button(x: 730.0,  y: 370.0, width: 40.0, height: 10.0, doorId: 2, requiresHeavy: false),
    Button(x: 1120.0, y: 450.0, width: 40.0, height: 10.0, doorId: 3, requiresHeavy: false),
    Button(x: 1270.0, y: 370.0, width: 40.0, height: 10.0, doorId: 4, requiresHeavy: false),
  ],
  doors: @[
    Door(id: 1, x: 360.0,  y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 2, x: 860.0,  y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 3, x: 1170.0, y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 4, x: 1380.0, y: 480.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  starChallenge: StarChallenge(timeTarget: 130.0, secretX: 750.0, secretY: 355.0),
  levelWidth: 1400.0,
  levelHeight: 600.0,
)

const level21* = Level(
  id: 21,
  name: "Memory",
  narration: "They remembered being alone. It felt like a dream now.",
  characters: @["pip", "luca", "bruno", "cara", "felix", "ivy"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 280.0, height: 20.0),   # ground left (level 1 echo)
    Platform(x: 350.0, y: 420.0, width: 100.0, height: 20.0),   # stepping stone (level 1 echo)
    Platform(x: 520.0, y: 460.0, width: 280.0, height: 20.0),   # ground right (level 1 echo)
    Platform(x: 850.0, y: 400.0, width: 100.0, height: 20.0),   # extended stepping stone
    Platform(x: 1000.0, y: 460.0, width: 200.0, height: 20.0),  # extended ground
    Platform(x: 1250.0, y: 380.0, width: 80.0,  height: 20.0),  # high platform
    Platform(x: 1400.0, y: 460.0, width: 200.0, height: 20.0),  # final ground
  ],
  hazards: @[
    Hazard(x: 280.0,  y: 470.0, width: 70.0,  height: 10.0),   # gap after left ground
    Hazard(x: 800.0,  y: 470.0, width: 50.0,  height: 10.0),   # gap mid
    Hazard(x: 1200.0, y: 470.0, width: 50.0,  height: 10.0),   # gap before high platform
  ],
  exits: @[
    Exit(x: 1420.0, y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 1460.0, y: 410.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 1500.0, y: 410.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 1540.0, y: 410.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 1440.0, y: 410.0, width: 40.0, height: 50.0, characterId: "felix"),
    Exit(x: 1480.0, y: 410.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[
    Button(x: 1270.0, y: 370.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: false),
  ],
  doors: @[
    Door(id: 1, x: 1370.0, y: 380.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  movingPlatforms: @[
    MovingPlatform(waypoints: @[(x: 790.0, y: 435.0), (x: 870.0, y: 435.0)],
                   width: 80.0, height: 20.0, speed: 50.0,
                   pingPong: true, forward: true,
                   x: 790.0, y: 435.0, prevX: 790.0, prevY: 435.0),
  ],
  starChallenge: StarChallenge(timeTarget: 100.0, secretX: 370.0, secretY: 395.0),
  levelWidth: 1600.0,
  levelHeight: 500.0,
)

const level22* = Level(
  id: 22,
  name: "Strength",
  narration: "Strength was not size. Bruno had always known this.",
  characters: @["pip", "luca", "bruno", "cara", "felix", "ivy"],
  platforms: @[
    Platform(x: 0.0,    y: 560.0, width: 200.0, height: 20.0),   # start ground
    Platform(x: 280.0,  y: 560.0, width: 120.0, height: 20.0),   # after door 1
    Platform(x: 500.0,  y: 480.0, width: 100.0, height: 20.0),   # raised platform
    Platform(x: 680.0,  y: 560.0, width: 120.0, height: 20.0),   # after door 2
    Platform(x: 880.0,  y: 400.0, width: 20.0,  height: 180.0),  # wall-jump pillar left
    Platform(x: 980.0,  y: 400.0, width: 20.0,  height: 180.0),  # wall-jump pillar right
    Platform(x: 880.0,  y: 380.0, width: 120.0, height: 20.0),   # top of shaft
    Platform(x: 1080.0, y: 560.0, width: 120.0, height: 20.0),   # after door 3
    Platform(x: 1280.0, y: 480.0, width: 100.0, height: 20.0),   # float platform
    Platform(x: 1460.0, y: 560.0, width: 200.0, height: 20.0),   # after door 4
    Platform(x: 1500.0, y: 380.0, width: 100.0, height: 20.0),   # high platform (pip)
  ],
  hazards: @[
    Hazard(x: 200.0,  y: 570.0, width: 80.0,  height: 10.0),    # gap 1
    Hazard(x: 400.0,  y: 570.0, width: 100.0, height: 10.0),    # gap 2
    Hazard(x: 800.0,  y: 570.0, width: 80.0,  height: 10.0),    # gap before shaft
    Hazard(x: 1200.0, y: 570.0, width: 80.0,  height: 10.0),    # gap before float
    Hazard(x: 1380.0, y: 570.0, width: 80.0,  height: 10.0),    # gap before final
  ],
  exits: @[
    Exit(x: 1480.0, y: 510.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 1520.0, y: 510.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 1560.0, y: 510.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 1600.0, y: 510.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 1500.0, y: 510.0, width: 40.0, height: 50.0, characterId: "felix"),
    Exit(x: 1540.0, y: 510.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[
    Button(x: 100.0,  y: 550.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: true),
    Button(x: 520.0,  y: 470.0, width: 40.0, height: 10.0, doorId: 2, requiresHeavy: false),
    Button(x: 910.0,  y: 370.0, width: 40.0, height: 10.0, doorId: 3, requiresHeavy: false),
    Button(x: 1300.0, y: 470.0, width: 40.0, height: 10.0, doorId: 4, requiresHeavy: false),
  ],
  doors: @[
    Door(id: 1, x: 250.0,  y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 2, x: 640.0,  y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 3, x: 1040.0, y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 4, x: 1420.0, y: 480.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  starChallenge: StarChallenge(timeTarget: 140.0, secretX: 930.0, secretY: 355.0),
  levelWidth: 1700.0,
  levelHeight: 600.0,
)

const level23* = Level(
  id: 23,
  name: "Grace",
  narration: "Grace under pressure. Ivy made it look easy.",
  characters: @["pip", "luca", "bruno", "cara", "felix", "ivy"],
  platforms: @[
    Platform(x: 0.0,    y: 560.0, width: 200.0, height: 20.0),   # start ground
    Platform(x: 300.0,  y: 500.0, width: 80.0,  height: 20.0),   # small stepping stone
    Platform(x: 460.0,  y: 440.0, width: 80.0,  height: 20.0),   # ascending step
    Platform(x: 600.0,  y: 380.0, width: 20.0,  height: 200.0),  # wall-jump pillar left
    Platform(x: 700.0,  y: 380.0, width: 20.0,  height: 200.0),  # wall-jump pillar right
    Platform(x: 600.0,  y: 360.0, width: 120.0, height: 20.0),   # top of shaft
    Platform(x: 800.0,  y: 440.0, width: 100.0, height: 20.0),   # landing after shaft
    Platform(x: 980.0,  y: 500.0, width: 80.0,  height: 20.0),   # float descent target
    Platform(x: 1140.0, y: 560.0, width: 100.0, height: 20.0),   # ground after descent
    Platform(x: 1320.0, y: 480.0, width: 80.0,  height: 20.0),   # narrow step
    Platform(x: 1480.0, y: 400.0, width: 80.0,  height: 20.0),   # high narrow step
    Platform(x: 1640.0, y: 560.0, width: 200.0, height: 20.0),   # final ground
  ],
  hazards: @[
    Hazard(x: 200.0,  y: 570.0, width: 100.0, height: 10.0),    # gap 1
    Hazard(x: 380.0,  y: 570.0, width: 80.0,  height: 10.0),    # gap 2
    Hazard(x: 540.0,  y: 570.0, width: 60.0,  height: 10.0),    # gap before walls
    Hazard(x: 720.0,  y: 570.0, width: 80.0,  height: 10.0),    # gap after walls
    Hazard(x: 900.0,  y: 570.0, width: 80.0,  height: 10.0),    # gap descent
    Hazard(x: 1060.0, y: 570.0, width: 80.0,  height: 10.0),    # gap
    Hazard(x: 1240.0, y: 570.0, width: 80.0,  height: 10.0),    # gap
    Hazard(x: 1400.0, y: 570.0, width: 80.0,  height: 10.0),    # gap
    Hazard(x: 1560.0, y: 570.0, width: 80.0,  height: 10.0),    # final gap
  ],
  exits: @[
    Exit(x: 1660.0, y: 510.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 1700.0, y: 510.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 1740.0, y: 510.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 1780.0, y: 510.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 1680.0, y: 510.0, width: 40.0, height: 50.0, characterId: "felix"),
    Exit(x: 1720.0, y: 510.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[
    Button(x: 630.0,  y: 350.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: false),
    Button(x: 1340.0, y: 470.0, width: 40.0, height: 10.0, doorId: 2, requiresHeavy: true),
  ],
  doors: @[
    Door(id: 1, x: 760.0,  y: 360.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 2, x: 1600.0, y: 480.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  starChallenge: StarChallenge(timeTarget: 120.0, secretX: 650.0, secretY: 335.0),
  levelWidth: 1840.0,
  levelHeight: 600.0,
)

const level24* = Level(
  id: 24,
  name: "Patience",
  narration: "The wise ones wait. Felix waited for everyone.",
  characters: @["pip", "luca", "bruno", "cara", "felix", "ivy"],
  platforms: @[
    Platform(x: 0.0,    y: 560.0, width: 200.0, height: 20.0),   # start ground
    Platform(x: 300.0,  y: 520.0, width: 80.0,  height: 20.0),   # step 1
    Platform(x: 460.0,  y: 480.0, width: 80.0,  height: 20.0),   # step 2
    Platform(x: 620.0,  y: 440.0, width: 80.0,  height: 20.0),   # step 3
    Platform(x: 780.0,  y: 560.0, width: 150.0, height: 20.0),   # rest platform
    Platform(x: 1000.0, y: 480.0, width: 100.0, height: 20.0),   # button platform
    Platform(x: 1180.0, y: 560.0, width: 120.0, height: 20.0),   # after door 1
    Platform(x: 1380.0, y: 500.0, width: 80.0,  height: 20.0),   # narrow step
    Platform(x: 1540.0, y: 440.0, width: 80.0,  height: 20.0),   # high step
    Platform(x: 1700.0, y: 380.0, width: 20.0,  height: 200.0),  # wall-jump pillar left
    Platform(x: 1800.0, y: 380.0, width: 20.0,  height: 200.0),  # wall-jump pillar right
    Platform(x: 1700.0, y: 360.0, width: 120.0, height: 20.0),   # top of shaft
    Platform(x: 1900.0, y: 560.0, width: 200.0, height: 20.0),   # final ground
    Platform(x: 1950.0, y: 400.0, width: 100.0, height: 20.0),   # high exit platform
  ],
  hazards: @[
    Hazard(x: 200.0,  y: 570.0, width: 100.0, height: 10.0),    # gap 1
    Hazard(x: 380.0,  y: 570.0, width: 80.0,  height: 10.0),    # gap 2
    Hazard(x: 540.0,  y: 570.0, width: 80.0,  height: 10.0),    # gap 3
    Hazard(x: 700.0,  y: 570.0, width: 80.0,  height: 10.0),    # gap 4
    Hazard(x: 930.0,  y: 570.0, width: 70.0,  height: 10.0),    # gap 5
    Hazard(x: 1300.0, y: 570.0, width: 80.0,  height: 10.0),    # gap 6
    Hazard(x: 1460.0, y: 570.0, width: 80.0,  height: 10.0),    # gap 7
    Hazard(x: 1620.0, y: 570.0, width: 80.0,  height: 10.0),    # gap 8
  ],
  exits: @[
    Exit(x: 1920.0, y: 510.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 1960.0, y: 510.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 2000.0, y: 510.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 2040.0, y: 510.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 1940.0, y: 510.0, width: 40.0, height: 50.0, characterId: "felix"),
    Exit(x: 1980.0, y: 510.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[
    Button(x: 1020.0, y: 470.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: true),
    Button(x: 1730.0, y: 350.0, width: 40.0, height: 10.0, doorId: 2, requiresHeavy: false),
    Button(x: 1970.0, y: 390.0, width: 40.0, height: 10.0, doorId: 3, requiresHeavy: false),
  ],
  doors: @[
    Door(id: 1, x: 1140.0, y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 2, x: 1860.0, y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 3, x: 2060.0, y: 480.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  starChallenge: StarChallenge(timeTarget: 150.0, secretX: 1750.0, secretY: 335.0),
  levelWidth: 2100.0,
  levelHeight: 600.0,
)

const level25* = Level(
  id: 25,
  name: "Almost",
  narration: "Almost there. Almost home. Almost together.",
  characters: @["pip", "luca", "bruno", "cara", "felix", "ivy"],
  platforms: @[
    Platform(x: 0.0,    y: 560.0, width: 200.0, height: 20.0),   # start ground
    Platform(x: 300.0,  y: 500.0, width: 80.0,  height: 20.0),   # step up
    Platform(x: 460.0,  y: 440.0, width: 100.0, height: 20.0),   # button platform 1
    Platform(x: 640.0,  y: 560.0, width: 120.0, height: 20.0),   # after door 1
    Platform(x: 840.0,  y: 480.0, width: 80.0,  height: 20.0),   # narrow step
    Platform(x: 1000.0, y: 400.0, width: 20.0,  height: 180.0),  # wall-jump pillar left
    Platform(x: 1100.0, y: 400.0, width: 20.0,  height: 180.0),  # wall-jump pillar right
    Platform(x: 1000.0, y: 380.0, width: 120.0, height: 20.0),   # top of shaft
    Platform(x: 1200.0, y: 560.0, width: 120.0, height: 20.0),   # after door 2
    Platform(x: 1400.0, y: 480.0, width: 100.0, height: 20.0),   # float platform
    Platform(x: 1580.0, y: 560.0, width: 120.0, height: 20.0),   # after door 3
    Platform(x: 1780.0, y: 500.0, width: 80.0,  height: 20.0),   # coyote step
    Platform(x: 1940.0, y: 440.0, width: 80.0,  height: 20.0),   # high step
    Platform(x: 2100.0, y: 560.0, width: 200.0, height: 20.0),   # exit ground (tantalizingly close)
    Platform(x: 2100.0, y: 380.0, width: 100.0, height: 20.0),   # high exit platform
  ],
  hazards: @[
    Hazard(x: 200.0,  y: 570.0, width: 100.0, height: 10.0),    # gap 1
    Hazard(x: 380.0,  y: 570.0, width: 80.0,  height: 10.0),    # gap 2
    Hazard(x: 560.0,  y: 570.0, width: 80.0,  height: 10.0),    # gap 3
    Hazard(x: 760.0,  y: 570.0, width: 80.0,  height: 10.0),    # gap 4
    Hazard(x: 920.0,  y: 570.0, width: 80.0,  height: 10.0),    # gap before shaft
    Hazard(x: 1120.0, y: 570.0, width: 80.0,  height: 10.0),    # gap after shaft
    Hazard(x: 1320.0, y: 570.0, width: 80.0,  height: 10.0),    # gap before float
    Hazard(x: 1500.0, y: 570.0, width: 80.0,  height: 10.0),    # gap after float
    Hazard(x: 1700.0, y: 570.0, width: 80.0,  height: 10.0),    # gap 9
    Hazard(x: 1860.0, y: 570.0, width: 80.0,  height: 10.0),    # gap 10
    Hazard(x: 2020.0, y: 570.0, width: 80.0,  height: 10.0),    # final gap before exit
  ],
  exits: @[
    Exit(x: 2120.0, y: 510.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 2160.0, y: 510.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 2200.0, y: 510.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 2240.0, y: 510.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 2140.0, y: 510.0, width: 40.0, height: 50.0, characterId: "felix"),
    Exit(x: 2180.0, y: 510.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[
    Button(x: 480.0,  y: 430.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: true),
    Button(x: 1030.0, y: 370.0, width: 40.0, height: 10.0, doorId: 2, requiresHeavy: false),
    Button(x: 1420.0, y: 470.0, width: 40.0, height: 10.0, doorId: 3, requiresHeavy: false),
    Button(x: 1960.0, y: 430.0, width: 40.0, height: 10.0, doorId: 4, requiresHeavy: false),
    Button(x: 2120.0, y: 370.0, width: 40.0, height: 10.0, doorId: 5, requiresHeavy: false),
  ],
  doors: @[
    Door(id: 1, x: 600.0,  y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 2, x: 1160.0, y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 3, x: 1540.0, y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 4, x: 2060.0, y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 5, x: 2280.0, y: 480.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  starChallenge: StarChallenge(timeTarget: 160.0, secretX: 1050.0, secretY: 355.0),
  levelWidth: 2300.0,
  levelHeight: 600.0,
)

const level26* = Level(
  id: 26,
  name: "Colors",
  narration: "They were colors. Each one necessary.",
  characters: @["pip", "luca", "bruno", "cara", "felix", "ivy"],
  platforms: @[
    Platform(x: 0.0,    y: 560.0, width: 200.0, height: 20.0),   # start ground
    Platform(x: 280.0,  y: 560.0, width: 100.0, height: 20.0),   # pink zone (pip)
    Platform(x: 460.0,  y: 500.0, width: 100.0, height: 20.0),   # blue zone (luca)
    Platform(x: 640.0,  y: 560.0, width: 120.0, height: 20.0),   # green zone (bruno)
    Platform(x: 840.0,  y: 480.0, width: 80.0,  height: 20.0),   # yellow zone (cara)
    Platform(x: 1000.0, y: 560.0, width: 100.0, height: 20.0),   # orange zone (felix)
    Platform(x: 1180.0, y: 440.0, width: 80.0,  height: 20.0),   # purple zone (ivy)
    Platform(x: 1340.0, y: 560.0, width: 200.0, height: 20.0),   # convergence ground
    Platform(x: 1340.0, y: 400.0, width: 80.0,  height: 20.0),   # high convergence
    Platform(x: 1500.0, y: 480.0, width: 80.0,  height: 20.0),   # step to exit
    Platform(x: 1620.0, y: 560.0, width: 200.0, height: 20.0),   # exit ground
  ],
  hazards: @[
    Hazard(x: 200.0,  y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 380.0,  y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 560.0,  y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 760.0,  y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 920.0,  y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 1100.0, y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 1260.0, y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 1540.0, y: 570.0, width: 80.0,  height: 10.0),
  ],
  exits: @[
    Exit(x: 1640.0, y: 510.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 1680.0, y: 510.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 1720.0, y: 510.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 1760.0, y: 510.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 1660.0, y: 510.0, width: 40.0, height: 50.0, characterId: "felix"),
    Exit(x: 1700.0, y: 510.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[
    Button(x: 300.0,  y: 550.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: false),
    Button(x: 660.0,  y: 550.0, width: 40.0, height: 10.0, doorId: 2, requiresHeavy: true),
    Button(x: 1200.0, y: 430.0, width: 40.0, height: 10.0, doorId: 3, requiresHeavy: false),
  ],
  doors: @[
    Door(id: 1, x: 420.0,  y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 2, x: 800.0,  y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 3, x: 1580.0, y: 480.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  movingPlatforms: @[
    MovingPlatform(waypoints: @[(x: 1100.0, y: 530.0), (x: 1260.0, y: 530.0)],
                   width: 80.0, height: 20.0, speed: 55.0,
                   pingPong: true, forward: true,
                   x: 1100.0, y: 530.0, prevX: 1100.0, prevY: 530.0),
  ],
  starChallenge: StarChallenge(timeTarget: 120.0, secretX: 1360.0, secretY: 375.0),
  levelWidth: 1820.0,
  levelHeight: 600.0,
)

const level27* = Level(
  id: 27,
  name: "Shapes",
  narration: "They were shapes. Each one perfect.",
  characters: @["pip", "luca", "bruno", "cara", "felix", "ivy"],
  platforms: @[
    Platform(x: 0.0,    y: 560.0, width: 200.0, height: 20.0),   # start ground
    Platform(x: 280.0,  y: 500.0, width: 40.0,  height: 20.0),   # narrow for cara
    Platform(x: 400.0,  y: 560.0, width: 180.0, height: 20.0),   # wide for bruno
    Platform(x: 660.0,  y: 480.0, width: 60.0,  height: 20.0),   # medium for pip
    Platform(x: 800.0,  y: 420.0, width: 140.0, height: 20.0),   # wide for luca
    Platform(x: 1020.0, y: 560.0, width: 50.0,  height: 20.0),   # narrow for felix
    Platform(x: 1150.0, y: 480.0, width: 80.0,  height: 20.0),   # medium for ivy
    Platform(x: 1310.0, y: 400.0, width: 20.0,  height: 180.0),  # wall-jump pillar left
    Platform(x: 1410.0, y: 400.0, width: 20.0,  height: 180.0),  # wall-jump pillar right
    Platform(x: 1310.0, y: 380.0, width: 120.0, height: 20.0),   # top of shaft
    Platform(x: 1510.0, y: 560.0, width: 200.0, height: 20.0),   # exit ground wide
    Platform(x: 1510.0, y: 420.0, width: 80.0,  height: 20.0),   # high exit platform
  ],
  hazards: @[
    Hazard(x: 200.0,  y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 320.0,  y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 580.0,  y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 720.0,  y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 940.0,  y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 1070.0, y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 1230.0, y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 1430.0, y: 570.0, width: 80.0,  height: 10.0),
  ],
  exits: @[
    Exit(x: 1530.0, y: 510.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 1570.0, y: 510.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 1610.0, y: 510.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 1650.0, y: 510.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 1550.0, y: 510.0, width: 40.0, height: 50.0, characterId: "felix"),
    Exit(x: 1590.0, y: 510.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[
    Button(x: 440.0,  y: 550.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: true),
    Button(x: 840.0,  y: 410.0, width: 40.0, height: 10.0, doorId: 2, requiresHeavy: false),
    Button(x: 1340.0, y: 370.0, width: 40.0, height: 10.0, doorId: 3, requiresHeavy: false),
  ],
  doors: @[
    Door(id: 1, x: 620.0,  y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 2, x: 980.0,  y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 3, x: 1470.0, y: 480.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  starChallenge: StarChallenge(timeTarget: 130.0, secretX: 1360.0, secretY: 355.0),
  levelWidth: 1710.0,
  levelHeight: 600.0,
)

const level28* = Level(
  id: 28,
  name: "Consciousness",
  narration: "They were consciousness discovering itself.",
  characters: @["pip", "luca", "bruno", "cara", "felix", "ivy"],
  platforms: @[
    # Brain/heart shape layout — platforms form a symmetrical organic shape
    Platform(x: 0.0,    y: 560.0, width: 160.0, height: 20.0),   # start ground (left base)
    Platform(x: 200.0,  y: 480.0, width: 100.0, height: 20.0),   # left lobe lower
    Platform(x: 360.0,  y: 400.0, width: 80.0,  height: 20.0),   # left lobe upper
    Platform(x: 500.0,  y: 340.0, width: 100.0, height: 20.0),   # left crown
    Platform(x: 660.0,  y: 300.0, width: 80.0,  height: 20.0),   # top center left
    Platform(x: 800.0,  y: 280.0, width: 100.0, height: 20.0),   # apex (top of heart)
    Platform(x: 960.0,  y: 300.0, width: 80.0,  height: 20.0),   # top center right
    Platform(x: 1100.0, y: 340.0, width: 100.0, height: 20.0),   # right crown
    Platform(x: 1260.0, y: 400.0, width: 80.0,  height: 20.0),   # right lobe upper
    Platform(x: 1400.0, y: 480.0, width: 100.0, height: 20.0),   # right lobe lower
    Platform(x: 1540.0, y: 560.0, width: 160.0, height: 20.0),   # right base
    Platform(x: 780.0,  y: 560.0, width: 140.0, height: 20.0),   # center bottom (heart point)
    Platform(x: 780.0,  y: 420.0, width: 140.0, height: 20.0),   # center platform (inner)
  ],
  hazards: @[
    Hazard(x: 160.0,  y: 570.0, width: 40.0,  height: 10.0),
    Hazard(x: 440.0,  y: 570.0, width: 60.0,  height: 10.0),
    Hazard(x: 740.0,  y: 570.0, width: 40.0,  height: 10.0),
    Hazard(x: 920.0,  y: 570.0, width: 40.0,  height: 10.0),
    Hazard(x: 1200.0, y: 570.0, width: 60.0,  height: 10.0),
    Hazard(x: 1500.0, y: 570.0, width: 40.0,  height: 10.0),
  ],
  exits: @[
    Exit(x: 820.0, y: 510.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 860.0, y: 510.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 800.0, y: 510.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 840.0, y: 510.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 880.0, y: 510.0, width: 40.0, height: 50.0, characterId: "felix"),
    Exit(x: 900.0, y: 510.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[
    Button(x: 520.0,  y: 330.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: false),
    Button(x: 830.0,  y: 270.0, width: 40.0, height: 10.0, doorId: 2, requiresHeavy: false),
    Button(x: 1120.0, y: 330.0, width: 40.0, height: 10.0, doorId: 3, requiresHeavy: true),
  ],
  doors: @[
    Door(id: 1, x: 740.0,  y: 340.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 2, x: 850.0,  y: 420.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 3, x: 1360.0, y: 400.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  movingPlatforms: @[
    MovingPlatform(waypoints: @[(x: 170.0, y: 540.0), (x: 170.0, y: 400.0)],
                   width: 70.0, height: 20.0, speed: 60.0,
                   pingPong: true, forward: true,
                   x: 170.0, y: 540.0, prevX: 170.0, prevY: 540.0),
  ],
  starChallenge: StarChallenge(timeTarget: 140.0, secretX: 830.0, secretY: 255.0),
  levelWidth: 1700.0,
  levelHeight: 600.0,
)

const level29* = Level(
  id: 29,
  name: "Family",
  narration: "They were family. Not because they were alike. Because they chose each other.",
  characters: @["pip", "luca", "bruno", "cara", "felix", "ivy"],
  platforms: @[
    Platform(x: 0.0,    y: 560.0, width: 200.0, height: 20.0),   # start ground
    Platform(x: 280.0,  y: 500.0, width: 80.0,  height: 20.0),   # step 1
    Platform(x: 440.0,  y: 440.0, width: 100.0, height: 20.0),   # button platform 1
    Platform(x: 620.0,  y: 560.0, width: 120.0, height: 20.0),   # after door 1
    Platform(x: 820.0,  y: 480.0, width: 80.0,  height: 20.0),   # narrow step
    Platform(x: 980.0,  y: 400.0, width: 20.0,  height: 180.0),  # wall-jump pillar left
    Platform(x: 1080.0, y: 400.0, width: 20.0,  height: 180.0),  # wall-jump pillar right
    Platform(x: 980.0,  y: 380.0, width: 120.0, height: 20.0),   # top of shaft
    Platform(x: 1180.0, y: 560.0, width: 120.0, height: 20.0),   # after door 2
    Platform(x: 1380.0, y: 480.0, width: 100.0, height: 20.0),   # button platform 3
    Platform(x: 1560.0, y: 400.0, width: 80.0,  height: 20.0),   # high narrow
    Platform(x: 1720.0, y: 560.0, width: 120.0, height: 20.0),   # after door 3
    Platform(x: 1920.0, y: 500.0, width: 80.0,  height: 20.0),   # coyote step
    Platform(x: 2080.0, y: 440.0, width: 100.0, height: 20.0),   # button platform 4
    Platform(x: 2260.0, y: 560.0, width: 200.0, height: 20.0),   # exit ground
    Platform(x: 2260.0, y: 380.0, width: 100.0, height: 20.0),   # high exit platform
  ],
  hazards: @[
    Hazard(x: 200.0,  y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 360.0,  y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 540.0,  y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 740.0,  y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 900.0,  y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 1100.0, y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 1300.0, y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 1480.0, y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 1640.0, y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 1840.0, y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 2000.0, y: 570.0, width: 80.0,  height: 10.0),
    Hazard(x: 2180.0, y: 570.0, width: 80.0,  height: 10.0),
  ],
  exits: @[
    Exit(x: 2280.0, y: 510.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 2320.0, y: 510.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 2360.0, y: 510.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 2400.0, y: 510.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 2300.0, y: 510.0, width: 40.0, height: 50.0, characterId: "felix"),
    Exit(x: 2340.0, y: 510.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[
    Button(x: 460.0,  y: 430.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: true),
    Button(x: 1010.0, y: 370.0, width: 40.0, height: 10.0, doorId: 2, requiresHeavy: false),
    Button(x: 1400.0, y: 470.0, width: 40.0, height: 10.0, doorId: 3, requiresHeavy: false),
    Button(x: 2100.0, y: 430.0, width: 40.0, height: 10.0, doorId: 4, requiresHeavy: false),
    Button(x: 2280.0, y: 370.0, width: 40.0, height: 10.0, doorId: 5, requiresHeavy: false),
  ],
  doors: @[
    Door(id: 1, x: 580.0,  y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 2, x: 1140.0, y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 3, x: 1680.0, y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 4, x: 2220.0, y: 480.0, width: 20.0, height: 80.0, isOpen: false),
    Door(id: 5, x: 2440.0, y: 480.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  starChallenge: StarChallenge(timeTarget: 170.0, secretX: 1030.0, secretY: 355.0),
  levelWidth: 2460.0,
  levelHeight: 600.0,
)

const level30* = Level(
  id: 30,
  name: "Together",
  narration: "One exit. One family. Together. Because that's what family does.",
  characters: @["pip", "luca", "bruno", "cara", "felix", "ivy"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 200.0, height: 20.0),    # start ground
    Platform(x: 260.0, y: 420.0, width: 100.0, height: 20.0),     # gentle step up
    Platform(x: 420.0, y: 460.0, width: 160.0, height: 20.0),     # middle ground
    Platform(x: 640.0, y: 420.0, width: 100.0, height: 20.0),     # gentle step
    Platform(x: 800.0, y: 460.0, width: 300.0, height: 20.0),     # wide exit platform
  ],
  hazards: @[
    Hazard(x: 200.0, y: 470.0, width: 60.0, height: 10.0),
    Hazard(x: 580.0, y: 470.0, width: 60.0, height: 10.0),
  ],
  exits: @[
    # ONE shared exit — all 6 characters at the same position
    Exit(x: 900.0, y: 410.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 900.0, y: 410.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 900.0, y: 410.0, width: 40.0, height: 50.0, characterId: "bruno"),
    Exit(x: 900.0, y: 410.0, width: 40.0, height: 50.0, characterId: "cara"),
    Exit(x: 900.0, y: 410.0, width: 40.0, height: 50.0, characterId: "felix"),
    Exit(x: 900.0, y: 410.0, width: 40.0, height: 50.0, characterId: "ivy"),
  ],
  buttons: @[],
  doors: @[],
  starChallenge: StarChallenge(timeTarget: 60.0, secretX: 440.0, secretY: 435.0),
  levelWidth: 1100.0,
  levelHeight: 500.0,
)

const level31* = Level(
  id: 31,
  name: "Shoulders",
  narration: "Bruno held steady. He knew they needed him exactly where he was.",
  characters: @["pip", "bruno"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 800.0, height: 20.0),  # ground
    Platform(x: 520.0, y: 260.0, width: 200.0, height: 20.0),  # high ledge — stacking target
  ],
  hazards: @[],
  exits: @[
    Exit(x: 600.0, y: 210.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 100.0, y: 410.0, width: 40.0, height: 50.0, characterId: "bruno"),
  ],
  buttons: @[
    Button(x: 555.0, y: 250.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: false),
  ],
  doors: @[
    Door(id: 1, x: 60.0, y: 380.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  starChallenge: StarChallenge(timeTarget: 60.0, secretX: 660.0, secretY: 235.0),
  levelWidth: 800.0,
  levelHeight: 500.0,
)

const level32* = Level(
  id: 32,
  name: "Towers",
  narration: "Pip had never been this high. She could see everything from up here.",
  characters: @["pip", "luca", "bruno"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 900.0, height: 20.0),  # ground
    Platform(x: 580.0, y: 330.0, width: 150.0, height: 20.0),  # mid ledge — Luca's exit
    Platform(x: 600.0, y: 220.0, width: 120.0, height: 20.0),  # top ledge — Pip's exit (triple stack only)
  ],
  hazards: @[],
  exits: @[
    Exit(x: 620.0, y: 170.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 640.0, y: 280.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 100.0, y: 410.0, width: 40.0, height: 50.0, characterId: "bruno"),
  ],
  buttons: @[
    Button(x: 610.0, y: 210.0, width: 40.0, height: 10.0, doorId: 1, requiresHeavy: false),
  ],
  doors: @[
    Door(id: 1, x: 60.0, y: 380.0, width: 20.0, height: 80.0, isOpen: false),
  ],
  starChallenge: StarChallenge(timeTarget: 75.0, secretX: 670.0, secretY: 195.0),
  levelWidth: 900.0,
  levelHeight: 500.0,
)

const level33* = Level(
  id: 33,
  name: "Shoulders",
  narration: "Bruno held steady. He knew they needed him exactly where he was.",
  characters: @["bruno", "pip"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 800.0, height: 20.0),   # ground
    Platform(x: 480.0, y: 255.0, width: 200.0, height: 20.0),   # high ledge
  ],
  hazards: @[],
  exits: @[
    Exit(x: 590.0, y: 205.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 650.0, y: 410.0, width: 40.0, height: 50.0, characterId: "bruno"),
  ],
  buttons: @[],
  doors: @[],
  starChallenge: StarChallenge(timeTarget: 60.0, secretX: 510.0, secretY: 230.0),
  levelWidth: 800.0,
  levelHeight: 500.0,
)

const level34* = Level(
  id: 34,
  name: "Carried",
  narration: "They didn't always need the same things. But right now, they needed each other.",
  characters: @["pip", "luca", "bruno"],
  platforms: @[
    Platform(x: 0.0,   y: 460.0, width: 200.0, height: 20.0),   # left ground
    Platform(x: 600.0, y: 460.0, width: 400.0, height: 20.0),   # right ground
    Platform(x: 640.0, y: 350.0, width: 160.0, height: 20.0),   # mid ledge (Luca exit)
    Platform(x: 680.0, y: 220.0, width: 130.0, height: 20.0),   # high ledge (Pip exit)
  ],
  hazards: @[
    Hazard(x: 200.0, y: 470.0, width: 400.0, height: 10.0),     # chasm spikes
  ],
  exits: @[
    Exit(x: 710.0, y: 170.0, width: 40.0, height: 50.0, characterId: "pip"),
    Exit(x: 660.0, y: 300.0, width: 40.0, height: 50.0, characterId: "luca"),
    Exit(x: 880.0, y: 410.0, width: 40.0, height: 50.0, characterId: "bruno"),
  ],
  buttons: @[],
  doors: @[],
  movingPlatforms: @[
    MovingPlatform(waypoints: @[(x: 220.0, y: 460.0), (x: 560.0, y: 460.0)],
                   width: 110.0, height: 20.0, speed: 80.0,
                   pingPong: true, forward: true,
                   x: 220.0, y: 460.0, prevX: 220.0, prevY: 460.0),
  ],
  starChallenge: StarChallenge(timeTarget: 80.0, secretX: 700.0, secretY: 195.0),
  levelWidth: 1000.0,
  levelHeight: 500.0,
)

const allLevels*: array[34, Level] = [level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, level11, level12, level13, level14, level15, level16, level17, level18, level19, level20, level21, level22, level23, level24, level25, level26, level27, level28, level29, level30, level31, level32, level33, level34]
