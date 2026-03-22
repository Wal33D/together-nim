## Particle system for visual effects — subtle geometric bursts and dust

import "../constants"
import math
import random

type
  Particle* = object
    x*, y*: float
    vx*, vy*: float
    life*: float        ## remaining lifetime in seconds
    maxLife*: float     ## total lifetime for alpha calculation
    color*: Color
    size*: float        ## pixel size
    gravityScale*: float ## multiplier on gravity (0.0 = no gravity)
    fadeTime*: float     ## seconds before death to start fading (0.0 = fade over full lifetime)
    homing*: bool        ## if true, velocity converges toward (targetX, targetY)
    targetX*: float
    targetY*: float

  ParticleSystem* = object
    particles*: seq[Particle]

const MAX_PARTICLES = 200

proc pushParticle(system: var ParticleSystem, p: Particle) =
  if system.particles.len < MAX_PARTICLES:
    system.particles.add(p)

proc randRange(minValue, maxValue: float): float =
  if maxValue <= minValue:
    minValue
  else:
    minValue + rand(maxValue - minValue)

proc emitBurst*(system: var ParticleSystem, x, y: float, count: int,
                color: Color, spread, speed, verticalBias: float,
                lifeMin, lifeMax, sizeMin, sizeMax: float) =
  ## Spawn a shaped burst of particles at (x, y).
  for i in 0..<count:
    if system.particles.len >= MAX_PARTICLES:
      break
    let angle = rand(2.0 * PI)
    let speedScale = 0.3 + rand(0.7)
    let vx = cos(angle) * speed * speedScale
    let vy = sin(angle) * speed * speedScale + verticalBias
    let life = randRange(lifeMin, lifeMax)
    let size = randRange(sizeMin, sizeMax)
    pushParticle(system, Particle(
      x: x + randRange(-spread * 0.5, spread * 0.5),
      y: y + randRange(-spread * 0.15, spread * 0.15),
      vx: vx,
      vy: vy,
      life: life,
      maxLife: life,
      color: color,
      size: size,
      gravityScale: 1.0
    ))

proc emit*(system: var ParticleSystem, x, y: float, count: int,
           color: Color, spread, speed: float) =
  ## Legacy generic burst used by tests and older callers.
  system.emitBurst(x, y, count, color, spread, speed, -speed * 0.5,
                   0.25, 0.70, 2.0, 4.0)

proc blendWithWhite(c: Color, whiteFraction: float): Color =
  ## Mix a color toward white by the given fraction.
  let f = 1.0 - whiteFraction
  result.r = uint8(float(c.r) * f + 255.0 * whiteFraction)
  result.g = uint8(float(c.g) * f + 255.0 * whiteFraction)
  result.b = uint8(float(c.b) * f + 255.0 * whiteFraction)

proc emitJumpFan(system: var ParticleSystem, x, y: float, color: Color,
                 count: int, halfArc: float) =
  ## Downward-fanning burst shared by jump and double-jump emitters.
  let blended = blendWithWhite(color, 0.3)
  const CenterAngle = 3.0 * PI / 2.0
  for i in 0..<count:
    if system.particles.len >= MAX_PARTICLES:
      break
    let angle = CenterAngle + randRange(-halfArc, halfArc)
    let speed = randRange(80.0, 150.0)
    let size = randRange(3.0, 5.0)
    pushParticle(system, Particle(
      x: x,
      y: y,
      vx: cos(angle) * speed,
      vy: sin(angle) * speed,
      life: 0.3,
      maxLife: 0.3,
      color: blended,
      size: size,
      gravityScale: 1.0
    ))

proc emitJump*(system: var ParticleSystem, x, y: float, color: Color) =
  ## Downward-fanning burst at character feet for jump takeoff.
  let count = 6 + rand(2)
  system.emitJumpFan(x, y, color, count, PI / 3.0)

proc emitDoubleJump*(system: var ParticleSystem, x, y: float, color: Color) =
  ## Wider downward burst for Pip's double-jump.
  system.emitJumpFan(x, y, color, 10, 4.0 * PI / 9.0)

proc emitLanding*(system: var ParticleSystem, x, y: float, color: Color) =
  ## Low dust puff for touchdown.
  system.emitBurst(x, y, 6, color, 14.0, 22.0, 10.0, 0.20, 0.40, 1.5, 3.2)

proc emitDeath*(system: var ParticleSystem, x, y: float, color: Color) =
  ## Wider burst used when a character dies and respawns.
  system.emitBurst(x, y, 10, color, 20.0, 42.0, -6.0, 0.22, 0.55, 2.0, 4.0)

proc emitExit*(system: var ParticleSystem, x, y: float, color: Color) =
  ## Short chime-like burst around a reached exit.
  system.emitBurst(x, y, 6, color, 12.0, 28.0, -10.0, 0.20, 0.42, 1.5, 3.0)

