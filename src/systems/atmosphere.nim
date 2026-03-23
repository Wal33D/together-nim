## Atmospheric background effects — gradient, floating particles, light shafts

import
  std/math,
  "../constants",
  random

type
  AtmosParticle* = object
    x*, y*: float
    baseX*: float
    vx*, vy*: float
    color*: Color
    alpha*: uint8
    size*: float
    age*: float
    maxLife*: float

  LightShaft* = object
    x*: float
    width*: float
    alpha*: uint8
    vx*: float

  Atmosphere* = object
    particles*: seq[AtmosParticle]
    shafts*: seq[LightShaft]
    colors*: seq[Color]
    useLifetime*: bool

const
  AtmosParticleCount* = 12
  AtmosShaftCount* = 3
  MenuParticleCount* = 15
  MenuColors*: array[3, Color] = [
    (r: 255'u8, g: 220'u8, b: 140'u8),  # Soft gold.
    (r: 255'u8, g: 190'u8, b: 200'u8),  # Pale pink.
    (r: 160'u8, g: 230'u8, b: 220'u8),  # Light teal.
  ]

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
    size: 2.0 + rand(2.0),
    age: 0.0,
    maxLife: 0.0,
  )

proc randomMenuParticle*(): AtmosParticle =
  ## Create a menu ambient particle with warm colors and gentle drift.
  let
    c = MenuColors[rand(MenuColors.len - 1)]
    startX = rand(float(DEFAULT_WIDTH))
  result = AtmosParticle(
    x: startX,
    y: rand(float(DEFAULT_HEIGHT)),
    baseX: startX,
    vx: 0.0,
    vy: -(10.0 + rand(10.0)),
    color: c,
    alpha: uint8(51 + rand(51)),
    size: 2.0 + rand(1.5),
    age: 0.0,
    maxLife: 4.0 + rand(2.0),
  )

proc newAtmosphere*(colors: seq[Color]): Atmosphere =
  result.colors = colors
  result.particles = @[]
  result.shafts = @[]
  result.useLifetime = false
  for i in 0..<AtmosParticleCount:
    result.particles.add(randomAtmosParticle(colors))
  let shaftPositions = [DEFAULT_WIDTH div 6, DEFAULT_WIDTH div 2, DEFAULT_WIDTH * 5 div 6]
  for i in 0..<AtmosShaftCount:
    result.shafts.add(LightShaft(
      x: float(shaftPositions[i]),
      width: float(20 + rand(30)),
      alpha: uint8(8 + rand(10)),
      vx: (rand(1.0) - 0.5) * 8.0
    ))

proc newMenuAtmosphere*(): Atmosphere =
  ## Create atmosphere tuned for main menu ambient particles.
  result.colors = @MenuColors
  result.particles = @[]
  result.shafts = @[]
  result.useLifetime = true
  for i in 0..<MenuParticleCount:
    var p = randomMenuParticle()
    p.age = rand(p.maxLife)
    result.particles.add(p)

proc update*(atm: var Atmosphere, dt: float) =
  if atm.useLifetime:
    for i in 0..<atm.particles.len:
      atm.particles[i].age += dt
      atm.particles[i].y += atm.particles[i].vy * dt
      atm.particles[i].x = atm.particles[i].baseX +
        8.0 * sin(atm.particles[i].age * 0.5 * 2.0 * PI)
      if atm.particles[i].age >= atm.particles[i].maxLife:
        atm.particles[i] = randomMenuParticle()
        atm.particles[i].y = float(DEFAULT_HEIGHT) + 5.0
  else:
    for i in 0..<atm.particles.len:
      atm.particles[i].x += atm.particles[i].vx * dt
      atm.particles[i].y += atm.particles[i].vy * dt
      # Respawn if drifted off screen — reappear at bottom.
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
