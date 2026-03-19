import unittest
import "../src/systems/atmosphere"
import "../src/constants"

suite "atmosphere system":
  test "newAtmosphere creates correct particle count":
    let colors: seq[Color] = @[PIP_COLOR, LUCA_COLOR]
    let atm = newAtmosphere(colors)
    check atm.particles.len == ATMOS_PARTICLE_COUNT

  test "newAtmosphere creates correct shaft count":
    let colors: seq[Color] = @[CARA_COLOR]
    let atm = newAtmosphere(colors)
    check atm.shafts.len == ATMOS_SHAFT_COUNT

  test "newAtmosphere with empty colors does not crash":
    let atm = newAtmosphere(@[])
    check atm.particles.len == ATMOS_PARTICLE_COUNT
    check atm.shafts.len == ATMOS_SHAFT_COUNT

  test "particles have alpha in expected range":
    let colors: seq[Color] = @[PIP_COLOR, LUCA_COLOR, BRUNO_COLOR]
    let atm = newAtmosphere(colors)
    for p in atm.particles:
      check p.alpha >= 20
      check p.alpha <= 30

  test "particles have positive size":
    let colors: seq[Color] = @[IVY_COLOR]
    let atm = newAtmosphere(colors)
    for p in atm.particles:
      check p.size > 0.0

  test "shafts have low alpha for subtlety":
    let atm = newAtmosphere(@[FELIX_COLOR])
    for s in atm.shafts:
      check s.alpha < 30

  test "update moves particles":
    let colors: seq[Color] = @[PIP_COLOR]
    var atm = newAtmosphere(colors)
    let yBefore = atm.particles[0].y
    update(atm, 1.0)
    # Particle should have moved (vy is always negative — upward)
    check atm.particles[0].y != yBefore

  test "update respawns particles that drift above screen":
    var atm = newAtmosphere(@[LUCA_COLOR])
    # Place a particle just above the screen
    atm.particles[0].y = -20.0
    atm.particles[0].x = 100.0
    update(atm, 0.016)
    # After respawn, y should be near bottom (DEFAULT_HEIGHT + 5)
    check atm.particles[0].y > float(DEFAULT_HEIGHT) - 10.0

  test "update moves light shafts":
    var atm = newAtmosphere(@[CARA_COLOR])
    # Force a non-zero velocity
    atm.shafts[0].vx = 20.0
    let xBefore = atm.shafts[0].x
    update(atm, 0.1)
    check atm.shafts[0].x != xBefore

  test "light shafts wrap when they drift off right edge":
    var atm = newAtmosphere(@[])
    atm.shafts[0].x = float(DEFAULT_WIDTH) + 70.0
    atm.shafts[0].vx = 1.0
    update(atm, 0.016)
    check atm.shafts[0].x < 0.0

  test "light shafts wrap when they drift off left edge":
    var atm = newAtmosphere(@[])
    atm.shafts[0].x = -70.0
    atm.shafts[0].vx = -1.0
    update(atm, 0.016)
    check atm.shafts[0].x > float(DEFAULT_WIDTH)
