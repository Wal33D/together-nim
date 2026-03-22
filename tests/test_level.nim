import unittest
import strutils
import "../src/systems/levels"

suite "levels":
  test "level 1 has pip only":
    check level1.characters == @["pip"]

  test "level 1 has one exit":
    check level1.exits.len == 1

  test "level 1 has platforms":
    check level1.platforms.len > 0

  test "level 5 has pip and luca":
    check level5.characters == @["pip", "luca"]

  test "level 5 has two exits":
    check level5.exits.len == 2

  test "all levels array has 25 levels":
    check allLevels.len == 25

  test "level 6 introduces bruno":
    check level6.characters == @["pip", "luca", "bruno"]

  test "level 6 has requiresHeavy button":
    check level6.buttons.len == 1
    check level6.buttons[0].requiresHeavy == true

  test "level 6 has three exits":
    check level6.exits.len == 3

  test "level 8 introduces cara":
    check level8.characters == @["pip", "bruno", "cara"]

  test "level 9 has all four characters":
    check level9.characters == @["pip", "luca", "bruno", "cara"]

  test "level 10 has trust narration":
    check level10.narration == "Trust was not a feeling. Trust was a choice."

  test "level 11 Patience has pip bruno felix":
    check level11.characters == @["pip", "bruno", "felix"]
    check level11.name == "Patience"

  test "level 11 has felix narration":
    check level11.narration.contains("Felix")

  test "level 11 has three exits":
    check level11.exits.len == 3

  test "level 11 has long gap hazards":
    check level11.hazards.len == 3

  test "level 12 The Quiet One has pip luca ivy":
    check level12.characters == @["pip", "luca", "ivy"]
    check level12.name == "The Quiet One"

  test "level 12 has ivy narration":
    check level12.narration.contains("Ivy")

  test "level 12 has three exits":
    check level12.exits.len == 3

  test "level 13 Six has all 6 characters":
    check level13.characters.len == 6
    check level13.name == "Six"

  test "level 13 has 6 exits":
    check level13.exits.len == 6

  test "level 14 Hazards has spikes":
    check level14.hazards.len >= 2
    check level14.name == "Hazards"

  test "level 14 has heavy button for bruno":
    check level14.buttons.len == 1
    check level14.buttons[0].requiresHeavy == true

  test "level 14 has all 6 characters":
    check level14.characters.len == 6

  test "level 15 Rising is vertical":
    check level15.levelHeight > level15.levelWidth
    check level15.name == "Rising"

  test "level 15 has all 6 characters":
    check level15.characters.len == 6

  test "level 15 has wall-jump pillars":
    var tallPlatforms = 0
    for p in level15.platforms:
      if p.height > p.width:
        tallPlatforms += 1
    check tallPlatforms >= 2

  test "level 16 Apart has all 6 characters":
    check level16.characters.len == 6
    check level16.name == "Apart"

  test "level 16 has separation narration":
    check level16.narration == "For the first time, they couldn't see each other."

  test "level 16 has central wall":
    var tallWalls = 0
    for p in level16.platforms:
      if p.height > p.width and p.height >= 400.0:
        tallWalls += 1
    check tallWalls >= 1

  test "level 16 has 6 exits":
    check level16.exits.len == 6

  test "level 17 Trust Fall has pip and bruno":
    check level17.characters == @["pip", "bruno"]
    check level17.name == "Trust Fall"

  test "level 17 has trust narration":
    check level17.narration == "Trust was not a feeling. Trust was a choice."

  test "level 17 has button and door":
    check level17.buttons.len == 1
    check level17.doors.len == 1

  test "level 17 has dividing wall":
    var walls = 0
    for p in level17.platforms:
      if p.height > p.width:
        walls += 1
    check walls >= 1

  test "level 18 Bridges has luca cara felix":
    check level18.characters == @["luca", "cara", "felix"]
    check level18.name == "Bridges"

  test "level 18 has bridges narration":
    check level18.narration == "They were bridges for each other. They always had been."

  test "level 18 has chain of 3 doors":
    check level18.buttons.len == 3
    check level18.doors.len == 3

  test "level 18 has 3 exits":
    check level18.exits.len == 3

  test "level 19 Missing has all 6 characters":
    check level19.characters.len == 6
    check level19.name == "Missing"

  test "level 19 has reunion narration":
    check level19.narration.contains("Where were you")

  test "level 19 has 6 exits":
    check level19.exits.len == 6

  test "level 20 Home has all 6 characters":
    check level20.characters.len == 6
    check level20.name == "Home"

  test "level 20 has home narration":
    check level20.narration == "Home was not a place. Home was who you were with."

  test "level 20 has multiple buttons and doors":
    check level20.buttons.len >= 3
    check level20.doors.len >= 3

  test "level 20 has heavy button for bruno":
    var hasHeavy = false
    for b in level20.buttons:
      if b.requiresHeavy:
        hasHeavy = true
    check hasHeavy

  test "level 21 Memory has all 6 characters":
    check level21.characters.len == 6
    check level21.name == "Memory"

  test "level 21 has memory narration":
    check level21.narration == "They remembered being alone. It felt like a dream now."

  test "level 21 callbacks to level 1 layout":
    # First 3 platforms match level 1 positions
    check level21.platforms[0].x == level1.platforms[0].x
    check level21.platforms[0].y == level1.platforms[0].y
    check level21.platforms[1].x == level1.platforms[1].x
    check level21.platforms[1].y == level1.platforms[1].y

  test "level 21 has 6 exits":
    check level21.exits.len == 6

  test "level 22 Strength has all 6 characters":
    check level22.characters.len == 6
    check level22.name == "Strength"

  test "level 22 has strength narration":
    check level22.narration.contains("Bruno")

  test "level 22 has multiple button chains":
    check level22.buttons.len >= 4
    check level22.doors.len >= 4

  test "level 22 has heavy button":
    var hasHeavy = false
    for b in level22.buttons:
      if b.requiresHeavy:
        hasHeavy = true
    check hasHeavy

  test "level 22 has 6 exits":
    check level22.exits.len == 6

  test "level 23 Grace has all 6 characters":
    check level23.characters.len == 6
    check level23.name == "Grace"

  test "level 23 has grace narration":
    check level23.narration.contains("Ivy")

  test "level 23 has many hazards":
    check level23.hazards.len >= 7

  test "level 23 has wall-jump pillars for cara":
    var tallPlatforms = 0
    for p in level23.platforms:
      if p.height > p.width:
        tallPlatforms += 1
    check tallPlatforms >= 2

  test "level 23 has 6 exits":
    check level23.exits.len == 6

  test "level 24 Patience has all 6 characters":
    check level24.characters.len == 6
    check level24.name == "Patience"

  test "level 24 has patience narration":
    check level24.narration.contains("Felix")

  test "level 24 is a long level":
    check level24.levelWidth >= 2000.0

  test "level 24 has many hazards for timing":
    check level24.hazards.len >= 6

  test "level 24 has 6 exits":
    check level24.exits.len == 6

  test "level 25 Almost has all 6 characters":
    check level25.characters.len == 6
    check level25.name == "Almost"

  test "level 25 has almost narration":
    check level25.narration == "Almost there. Almost home. Almost together."

  test "level 25 has most buttons and doors":
    check level25.buttons.len >= 5
    check level25.doors.len >= 5

  test "level 25 has many hazards":
    check level25.hazards.len >= 10

  test "level 25 has 6 exits":
    check level25.exits.len == 6
