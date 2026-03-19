## Atmospheric background effects — gradient, floating particles, light shafts

import "../constants"
import random
import math

type
  AtmosParticle* = object
    x*, y*: float
    vx*, vy*: float
    color*: Color
    alpha*: uint8
    size*: float

  LightShaft* = object
    x*: float
    width*: float
    alpha*: uint8
    vx*: float

  Atmosphere* = object
    particles*: seq[AtmosParticle]
    shafts*: seq[LightShaft]
    colors*: seq[Color]

const ATMOS_PARTICLE_COUNT* = 12
const ATMOS_SHAFT_COUNT* = 3

proc randomAtmosParticle*(colors: seq[Color]): AtmosParticle =
  let c =
    if colors.len > 0: colors[rand(colors.len - 1)]
    else: (r: 128'u8, g: 128'u8, b: 200'u8)
  result = AtmosParticle(
    x: rand(float(DEFAULT_WIDTH)),
    y: rand(float(DEFAULT_HEIGHT)),
    vx: (rand(1.0) - 0.5) * 12.0,
    vy: -5.0 - rand(10.0),
    color: c,
    alpha: uint8(20 + rand(10)),
    size: 2.0 + rand(2.0)
  )

proc newAtmosphere*(colors: seq[Color]): Atmosphere =
  result.colors = colors
  result.particles = @[]
  result.shafts = @[]
  for i in 0..<ATMOS_PARTICLE_COUNT:
    result.particles.add(randomAtmosParticle(colors))
  let shaftPositions = [DEFAULT_WIDTH div 6, DEFAULT_WIDTH div 2, DEFAULT_WIDTH * 5 div 6]
  for i in 0..<ATMOS_SHAFT_COUNT:
    result.shafts.add(LightShaft(
      x: float(shaftPositions[i]),
      width: float(20 + rand(30)),
      alpha: uint8(8 + rand(10)),
      vx: (rand(1.0) - 0.5) * 8.0
    ))

proc update*(atm: var Atmosphere, dt: float) =
  for i in 0..<atm.particles.len:
    atm.particles[i].x += atm.particles[i].vx * dt
    atm.particles[i].y += atm.particles[i].vy * dt
    # Respawn if drifted off screen — reappear at bottom
    if atm.particles[i].y < -10.0 or
       atm.particles[i].x < -10.0 or
       atm.particles[i].x > float(DEFAULT_WIDTH) + 10.0:
      atm.particles[i] = randomAtmosParticle(atm.colors)
      atm.particles[i].y = float(DEFAULT_HEIGHT) + 5.0
  for i in 0..<atm.shafts.len:
    atm.shafts[i].x += atm.shafts[i].vx * dt
    if atm.shafts[i].x > float(DEFAULT_WIDTH) + 60.0:
      atm.shafts[i].x = -60.0
    elif atm.shafts[i].x < -60.0:
      atm.shafts[i].x = float(DEFAULT_WIDTH) + 60.0
