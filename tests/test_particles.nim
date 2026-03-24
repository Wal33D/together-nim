import unittest
import "../src/systems/particles"
import "../src/constants"

suite "particle system":
  test "emit adds particles to empty system":
    var sys = ParticleSystem(particles: @[])
    let color: Color = (r: 160'u8, g: 160'u8, b: 170'u8)
    emit(sys, 100.0, 200.0, 6, color, 20.0, 55.0)
    check sys.particles.len == 6

  test "emit respects MAX_PARTICLES cap":
    var sys = ParticleSystem(particles: @[])
    let color: Color = (r: 255'u8, g: 255'u8, b: 255'u8)
    # Fill to near capacity
    emit(sys, 0.0, 0.0, 195, color, 10.0, 30.0)
    # Try to add 10 more — only 5 fit (cap is 200)
    emit(sys, 0.0, 0.0, 10, color, 10.0, 30.0)
    check sys.particles.len == 200

  test "emitted particles have positive life":
    var sys = ParticleSystem(particles: @[])
    let color: Color = (r: 100'u8, g: 200'u8, b: 50'u8)
    emit(sys, 50.0, 50.0, 3, color, 15.0, 40.0)
    for p in sys.particles:
      check p.life > 0.0

  test "emitted particles have positive maxLife":
    var sys = ParticleSystem(particles: @[])
    let color: Color = (r: 100'u8, g: 200'u8, b: 50'u8)
    emit(sys, 50.0, 50.0, 3, color, 15.0, 40.0)
    for p in sys.particles:
      check p.maxLife > 0.0

  test "emitted particles have positive size":
    var sys = ParticleSystem(particles: @[])
    let color: Color = (r: 100'u8, g: 200'u8, b: 50'u8)
    emit(sys, 50.0, 50.0, 4, color, 15.0, 40.0)
    for p in sys.particles:
      check p.size > 0.0

  test "update reduces particle life":
    var sys = ParticleSystem(particles: @[])
    let color: Color = (r: 255'u8, g: 100'u8, b: 100'u8)
    emit(sys, 0.0, 0.0, 3, color, 10.0, 30.0)
    let lifeBefore = sys.particles[0].life
    update(sys, 0.05)
    check sys.particles[0].life < lifeBefore

  test "update removes dead particles":
    var sys = ParticleSystem(particles: @[])
    let color: Color = (r: 255'u8, g: 255'u8, b: 255'u8)
    emit(sys, 0.0, 0.0, 5, color, 10.0, 20.0)
    # Advance far past particle lifetime
    update(sys, 10.0)
    check sys.particles.len == 0

  test "update moves particles":
    var sys = ParticleSystem(particles: @[])
    let color: Color = (r: 200'u8, g: 200'u8, b: 200'u8)
    emit(sys, 100.0, 100.0, 1, color, 0.0, 60.0)
    let xBefore = sys.particles[0].x
    let yBefore = sys.particles[0].y
    update(sys, 0.1)
    # At least one coordinate must have changed
    check sys.particles[0].x != xBefore or sys.particles[0].y != yBefore

  test "emit with count 0 adds no particles":
    var sys = ParticleSystem(particles: @[])
    let color: Color = (r: 0'u8, g: 0'u8, b: 0'u8)
    emit(sys, 0.0, 0.0, 0, color, 10.0, 30.0)
    check sys.particles.len == 0

  test "update on empty system does not crash":
    var sys = ParticleSystem(particles: @[])
    update(sys, 0.016)
    check sys.particles.len == 0

  test "emitSuperBounce emits 10 particles":
    var sys = ParticleSystem(particles: @[])
    emitSuperBounce(sys, 100.0, 200.0)
    check sys.particles.len == 10

  test "emitSuperBounce particles have 0.4s lifetime":
    var sys = ParticleSystem(particles: @[])
    emitSuperBounce(sys, 100.0, 200.0)
    for p in sys.particles:
      check abs(p.maxLife - 0.4) < 0.001
