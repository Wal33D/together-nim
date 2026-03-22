import
  unittest,
  "../src/game",
  "../src/constants",
  "../src/entities/character",
  "../src/entities/level",
  "../src/systems/particles"

suite "scripted moments":
  test "level 7: button press triggers celebration bounce":
    var g = newGame()
    g.state = playing
    g.currentLevel = 6
    g.currentLevelState = Level(
      id: 7,
      platforms: @[Platform(x: 0.0, y: 460.0, width: 400.0, height: 20.0)],
      hazards: @[],
      exits: @[],
      buttons: @[
        Button(x: 100.0, y: 450.0, width: 40.0, height: 10.0, doorId: 1,
               requiresHeavy: true, active: true, prevActive: false),
      ],
      doors: @[Door(id: 1, x: 300.0, y: 380.0, width: 20.0, height: 80.0, isOpen: true)],
      movingPlatforms: @[],
      levelWidth: 800.0,
      levelHeight: 500.0,
    )
    g.characters = @[newCharacter("pip"), newCharacter("luca"), newCharacter("bruno")]
    for i in 0..<g.characters.len:
      g.characters[i].grounded = true
      g.characters[i].y = 420.0

    g.checkScriptedMoments()

    check 7'u8 in g.triggeredMoments
    for c in g.characters:
      check c.vy == -100.0

  test "level 7: moment does not re-trigger":
    var g = newGame()
    g.state = playing
    g.currentLevel = 6
    g.triggeredMoments.incl(7'u8)
    g.currentLevelState = Level(
      id: 7,
      platforms: @[],
      hazards: @[],
      exits: @[],
      buttons: @[
        Button(x: 100.0, y: 450.0, width: 40.0, height: 10.0, doorId: 1,
               requiresHeavy: true, active: true, prevActive: false),
      ],
      doors: @[],
      movingPlatforms: @[],
      levelWidth: 800.0,
      levelHeight: 500.0,
    )
    g.characters = @[newCharacter("bruno")]
    g.characters[0].grounded = true
    g.characters[0].vy = 0.0

    g.checkScriptedMoments()

    check g.characters[0].vy == 0.0

  test "level 7: airborne characters do not bounce":
    var g = newGame()
    g.state = playing
    g.currentLevel = 6
    g.currentLevelState = Level(
      id: 7,
      platforms: @[],
      hazards: @[],
      exits: @[],
      buttons: @[
        Button(x: 100.0, y: 450.0, width: 40.0, height: 10.0, doorId: 1,
               requiresHeavy: true, active: true, prevActive: false),
      ],
      doors: @[],
      movingPlatforms: @[],
      levelWidth: 800.0,
      levelHeight: 500.0,
    )
    g.characters = @[newCharacter("pip"), newCharacter("bruno")]
    g.characters[0].grounded = false
    g.characters[0].vy = 50.0
    g.characters[1].grounded = true
    g.characters[1].vy = 0.0

    g.checkScriptedMoments()

    check g.characters[0].vy == 50.0
    check g.characters[1].vy == -100.0

  test "level 13: all at exit triggers special narration":
    var g = newGame()
    g.state = playing
    g.currentLevel = 12
    g.currentLevelState = Level(
      id: 13,
      platforms: @[],
      hazards: @[],
      exits: @[],
      buttons: @[],
      doors: @[],
      movingPlatforms: @[],
      levelWidth: 800.0,
      levelHeight: 500.0,
    )
    g.characters = @[
      newCharacter("pip"), newCharacter("luca"), newCharacter("bruno"),
      newCharacter("cara"), newCharacter("felix"), newCharacter("ivy"),
    ]
    for i in 0..<g.characters.len:
      g.characters[i].atExit = true

    g.checkScriptedMoments()

    check 13'u8 in g.triggeredMoments
    check g.narrationText == "Together. Finally, together."
    check g.narrationActive == true

  test "level 13: does not trigger if not all at exit":
    var g = newGame()
    g.state = playing
    g.currentLevel = 12
    g.currentLevelState = Level(
      id: 13,
      platforms: @[],
      hazards: @[],
      exits: @[],
      buttons: @[],
      doors: @[],
      movingPlatforms: @[],
      levelWidth: 800.0,
      levelHeight: 500.0,
    )
    g.characters = @[newCharacter("pip"), newCharacter("luca")]
    g.characters[0].atExit = true
    g.characters[1].atExit = false

    g.checkScriptedMoments()

    check 13'u8 notin g.triggeredMoments

  test "level 19: Pip near others triggers reunion narration":
    var g = newGame()
    g.state = playing
    g.currentLevel = 18
    g.currentLevelState = Level(
      id: 19,
      platforms: @[],
      hazards: @[],
      exits: @[],
      buttons: @[],
      doors: @[],
      movingPlatforms: @[],
      levelWidth: 800.0,
      levelHeight: 500.0,
    )
    g.characters = @[newCharacter("pip"), newCharacter("luca")]
    g.characters[0].x = 100.0
    g.characters[0].y = 100.0
    g.characters[1].x = 120.0
    g.characters[1].y = 100.0

    g.checkScriptedMoments()

    check 19'u8 in g.triggeredMoments
    check g.narrationText == "They were waiting. They had always been waiting."
    check g.narrationActive == true

  test "level 19: Pip far from others does not trigger":
    var g = newGame()
    g.state = playing
    g.currentLevel = 18
    g.currentLevelState = Level(
      id: 19,
      platforms: @[],
      hazards: @[],
      exits: @[],
      buttons: @[],
      doors: @[],
      movingPlatforms: @[],
      levelWidth: 800.0,
      levelHeight: 500.0,
    )
    g.characters = @[newCharacter("pip"), newCharacter("luca")]
    g.characters[0].x = 100.0
    g.characters[0].y = 100.0
    g.characters[1].x = 500.0
    g.characters[1].y = 100.0

    g.checkScriptedMoments()

    check 19'u8 notin g.triggeredMoments

  test "level 30: all at exit triggers finale":
    var g = newGame()
    g.state = playing
    g.currentLevel = 29
    g.currentLevelState = Level(
      id: 30,
      platforms: @[],
      hazards: @[],
      exits: @[],
      buttons: @[],
      doors: @[],
      movingPlatforms: @[],
      levelWidth: 800.0,
      levelHeight: 500.0,
    )
    g.characters = @[newCharacter("pip")]
    g.characters[0].atExit = true

    g.checkScriptedMoments()

    check 30'u8 in g.triggeredMoments
    check g.finaleActive == true
    check g.finaleTimer == 0.0

  test "startGame clears triggered moments":
    var g = newGame()
    g.triggeredMoments.incl(7'u8)
    g.triggeredMoments.incl(13'u8)
    g.startGame()
    check g.triggeredMoments == {}

  test "loadLevel resets finale state":
    var g = newGame()
    g.finaleActive = true
    g.finaleTimer = 1.5
    g.screenBrightness = 0.75
    g.loadLevel(0)
    check g.finaleActive == false
    check g.finaleTimer == 0.0
    check g.screenBrightness == 0.0
