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
    check cam.lookAheadX == 0.0
    check cam.lookAheadY == 0.0
    check cam.impulseX == 0.0
    check cam.impulseY == 0.0
    check cam.responseBoost == 0.0
    check cam.holdTimer == 0.0

  test "updateCamera lerps toward target":
    var cam = newCamera()
    # Character at world (800, 300) on a 1200px level — camera should lerp right
    updateCamera(cam, 800.0, 300.0, 24.0, 24.0, 1200.0, 500.0)
    check cam.x > 0.0

  test "moving right builds positive look-ahead":
    var cam = newCamera()
    updateCamera(cam, 500.0, 250.0, 24.0, 24.0, 180.0, 0.0, true,
                 1800.0, 900.0, FIXED_TIMESTEP)
    check cam.lookAheadX > 0.0

  test "idle facing left keeps a slight left bias":
    var cam = newCamera()
    updateCamera(cam, 700.0, 250.0, 24.0, 24.0, 0.0, 0.0, false,
                 1800.0, 900.0, FIXED_TIMESTEP)
    check cam.lookAheadX < 0.0

  test "camera impulse shifts the target immediately":
    var cam = newCamera()
    cam.addImpulse(16.0, -10.0)
    updateCamera(cam, 700.0, 300.0, 24.0, 24.0, 0.0, 0.0, true,
                 1800.0, 1000.0, FIXED_TIMESTEP)
    let centeredX = 700.0 + 12.0 - float(DEFAULT_WIDTH) * 0.5
    let centeredY = 300.0 + 12.0 - float(DEFAULT_HEIGHT) * 0.5
    check cam.targetX > centeredX
    check cam.targetY < centeredY

  test "response boost accelerates follow speed":
    var baseCam = newCamera()
    var boostedCam = newCamera()
    boostedCam.boostResponse(0.18)

    updateCamera(baseCam, 900.0, 250.0, 24.0, 24.0, 120.0, 0.0, true,
                 2200.0, 900.0, FIXED_TIMESTEP)
    updateCamera(boostedCam, 900.0, 250.0, 24.0, 24.0, 120.0, 0.0, true,
                 2200.0, 900.0, FIXED_TIMESTEP)

    check boostedCam.x > baseCam.x

  test "hold freezes camera motion until it expires":
    var cam = newCamera()
    cam.hold(0.05)

    updateCamera(cam, 900.0, 250.0, 24.0, 24.0, 120.0, 0.0, true,
                 2200.0, 900.0, FIXED_TIMESTEP)
    check cam.x == 0.0
    check cam.holdTimer > 0.0

    for _ in 0..4:
      updateCamera(cam, 900.0, 250.0, 24.0, 24.0, 120.0, 0.0, true,
                   2200.0, 900.0, FIXED_TIMESTEP)
    check cam.x > 0.0

  test "queued snap applies after hold releases":
    var cam = newCamera()
    snapCamera(cam, 900.0, 250.0, 24.0, 24.0, 2200.0, 900.0)
    let heldX = cam.x
    cam.hold(0.05)
    cam.queueSnap(40.0, 250.0, 24.0, 24.0, 2200.0, 900.0)

    updateCamera(cam, 40.0, 250.0, 24.0, 24.0, 0.0, 0.0, true,
                 2200.0, 900.0, FIXED_TIMESTEP)
    check cam.x == heldX

    for _ in 0..3:
      updateCamera(cam, 40.0, 250.0, 24.0, 24.0, 0.0, 0.0, true,
                   2200.0, 900.0, FIXED_TIMESTEP)
    check cam.x == 0.0

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
    cam.addImpulse(10.0, -6.0)
    cam.boostResponse(0.2)
    snapCamera(cam, 600.0, 300.0, 24.0, 24.0, 1200.0, 500.0)
    let expectedX = max(0.0, min(600.0 + 12.0 - float(DEFAULT_WIDTH) * 0.5, 1200.0 - float(DEFAULT_WIDTH)))
    check abs(cam.x - expectedX) < 0.001
    check cam.lookAheadX == 0.0
    check cam.lookAheadY == 0.0
    check cam.impulseX == 0.0
    check cam.impulseY == 0.0
    check cam.responseBoost == 0.0
    check cam.holdTimer == 0.0

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

  test "triggerShake sets timer and intensity":
    var cam = newCamera()
    cam.triggerShake(4.0, 0.3)
    check cam.shakeTimer == 0.3
    check cam.shakeIntensity == 4.0

  test "updateShake produces nonzero offsets while active":
    var cam = newCamera()
    cam.triggerShake(4.0, 0.3)
    cam.updateShake(0.016)
    check cam.shakeTimer > 0.0
    check cam.shakeOffsetX != 0.0 or cam.shakeOffsetY != 0.0

  test "updateShake clears offsets when timer expires":
    var cam = newCamera()
    cam.triggerShake(4.0, 0.3)
    cam.updateShake(0.5)  # advance past the 300ms duration
    check cam.shakeTimer == 0.0
    check cam.shakeOffsetX == 0.0
    check cam.shakeOffsetY == 0.0

  test "shake offsets are zero when no shake active":
    var cam = newCamera()
    cam.updateShake(0.016)
    check cam.shakeOffsetX == 0.0
    check cam.shakeOffsetY == 0.0
