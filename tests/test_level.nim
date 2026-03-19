import unittest
import "../src/systems/levels"

suite "levels":
  test "level 1 has correct character list":
    check level1.characters == @["pip"]
    check level1.characters.len == 1

  test "level 1 has one exit":
    check level1.exits.len == 1
    check level1.exits[0].characterId == "pip"

  test "level 1 has platforms":
    check level1.platforms.len > 0

  test "level 3 has pip and luca":
    check level3.characters == @["pip", "luca"]

  test "level 3 has two exits":
    check level3.exits.len == 2
