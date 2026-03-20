## Particle system for visual effects — subtle geometric bursts and dust

import "../constants"
import math
import random

type
  Particle* = object
    x*, y*: float
    vx*, vy*: float
    life*: float     ## remaining lifetime in seconds
    maxLife*: float  ## total lifetime for alpha calculation
    color*: Color
    size*: float     ## pixel size

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
      size: size
    ))

proc emit*(system: var ParticleSystem, x, y: float, count: int,
           color: Color, spread, speed: float) =
  ## Legacy generic burst used by tests and older callers.
  system.emitBurst(x, y, count, color, spread, speed, -speed * 0.5,
                   0.25, 0.70, 2.0, 4.0)

proc emitJump*(system: var ParticleSystem, x, y: float, color: Color) =
  ## Small, upward-leaning burst for jump takeoff.
  system.emitBurst(x, y, 4, color, 8.0, 34.0, -18.0, 0.18, 0.34, 1.5, 2.6)

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

proc update*(system: var ParticleSystem, dt: float) =
  ## Advance all particles and remove dead ones.
  var i = 0
  while i < system.particles.len:
    var p = system.particles[i]
    p.life -= dt
    if p.life <= 0.0:
      system.particles.del(i)
    else:
      p.x += p.vx * dt
      p.y += p.vy * dt
      p.vy += 280.0 * dt  # gentle downward gravity
      p.vx *= pow(0.88, dt * 60.0)  # frame-rate-independent friction
      system.particles[i] = p
      inc i
