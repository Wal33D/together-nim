import unittest
import "../src/constants"

suite "constants":
  test "physics constants":
    check GRAVITY == 800.0
    check JUMP_VELOCITY == -380.0
    check MAX_FALL_SPEED == 600.0
    check TERMINAL_VELOCITY == MAX_FALL_SPEED

  test "window constants":
    check DEFAULT_WIDTH == 800
    check DEFAULT_HEIGHT == 500

  test "timing constant":
    check abs(FIXED_TIMESTEP - 1.0 / 60.0) < 1e-10

  test "character colors":
    check PIP_COLOR.r == 255
    check LUCA_COLOR.g == 217
    check BRUNO_COLOR.r == 107
