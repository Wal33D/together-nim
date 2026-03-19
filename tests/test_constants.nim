import unittest
import "../src/constants"

suite "constants":
  test "physics constants":
    check GRAVITY == 980.0
    check JUMP_VELOCITY == -450.0
    check MAX_FALL_SPEED == 800.0
    check TERMINAL_VELOCITY == MAX_FALL_SPEED

  test "window constants":
    check DEFAULT_WIDTH == 1280
    check DEFAULT_HEIGHT == 720

  test "timing constant":
    check abs(FIXED_TIMESTEP - 1.0 / 60.0) < 1e-10

  test "character colors length":
    check CHAR_COLORS.len == 6

  test "character dimensions":
    check CHAR_WIDTH > 0
    check CHAR_HEIGHT > 0
