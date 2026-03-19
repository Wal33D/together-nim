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

  test "all levels array has 5 levels":
    check allLevels.len == 5
