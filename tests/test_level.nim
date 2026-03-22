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

  test "all levels array has 20 levels":
    check allLevels.len == 20

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
