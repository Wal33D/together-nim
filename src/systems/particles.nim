## Particle system for visual effects — landing dust and exit sparkles

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

proc emit*(system: var ParticleSystem, x, y: float, count: int,
           color: Color, spread, speed: float) =
  ## Spawn a burst of particles at (x, y).
  for i in 0..<count:
    if system.particles.len >= MAX_PARTICLES:
      break
    let angle = rand(2.0 * PI)
    let vx = cos(angle) * speed * (0.3 + rand(0.7))
    let vy = sin(angle) * speed * (0.3 + rand(0.7)) - speed * 0.5  # upward bias
    let life = 0.25 + rand(0.45)
    let p = Particle(
      x: x + rand(spread) - spread * 0.5,
      y: y,
      vx: vx,
      vy: vy,
      life: life,
      maxLife: life,
      color: color,
      size: 2.0 + rand(2.0)
    )
    system.particles.add(p)

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
