import unittest
import "../src/systems/backdrop"

suite "backdrop scenes":
  test "early levels use dawn meadow":
    check levelBackdropScene(1) == dawnMeadow
    check backdropThemeForLevel(4).scene == dawnMeadow

  test "mid campaign uses river valley":
    check levelBackdropScene(5) == riverValley
    check backdropThemeForLevel(7).scene == riverValley

  test "late campaign uses stone ruins":
    check levelBackdropScene(8) == stoneRuins
    check backdropThemeForLevel(10).scene == stoneRuins

  test "final act uses night sky":
    check levelBackdropScene(11) == nightSky
    check backdropThemeForLevel(12).scene == nightSky
