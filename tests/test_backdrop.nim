import unittest
import "../src/systems/backdrop"

suite "backdrop scenes":
  test "act 1 levels use dawn meadow":
    check levelBackdropScene(1) == dawnMeadow
    check levelBackdropScene(6) == dawnMeadow
    check backdropThemeForLevel(3).scene == dawnMeadow

  test "act 2 levels use river valley":
    check levelBackdropScene(7) == riverValley
    check levelBackdropScene(12) == riverValley
    check backdropThemeForLevel(9).scene == riverValley

  test "act 3 levels use stone ruins":
    check levelBackdropScene(13) == stoneRuins
    check levelBackdropScene(18) == stoneRuins
    check backdropThemeForLevel(15).scene == stoneRuins

  test "act 4 levels use night sky":
    check levelBackdropScene(19) == nightSky
    check levelBackdropScene(24) == nightSky
    check backdropThemeForLevel(21).scene == nightSky

  test "act 5 levels use aether plane":
    check levelBackdropScene(25) == aetherPlane
    check levelBackdropScene(30) == aetherPlane
    check backdropThemeForLevel(27).scene == aetherPlane