proc emitCompletion*(system: var ParticleSystem, x, y: float, color: Color) =
  ## Slightly brighter celebration burst for level completion.
  system.emitBurst(x, y, 8, color, 18.0, 34.0, -14.0, 0.24, 0.50, 1.5, 3.4)

proc emitWallSpark*(system: var ParticleSystem, x, y: float, charH: float,
                    wallOnRight: bool) =
  ## Emit trailing sparks at the wall-contact edge during a wall slide.
  const
    SparkColor: Color = (r: 255'u8, g: 255'u8, b: 204'u8)
    SparkLife = 0.15
  for i in 0..<2:
    if system.particles.len >= MAX_PARTICLES:
      break
    let spawnY = y + rand(charH * 0.5)
    let hScatter = randRange(-15.0, 15.0)
    let size = randRange(2.0, 3.0)
    pushParticle(system, Particle(
      x: x,
      y: spawnY,
      vx: hScatter,
      vy: 120.0,
      life: SparkLife,
      maxLife: SparkLife,
      color: SparkColor,
      size: size,
      gravityScale: 1.0
    ))

proc emitButtonShimmer*(system: var ParticleSystem, x, y: float, color: Color) =
  ## Ring burst of 12 particles radiating from (x, y).
  const
    ShimmerLife = 0.5
    ParticleCount = 12
  for i in 0..<ParticleCount:
    if system.particles.len >= MAX_PARTICLES:
      break
    let angle = float(i) * 30.0 * PI / 180.0
    let speed = randRange(60.0, 100.0)
    let vx = cos(angle) * speed
    let vy = sin(angle) * speed + (-20.0)
    let size = randRange(4.0, 6.0)
    pushParticle(system, Particle(
      x: x,
      y: y,
      vx: vx,
      vy: vy,
      life: ShimmerLife,
      maxLife: ShimmerLife,
      color: color,
      size: size,
      gravityScale: 1.0
    ))

proc emitExitBeckoning*(system: var ParticleSystem, exitX, exitY, exitW, exitH: float, color: Color) =
  ## One rising particle from a random point within the exit zone.
  let spawnX = exitX + rand(exitW)
  let spawnY = exitY + rand(exitH)
  let size = randRange(3.0, 4.0)
  const BeckonLife = 2.0
  pushParticle(system, Particle(
    x: spawnX,
    y: spawnY,
    vx: randRange(-10.0, 10.0),
    vy: -30.0,
    life: BeckonLife,
    maxLife: BeckonLife,
    color: color,
    size: size,
    gravityScale: 0.0,
    fadeTime: 0.5
  ))

proc emitDeathDissolve*(system: var ParticleSystem, x, y: float, color: Color) =
  ## Outward burst of 15-20 particles with gravity for death dissolve.
  let count = 15 + rand(5)
  for i in 0..<count:
    if system.particles.len >= MAX_PARTICLES:
      break
    let angle = rand(2.0 * PI)
    let speed = randRange(100.0, 250.0)
    let size = randRange(4.0, 8.0)
    const DissolveLife = 0.4
    pushParticle(system, Particle(
      x: x,
      y: y,
      vx: cos(angle) * speed,
      vy: sin(angle) * speed,
      life: DissolveLife,
      maxLife: DissolveLife,
      color: color,
      size: size,
      gravityScale: 1.0
    ))

proc emitRespawnReform*(system: var ParticleSystem, spawnX, spawnY: float, color: Color) =
  ## Converging particles from a 150px radius toward the spawn point.
  let count = 15 + rand(5)
  for i in 0..<count:
    if system.particles.len >= MAX_PARTICLES:
      break
    let angle = rand(2.0 * PI)
    let dist = randRange(50.0, 150.0)
    let size = randRange(4.0, 8.0)
    const ReformLife = 0.3
    pushParticle(system, Particle(
      x: spawnX + cos(angle) * dist,
      y: spawnY + sin(angle) * dist,
      vx: 0.0,
      vy: 0.0,
      life: ReformLife,
      maxLife: ReformLife,
      color: color,
      size: size,
      gravityScale: 0.0,
      homing: true,
      targetX: spawnX,
      targetY: spawnY
    ))

proc update*(system: var ParticleSystem, dt: float) =
  ## Advance all particles and remove dead ones.
  var i = 0
  while i < system.particles.len:
    var p = system.particles[i]
    p.life -= dt
    if p.life <= 0.0:
      system.particles.del(i)
    else:
      if p.homing:
        let elapsed = p.maxLife - p.life
        let t = min(1.0, elapsed / p.maxLife)
        let strength = 3.0 * t * t
        p.vx = (p.targetX - p.x) * strength
        p.vy = (p.targetY - p.y) * strength
      p.x += p.vx * dt
      p.y += p.vy * dt
      p.vy += 280.0 * p.gravityScale * dt  # gentle downward gravity
      p.vx *= pow(0.88, dt * 60.0)  # frame-rate-independent friction
      system.particles[i] = p
      inc i
