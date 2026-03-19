import unittest
import "../src/systems/camera"
import "../src/constants"

suite "camera":
  test "newCamera starts at origin":
    let cam = newCamera()
    check cam.x == 0.0
    check cam.y == 0.0
    check cam.targetX == 0.0
    check cam.targetY == 0.0

  test "updateCamera lerps toward target":
    var cam = newCamera()
    # Character at world (800, 300) on a 1200px level — camera should lerp right
    updateCamera(cam, 800.0, 300.0, 24.0, 24.0, 1200.0, 500.0)
    check cam.x > 0.0

  test "camera clamps to level left edge":
    var cam = newCamera()
    # Character at world origin — camera should stay at 0
    updateCamera(cam, 0.0, 0.0, 24.0, 24.0, 800.0, 500.0)
    check cam.x >= 0.0
    check cam.y >= 0.0

  test "camera clamps to level right edge":
    var cam = newCamera()
    # Snap to far right of a 1200px level
    snapCamera(cam, 1170.0, 460.0, 24.0, 24.0, 1200.0, 500.0)
    check cam.x <= 1200.0 - float(DEFAULT_WIDTH)

  test "snapCamera places camera immediately without lerp":
    var cam = newCamera()
    snapCamera(cam, 600.0, 300.0, 24.0, 24.0, 1200.0, 500.0)
    let expectedX = max(0.0, min(600.0 + 12.0 - float(DEFAULT_WIDTH) * 0.5, 1200.0 - float(DEFAULT_WIDTH)))
    check abs(cam.x - expectedX) < 0.001

  test "camera does not scroll on 800px level (no room)":
    var cam = newCamera()
    # On an 800px-wide level, camera max scroll is 0
    snapCamera(cam, 400.0, 250.0, 24.0, 24.0, 800.0, 500.0)
    check cam.x == 0.0

  test "camera scrolls on wider level":
    var cam = newCamera()
    # On a 1200px-wide level, camera can scroll up to 400px
    snapCamera(cam, 800.0, 250.0, 24.0, 24.0, 1200.0, 500.0)
    check cam.x > 0.0
    check cam.x <= 400.0

  test "camera y stays zero when level fits vertically":
    var cam = newCamera()
    updateCamera(cam, 400.0, 250.0, 24.0, 24.0, 1200.0, 500.0)
    check cam.y == 0.0
