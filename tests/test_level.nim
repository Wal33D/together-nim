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

  test "all levels array has 12 levels":
    check allLevels.len == 12

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
    check level11.characters == @["pip", "luca", "bruno", "cara", "felix"]

  test "level 11 has felix narration":
    check level11.narration.contains("Felix")

  test "level 12 introduces ivy":
    check level12.characters == @["pip", "luca", "bruno", "cara", "felix", "ivy"]

  test "level 12 has ivy narration":
    check level12.narration.contains("Ivy")
