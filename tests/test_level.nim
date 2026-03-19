import unittest
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

  test "all levels array has 15 levels":
    check allLevels.len == 15

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

  test "level 11 introduces felix":
    check "felix" in level11.characters
    check level11.name == "Patience"

  test "level 11 has long gaps with hazards":
    check level11.hazards.len == 3

  test "level 11 has three exits":
    check level11.exits.len == 3

  test "level 12 introduces ivy":
    check "ivy" in level12.characters
    check level12.name == "The Quiet One"

  test "level 12 has tall drop from high start":
    check level12.platforms[0].y < 200.0

  test "level 12 has three exits":
    check level12.exits.len == 3

  test "level 13 has all six characters":
    check level13.characters.len == 6
    check level13.name == "Six"

  test "level 13 has six exits":
    check level13.exits.len == 6

  test "level 14 has hazards and heavy button":
    check level14.hazards.len >= 3
    check level14.buttons.len == 1
    check level14.buttons[0].requiresHeavy == true

  test "level 14 has all six characters":
    check level14.characters.len == 6

  test "level 15 is vertical":
    check level15.levelHeight > level15.levelWidth
    check level15.levelHeight == 1000.0

  test "level 15 has wall-jump pillars":
    var narrowPillars = 0
    for p in level15.platforms:
      if p.width == 20.0 and p.height >= 80.0:
        narrowPillars += 1
    check narrowPillars >= 2

  test "level 15 has all six characters":
    check level15.characters.len == 6
