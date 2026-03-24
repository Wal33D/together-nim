## Boxy-backed renderer for Together — menu, gameplay, narration, win screen

import "../entities/character"
import "../entities/level"
import "levels"
import "../constants"
import "../game"
import "camera"
import "atmosphere"
import "backdrop"
import "particles"
import "render_backend"
import "screenEffects"
import math
import random
import chroma
import vmath

const
  ActTints: array[5, (uint8, uint8, uint8, uint8)] = [
    (255'u8, 200'u8, 100'u8, 20'u8),  # Act 1: warm gold
    (100'u8, 160'u8, 255'u8, 20'u8),  # Act 2: soft blue
    (160'u8, 100'u8, 200'u8, 20'u8),  # Act 3: muted purple
    (60'u8,  60'u8,  140'u8, 26'u8),  # Act 4: deep indigo
    (255'u8, 255'u8, 255'u8, 15'u8),  # Act 5: white/prismatic
  ]
  VignetteDepth = 100
  VignettePasses = 3

  BgCharCount = 8
  BgCharMinSize = 24.0
  BgCharMaxSize = 56.0
  BgCharMinAlpha = 0.5
  BgCharMaxAlpha = 0.7
  BgCharMaxSpeed = 30.0

type
  BgChar = object
    pos: Vec2
    vel: Vec2
    charIdx: int    # 0-5, maps to character color
    size: float     # 24..56 px — smaller = further back (slower)
    alpha: float    # 0.5..0.7

var
  bgChars: array[BgCharCount, BgChar]
  bgCharsInit: bool = false

proc initBgChars() =
  ## Populate background character shapes with random positions and slow drift.
  for i in 0 ..< BgCharCount:
    let size = BgCharMinSize + rand(BgCharMaxSize - BgCharMinSize)
    let speedFactor = float32(size / BgCharMaxSize)
    bgChars[i] = BgChar(
      pos: vec2(float32(rand(DEFAULT_WIDTH.float - size)),
                float32(rand(DEFAULT_HEIGHT.float - size))),
      vel: vec2(float32((rand(2.0) - 1.0) * BgCharMaxSpeed) * speedFactor,
                float32((rand(2.0) - 1.0) * BgCharMaxSpeed) * speedFactor),
      charIdx: i mod 6,
      size: size,
      alpha: BgCharMinAlpha + rand(BgCharMaxAlpha - BgCharMinAlpha),
    )
  bgCharsInit = true

proc updateBgChars(dt: float) =
  ## Drift and bounce background character shapes off screen edges.
  let dt32 = dt.float32
  for i in 0 ..< BgCharCount:
    bgChars[i].pos += bgChars[i].vel * dt32
    let sz = bgChars[i].size.float32
    # Bounce off left/right.
    if bgChars[i].pos.x < 0.0:
      bgChars[i].pos.x = 0.0
      bgChars[i].vel.x = -bgChars[i].vel.x
    elif bgChars[i].pos.x + sz > DEFAULT_WIDTH.float32:
      bgChars[i].pos.x = DEFAULT_WIDTH.float32 - sz
      bgChars[i].vel.x = -bgChars[i].vel.x
    # Bounce off top/bottom.
    if bgChars[i].pos.y < 0.0:
      bgChars[i].pos.y = 0.0
      bgChars[i].vel.y = -bgChars[i].vel.y
    elif bgChars[i].pos.y + sz > DEFAULT_HEIGHT.float32:
      bgChars[i].pos.y = DEFAULT_HEIGHT.float32 - sz
      bgChars[i].vel.y = -bgChars[i].vel.y

proc renderBgChars(renderer: RendererPtr) =
  ## Draw background character silhouettes on the Boxy layer.
  renderer.setDrawBlendMode(BlendMode_Blend)
  for i in 0 ..< BgCharCount:
    let bg = bgChars[i]
    let c = CHAR_COLORS[bg.charIdx]
    let a = uint8(bg.alpha * 255.0)
    renderer.setDrawColor(c.r, c.g, c.b, a)
    drawFilledRect(renderer, bg.pos.x, bg.pos.y, bg.size, bg.size)
  renderer.setDrawBlendMode(BlendMode_None)

proc renderMenu(renderer: RendererPtr, game: Game) =
  if not bgCharsInit:
    initBgChars()
  updateBgChars(game.deltaTime)

  let top = (r: 8'u8, g: 11'u8, b: 18'u8)
  let bottom = (r: 18'u8, g: 24'u8, b: 34'u8)
  for i in 0 ..< 14:
    let bandY = i * (DEFAULT_HEIGHT div 14)
    let t = i.float / 13.0
    let bandColor = (
      r: uint8(float(top.r) + (float(bottom.r) - float(top.r)) * t),
      g: uint8(float(top.g) + (float(bottom.g) - float(top.g)) * t),
      b: uint8(float(top.b) + (float(bottom.b) - float(top.b)) * t)
    )
    renderer.setDrawColor(bandColor.r, bandColor.g, bandColor.b, 255)
    drawFilledRect(renderer, 0, bandY.cint, DEFAULT_WIDTH.cint, (DEFAULT_HEIGHT div 14 + 1).cint)

  # Bouncing character shapes — behind UI fog panels.
  renderBgChars(renderer)

  renderer.setDrawBlendMode(BlendMode_Blend)
  renderer.setDrawColor(84, 110, 150, 28)
  drawFilledRect(renderer, 64, 70, 340, 280)
  renderer.setDrawColor(64, 82, 112, 20)
  drawFilledRect(renderer, 520, 52, 280, 220)
  renderer.setDrawColor(56, 70, 96, 18)
  drawFilledRect(renderer, 420, 320, 360, 120)

  for p in game.menuAtmosphere.particles:
    renderer.setDrawColor(p.color.r, p.color.g, p.color.b, p.alpha)
    let sz = max(1, p.size.cint)
    drawFilledRect(renderer, p.x.cint, p.y.cint, sz, sz)
  renderer.setDrawBlendMode(BlendMode_None)

proc renderAtmosphereOverlay(renderer: RendererPtr, atm: Atmosphere) =
  renderer.setDrawBlendMode(BlendMode_Blend)

  for shaft in atm.shafts:
    renderer.setDrawColor(180, 180, 220, shaft.alpha)
    drawFilledRect(renderer, shaft.x.cint, 0, shaft.width.cint, DEFAULT_HEIGHT.cint)

  for p in atm.particles:
    renderer.setDrawColor(p.color.r, p.color.g, p.color.b, p.alpha)
    let sz = max(1, p.size.cint)
    drawFilledRect(renderer, p.x.cint, p.y.cint, sz, sz)

  renderer.setDrawBlendMode(BlendMode_None)

proc renderParticleSystem(renderer: RendererPtr, system: ParticleSystem,
                          camX, camY: int) =
  if system.particles.len == 0:
    return

  renderer.setDrawBlendMode(BlendMode_Blend)
  for p in system.particles:
    let fadeWindow = if p.fadeTime > 0.0: p.fadeTime else: p.maxLife
    let lifeRatio = if fadeWindow > 0.0: (if p.life < fadeWindow: max(0.0, min(1.0, p.life / fadeWindow)) else: 1.0) else: 0.0
    let alpha = uint8(max(0.0, min(255.0, lifeRatio * 220.0)))
    let sz = max(1, p.size.cint).int
    let x = p.x.cint - camX
    let y = p.y.cint - camY
    let rx = x.cint
    let ry = y.cint
    let rsz = sz.cint

    renderer.setDrawColor(p.color.r, p.color.g, p.color.b, alpha div 2)
    drawFilledRect(renderer, (rx - 1).cint, (ry - 1).cint,
                   (rsz + 2).cint, (rsz + 2).cint)

    renderer.setDrawColor(p.color.r, p.color.g, p.color.b, alpha)
    drawFilledRect(renderer, rx, ry, rsz, rsz)

    if sz >= 3:
      renderer.setDrawColor(255, 255, 255, alpha div 3)
      drawOutlineRect(renderer, rx, ry, rsz, rsz)
  renderer.setDrawBlendMode(BlendMode_None)

proc renderAmbientOverlay(renderer: RendererPtr, levelIdx: int) =
  ## Draw per-act color tint and vignette darkening at screen edges.
  let actIdx = actForLevel(levelIdx)
  if actIdx < 0:
    return

  renderer.setDrawBlendMode(BlendMode_Blend)

  # Per-act tint — full-screen rect.
  let tint = ActTints[actIdx]
  renderer.setDrawColor(tint[0], tint[1], tint[2], tint[3])
  drawFilledRect(renderer, 0, 0, DEFAULT_WIDTH.cint, DEFAULT_HEIGHT.cint)

  # Vignette — 3 passes per edge, each narrower and slightly more opaque.
  for pass in 0 ..< VignettePasses:
    let t = float(VignettePasses - pass) / float(VignettePasses)
    let w = int(float(VignetteDepth) * t)
    let alpha = uint8(float(38) * (1.0 - t) / float(VignettePasses - 1) + 5.0)
    renderer.setDrawColor(0, 0, 0, alpha)
    # Left edge.
    drawFilledRect(renderer, 0, 0, w.cint, DEFAULT_HEIGHT.cint)
    # Right edge.
    drawFilledRect(renderer, (DEFAULT_WIDTH - w).cint, 0, w.cint, DEFAULT_HEIGHT.cint)
    # Top edge.
    drawFilledRect(renderer, 0, 0, DEFAULT_WIDTH.cint, w.cint)
    # Bottom edge.
    drawFilledRect(renderer, 0, (DEFAULT_HEIGHT - w).cint, DEFAULT_WIDTH.cint, w.cint)

  renderer.setDrawBlendMode(BlendMode_None)

proc renderConnectionLine(renderer: RendererPtr, x1, y1, x2, y2: float,
                           color: constants.Color, alpha: uint8) =
  ## Draw a faint dotted line between two points.
  let steps = 8
  for s in 0 .. steps:
    let t = float(s) / float(steps)
    let px = x1 + (x2 - x1) * t
    let py = y1 + (y2 - y1) * t
    renderer.setDrawColor(color.r, color.g, color.b, alpha)
    drawFilledRect(renderer, px - 1.0, py - 1.0, 2.0, 2.0)

proc renderGameplay(renderer: RendererPtr, game: Game) =
  if game.currentLevel < 0 or game.currentLevel >= allLevels.len:
    return

  let level = game.currentLevelState

  # Scenic backdrop — rendered BEFORE platforms and characters.
  renderBackdrop(renderer, level, game.camera.x, game.elapsedTime)
  renderAtmosphereOverlay(renderer, game.atmosphere)

  # Camera offset — subtract from all world-space coordinates (with shake)
  let camX = (game.camera.x + game.camera.shakeOffsetX).cint
  let camY = (game.camera.y + game.camera.shakeOffsetY).cint

  # Platforms (gradient fill: lighter top, darker bottom; 1px dark outline)
  for p in level.platforms:
    let px = p.x.cint - camX
    let py = p.y.cint - camY
    let pw = p.width.cint
    let ph = p.height.cint
    let bands = max(1, ph.int)
    for band in 0 ..< bands:
      let t = if bands > 1: float(band) / float(bands - 1) else: 0.0
      let r = uint8(110.0 + (70.0 - 110.0) * t)
      let g = uint8(110.0 + (70.0 - 110.0) * t)
      let b = uint8(135.0 + (90.0 - 135.0) * t)
      renderer.setDrawColor(r, g, b, 255)
      drawFilledRect(renderer, px, py + band.cint, pw, 1)
    renderer.setDrawColor(40, 40, 55, 255)
    drawOutlineRect(renderer, px, py, pw, ph)

  # Moving platform waypoint path indicators
  renderer.setDrawBlendMode(BlendMode_Blend)
  for mp in level.movingPlatforms:
    let n = mp.waypoints.len
    for wi in 0 ..< n - 1:
      let a = mp.waypoints[wi]
      let b = mp.waypoints[wi + 1]
      for di in 1 .. 3:
        let frac = float(di) / 4.0
        let dotX = a.x + (b.x - a.x) * frac + mp.width / 2.0
        let dotY = a.y + (b.y - a.y) * frac + mp.height / 2.0
        renderer.setDrawColor(150, 150, 175, 80)
        drawFilledRect(renderer, (dotX - 2).cint - camX, (dotY - 2).cint - camY, 4, 4)
  renderer.setDrawBlendMode(BlendMode_None)

  # Moving platforms (lighter gray to distinguish)
  for mp in level.movingPlatforms:
    renderer.setDrawColor(130, 130, 155, 255)
    drawFilledRect(renderer, mp.x.cint - camX, mp.y.cint - camY, mp.width.cint, mp.height.cint)
    # Top edge highlight
    renderer.setDrawColor(160, 160, 185, 255)
    drawFilledRect(renderer, mp.x.cint - camX, mp.y.cint - camY, mp.width.cint, 2)

  # Hazards (red spikes)
  renderer.setDrawColor(200, 50, 50, 255)
  for h in level.hazards:
    drawFilledRect(renderer, h.x.cint - camX, h.y.cint - camY, h.width.cint, h.height.cint)

  # Doors
  renderer.setDrawBlendMode(BlendMode_Blend)
  for d in level.doors:
    if not d.isOpen:
      renderer.setDrawColor(80, 80, 200, 160)
      drawFilledRect(renderer, d.x.cint - camX, d.y.cint - camY, d.width.cint, d.height.cint)
  renderer.setDrawBlendMode(BlendMode_None)

  # Buttons — bright yellow when pressed (any character overlaps), dim otherwise
  for b in level.buttons:
    var pressed = false
    for ch in game.characters:
      let chRight  = ch.x + float(ch.width)
      let chBottom = ch.y + float(ch.height)
      let bRight   = b.x + b.width
      let bBottom  = b.y + b.height
      if ch.x < bRight and chRight > b.x and ch.y < bBottom and chBottom > b.y:
        pressed = true
        break
    if pressed:
      renderer.setDrawColor(255, 255, 80, 255)
    else:
      renderer.setDrawColor(100, 80, 20, 255)
    drawFilledRect(renderer, b.x.cint - camX, b.y.cint - camY, b.width.cint, b.height.cint)

  # Exits (character-colored outlines with gentle glow)
  renderer.setDrawBlendMode(BlendMode_Blend)
  for e in level.exits:
    # Look up the character index so we can use the palette consistently
    var exitColor: constants.Color = (r: 128'u8, g: 128'u8, b: 128'u8)
    for i, charId in level.characters:
      if charId == e.characterId:
        exitColor = CHAR_COLORS[game.characters[i].colorIndex mod 6]
        break
    # Pulsing glow behind (sine wave, period 2s)
    let exitPulse = 0.5 + 0.5 * sin(game.elapsedTime * PI)
    let exitGlowAlpha = uint8(20.0 + 30.0 * exitPulse)
    renderer.setDrawColor(exitColor.r, exitColor.g, exitColor.b, exitGlowAlpha)
    drawFilledRect(renderer, (e.x - 4).cint - camX, (e.y - 4).cint - camY,
                   (e.width + 8).cint, (e.height + 8).cint)
    # Outline
    renderer.setDrawColor(exitColor.r, exitColor.g, exitColor.b, 200)
    drawOutlineRect(renderer, e.x.cint - camX, e.y.cint - camY, e.width.cint, e.height.cint)
  renderer.setDrawBlendMode(BlendMode_None)

  # Secret collectible orb — glowing yellow-white circle with alpha pulse
  block:
    let sc = level.starChallenge
    if (sc.secretX != 0.0 or sc.secretY != 0.0) and not game.secretCollected:
      let pulse = 0.6 + 0.4 * sin(game.elapsedTime * PI * 2.0)
      let orbX = sc.secretX.cint - camX
      let orbY = sc.secretY.cint - camY
      renderer.setDrawBlendMode(BlendMode_Blend)
      # Outer glow
      renderer.setDrawColor(255, 245, 157, uint8(30.0 * pulse))
      drawFilledRect(renderer, orbX - 12, orbY - 12, 24, 24)
      # Inner glow
      renderer.setDrawColor(255, 250, 200, uint8(80.0 * pulse))
      drawFilledRect(renderer, orbX - 8, orbY - 8, 16, 16)
      # Core
      renderer.setDrawColor(255, 255, 230, uint8(180.0 * pulse))
      drawFilledRect(renderer, orbX - 4, orbY - 4, 8, 8)
      renderer.setDrawBlendMode(BlendMode_None)

  renderParticleSystem(renderer, game.particles, camX, camY)

  # Connection lines between nearby characters
  if game.characters.len > 1:
    renderer.setDrawBlendMode(BlendMode_Blend)
    for i in 0 ..< game.characters.len:
      if game.characters[i].isDying() or game.characters[i].isRespawning():
        continue
      for j in (i + 1) ..< game.characters.len:
        if game.characters[j].isDying() or game.characters[j].isRespawning():
          continue
        let ci = game.characters[i]
        let cj = game.characters[j]
        let cx1 = ci.x + float(ci.width) * 0.5
        let cy1 = ci.y + float(ci.height) * 0.5
        let cx2 = cj.x + float(cj.width) * 0.5
        let cy2 = cj.y + float(cj.height) * 0.5
        let dx = cx2 - cx1
        let dy = cy2 - cy1
        let dist = sqrt(dx * dx + dy * dy)
        if dist < ProximityGlowRange:
          let avgColor: constants.Color = (
            r: uint8((int(ci.color.r) + int(cj.color.r)) div 2),
            g: uint8((int(ci.color.g) + int(cj.color.g)) div 2),
            b: uint8((int(ci.color.b) + int(cj.color.b)) div 2),
          )
          let fade = if dist < ProximityNear:
            uint8(15.0 + 5.0 * (1.0 - dist / ProximityNear))
          else:
            uint8(15.0 * (1.0 - (dist - ProximityNear) / (ProximityGlowRange - ProximityNear)))
          renderConnectionLine(renderer, cx1 - float(camX), cy1 - float(camY),
                               cx2 - float(camX), cy2 - float(camY), avgColor, fade)
    renderer.setDrawBlendMode(BlendMode_None)

  # Character shadows — ellipse below each character on nearest platform
  renderer.setDrawBlendMode(BlendMode_Blend)
  for ch in game.characters:
    if ch.isDying() or ch.isRespawning():
      continue
    let charBottom = ch.y + float(ch.height)
    let charLeft = ch.x
    let charRight = ch.x + float(ch.width)
    # Find nearest platform surface below the character.
    var shadowY = level.levelHeight
    for p in level.platforms:
      if p.y >= charBottom and p.x < charRight and p.x + p.width > charLeft:
        if p.y < shadowY:
          shadowY = p.y
    for mp in level.movingPlatforms:
      if mp.y >= charBottom and mp.x < charRight and mp.x + mp.width > charLeft:
        if mp.y < shadowY:
          shadowY = mp.y
    let dist = shadowY - charBottom
    let maxShadowDist = 200.0
    let alpha = if dist <= 0.0: 40'u8
                elif dist >= maxShadowDist: 10'u8
                else: uint8(40.0 - 30.0 * (dist / maxShadowDist))
    let shadowW = float(ch.width)
    let shadowH = shadowW * 0.3
    let halfW = shadowW * 0.5
    let halfH = shadowH * 0.5
    let cx = ch.x + float(ch.width) * 0.5 - float(camX)
    let sy = shadowY - float(camY)
    renderer.setDrawColor(0, 0, 0, alpha)
    let strips = max(3, int(shadowH))
    for s in 0 ..< strips:
      let t = (float(s) + 0.5) / float(strips)
      let yOff = -halfH + shadowH * t
      let ratio = yOff / halfH
      let xRadius = halfW * sqrt(max(0.0, 1.0 - ratio * ratio))
      drawFilledRect(renderer, cx - xRadius, sy - halfH + shadowH * t, xRadius * 2.0, 1.0)
  renderer.setDrawBlendMode(BlendMode_None)

  # Characters
  for i, ch in game.characters:
    # During death: flash red 3 times then hide; during respawn: fade in
    if ch.isDying():
      if not ch.deathVisible():
        continue
    let isActive = i == game.activeCharacterIndex
    var chColor = CHAR_COLORS[ch.colorIndex mod 6]

    # Isolation desaturation — lonely characters lose colour.
    if ch.isolationSat > 0.001:
      let chromaCol = chroma.color(chColor.r.float32 / 255.0,
                                   chColor.g.float32 / 255.0,
                                   chColor.b.float32 / 255.0)
      let desat = chroma.desaturate(chromaCol, ch.isolationSat * 0.85)
      chColor.r = uint8(min(255.0, desat.r * 255.0))
      chColor.g = uint8(min(255.0, desat.g * 255.0))
      chColor.b = uint8(min(255.0, desat.b * 255.0))

    # Proximity lean offset — shift toward proximityTarget
    var leanOffset = 0.0
    if ch.proximityTarget >= 0 and ch.proximityTarget < game.characters.len:
      let target = game.characters[ch.proximityTarget]
      let targetCx = target.x + float(target.width) * 0.5
      let selfCx = ch.x + float(ch.width) * 0.5
      if targetCx > selfCx:
        leanOffset = ch.proximityLean
      else:
        leanOffset = -ch.proximityLean

      # Color brighten based on proximity distance
      let tdx = targetCx - selfCx
      let tdy = (target.y + float(target.height) * 0.5) - (ch.y + float(ch.height) * 0.5)
      let dist = sqrt(tdx * tdx + tdy * tdy)
      let brightenAmt = 0.05 * (1.0 - min(1.0, dist / 80.0))
      if brightenAmt > 0.001:
        let chromaCol = chroma.color(chColor.r.float32 / 255.0,
                                     chColor.g.float32 / 255.0,
                                     chColor.b.float32 / 255.0)
        let brightened = chroma.lighten(chromaCol, brightenAmt)
        chColor.r = uint8(min(255.0, brightened.r * 255.0))
        chColor.g = uint8(min(255.0, brightened.g * 255.0))
        chColor.b = uint8(min(255.0, brightened.b * 255.0))

    let dx = (ch.drawX() + ch.idleOffsetX + leanOffset).cint - camX
    let dy = (ch.drawY() + ch.idleSway()).cint - camY
    let dw = ch.drawWidth().cint
    let dh = ch.drawHeight().cint

    # Respawn fade-in alpha
    let baseAlpha = ch.respawnAlpha()

    # Colored halo glow behind character (3-pass soft falloff with additive blending)
    # Shift glow color toward warm yellow based on contentment
    if not ch.isDying():
      block:
        let glowScale = ch.glowScale
        let glowAlpha = ch.glowAlpha
        # Loneliness pulse: grows in amplitude the longer a character is isolated.
        let lonelinessAmp = min(0.08, ch.isolationTimer * 0.008)
        let pulse = glowAlpha + 0.05 * sin(game.elapsedTime * PI * 2.0 / 3.0) +
          lonelinessAmp * sin(game.elapsedTime * PI * 2.0 / 1.5)
        let charW = dw.float
        let charH = dh.float
        let charX = dx.float
        let charY = dy.float
        let warmth = ch.contentment * 0.3
        var glowRf = float(chColor.r) * (1.0 - warmth) + 255.0 * warmth
        var glowGf = float(chColor.g) * (1.0 - warmth) + 230.0 * warmth
        var glowBf = max(0.0, float(chColor.b) * (1.0 - warmth) + 80.0 * warmth)
        if ch.glowGoldMix > 0.001:
          let baseCol = chroma.color(glowRf / 255.0, glowGf / 255.0, glowBf / 255.0)
          let goldCol = chroma.color(1.0, 215.0 / 255.0, 0.0)
          let mixed = chroma.mix(baseCol, goldCol, ch.glowGoldMix)
          glowRf = float(mixed.r) * 255.0
          glowGf = float(mixed.g) * 255.0
          glowBf = float(mixed.b) * 255.0
        let glowR = uint8(min(255.0, glowRf))
        let glowG = uint8(min(255.0, glowGf))
        let glowB = uint8(max(0.0, min(255.0, glowBf)))
        renderer.setDrawBlendMode(BlendMode_Add)
        for pass in 0 .. 2:
          let t = float(2 - pass) / 2.0  # 1.0, 0.5, 0.0
          let scale = 1.0 + (glowScale - 1.0) * (0.4 + 0.6 * t)
          let alpha = pulse * (0.3 + 0.35 * t) * float(baseAlpha) / 255.0
          let gw = charW * scale
          let gh = charH * scale
          let gx = charX - (gw - charW) / 2.0
          let gy = charY - (gh - charH) / 2.0
          renderer.setDrawColor(glowR, glowG, glowB, uint8(alpha * 255.0))
          drawFilledRect(renderer, gx, gy, gw, gh)
        renderer.setDrawBlendMode(BlendMode_None)

    # Character body — flash red during death, normal color otherwise
    if ch.isDying():
      renderer.setDrawBlendMode(BlendMode_Blend)
      renderer.setDrawColor(255, 40, 40, 220)
      drawFilledRect(renderer, dx, dy, dw, dh)
      renderer.setDrawBlendMode(BlendMode_None)
    elif ch.isRespawning():
      renderer.setDrawBlendMode(BlendMode_Blend)
      renderer.setDrawColor(chColor.r, chColor.g, chColor.b, baseAlpha)
      drawFilledRect(renderer, dx, dy, dw, dh)
      renderer.setDrawBlendMode(BlendMode_None)
    else:
      renderer.setDrawColor(chColor.r, chColor.g, chColor.b, 255)
      drawFilledRect(renderer, dx, dy, dw, dh)

    # Skip decorations during death/respawn animation
    if ch.isDying() or ch.isRespawning():
      continue

    # Face — eyes and mouth
    block:
      let eyeRadius = max(2, ch.width div 12)
      let eyeSize = (eyeRadius * 2).cint
      let pupilSize = (eyeSize - 2).cint
      let centerX = dx.float + dw.float / 2.0
      let eyeSep = dw.float / 3.0
      let eyeY = (dy.float + dh.float * 0.25).cint
      let leftEyeX = (centerX - eyeSep / 2.0 - eyeRadius.float).cint
      let rightEyeX = (centerX + eyeSep / 2.0 - eyeRadius.float).cint
      let pupilOffset: cint =
        if ch.pupilOffset >= 0.33: 1
        elif ch.pupilOffset <= -0.33: -1
        else: 0

      # Skip eye rendering when blinking
      if not ch.blinking:
        # White sclera
        renderer.setDrawColor(255, 255, 255, 255)
        drawFilledRect(renderer, leftEyeX, eyeY, eyeSize, eyeSize)
        drawFilledRect(renderer, rightEyeX, eyeY, eyeSize, eyeSize)

        # Dark pupils
        renderer.setDrawColor(30, 30, 30, 255)
        drawFilledRect(renderer, leftEyeX + 1 + pupilOffset, eyeY + 1, pupilSize, pupilSize)
        drawFilledRect(renderer, rightEyeX + 1 + pupilOffset, eyeY + 1, pupilSize, pupilSize)

      # Mouth
      let mouthFrac = if ch.celebrating: 0.38 else: 0.25
      let mouthW = (dw.float * mouthFrac).cint
      let mouthX = (centerX - mouthW.float / 2.0).cint
      let mouthY = (dy.float + dh.float * 0.72).cint
      let chromaColor = chroma.color(chColor.r.float32 / 255.0,
                                      chColor.g.float32 / 255.0,
                                      chColor.b.float32 / 255.0)
      let darkened = chroma.darken(chromaColor, 0.3)
      let mouthR = uint8(darkened.r * 255.0)
      let mouthG = uint8(darkened.g * 255.0)
      let mouthB = uint8(darkened.b * 255.0)
      renderer.setDrawColor(mouthR, mouthG, mouthB, 255)
      if ch.celebrating:
        # Curved smile arc — parabolic U-shape.
        let arcHeight = 2.0
        for px in 0 ..< mouthW.int:
          let t = if mouthW > 1: (2.0 * px.float / (mouthW - 1).float) - 1.0 else: 0.0
          let yOff = cint(round(arcHeight * (1.0 - t * t)))
          drawFilledRect(renderer, mouthX + px.cint, mouthY - 1 + yOff, 1, 2)
      else:
        drawFilledRect(renderer, mouthX, mouthY, mouthW, 2)

    # Dim overlay on previously active character during switch
    if i == game.prevActiveCharacterIndex and game.charDimTimer > 0.0:
      let dimAlpha = uint8(min(255.0, game.charDimTimer / 0.3 * 50.0))
      renderer.setDrawBlendMode(BlendMode_Blend)
      renderer.setDrawColor(0, 0, 0, dimAlpha)
      drawFilledRect(renderer, dx, dy, dw, dh)
      renderer.setDrawBlendMode(BlendMode_None)

    # Active character border
    if isActive:
      renderer.setDrawColor(255, 255, 255, 255)
      drawOutlineRect(renderer, dx - 1, dy - 1, dw + 2, dh + 2)

    # Exit glow on character when at exit
    if ch.atExit:
      renderer.setDrawBlendMode(BlendMode_Blend)
      renderer.setDrawColor(255, 255, 200, 60)
      drawFilledRect(renderer, dx - 3, dy - 3, dw + 6, dh + 6)
      renderer.setDrawBlendMode(BlendMode_None)

    # Contentment glow — warm additive overlay when at or near exit
    if ch.contentment > 0.3:
      let alpha = uint8(min(80.0, ch.contentment * 100.0))
      renderer.setDrawBlendMode(BlendMode_Add)
      renderer.setDrawColor(255, 220, 80, alpha)
      drawFilledRect(renderer, dx, dy, dw, dh)
      renderer.setDrawBlendMode(BlendMode_None)

  # Ring particles (character switch flourish)
  if game.particles.ringParticles.len > 0:
    renderer.setDrawBlendMode(BlendMode_Blend)
    for ring in game.particles.ringParticles:
      let progress = 1.0 - ring.life / ring.maxLife
      let scale = 1.0 + progress
      let w = ring.baseW * scale
      let h = ring.baseH * scale
      let rx = (ring.x - w * 0.5).cint - camX
      let ry = (ring.y - h * 0.5).cint - camY
      let rw = w.cint
      let rh = h.cint
      let alpha = uint8(max(0.0, min(255.0, (ring.life / ring.maxLife) * 255.0)))
      renderer.setDrawColor(ring.color.r, ring.color.g, ring.color.b, alpha)
      drawOutlineRect(renderer, rx, ry, rw, rh)
    renderer.setDrawBlendMode(BlendMode_None)

  # Ambient lighting overlay — per-act tint and vignette.
  renderAmbientOverlay(renderer, game.currentLevel)

  # Screen brightening for level 30 finale.
  if game.screenBrightness > 0.001:
    renderer.setDrawBlendMode(BlendMode_Blend)
    renderer.setDrawColor(255, 255, 255, uint8(min(255.0, game.screenBrightness * 255.0)))
    drawFilledRect(renderer, 0, 0, DEFAULT_WIDTH.cint, DEFAULT_HEIGHT.cint)
    renderer.setDrawBlendMode(BlendMode_None)

proc renderPaused(renderer: RendererPtr, game: Game) =
  ## Render gameplay only; the animated dim overlay is handled by the Silky UI layer.
  renderGameplay(renderer, game)

proc renderLevelWin(renderer: RendererPtr, game: Game) =
  renderGameplay(renderer, game)
  renderer.setDrawBlendMode(BlendMode_Blend)
  renderer.setDrawColor(0, 0, 0, 120)
  drawFilledRect(renderer, 0, 0, DEFAULT_WIDTH.cint, DEFAULT_HEIGHT.cint)
  renderer.setDrawBlendMode(BlendMode_None)

  # Star HUD — show earned/missed stars centered at top
  if game.levelWinTimer < 1.0:
    let starSize = 16
    let starGap = 8
    let totalW = 3 * starSize + 2 * starGap
    let startX = (DEFAULT_WIDTH - totalW) div 2
    let starY = 40
    renderer.setDrawBlendMode(BlendMode_Blend)
    for i in 0 ..< 3:
      let sx = startX + i * (starSize + starGap)
      if game.earnedStars[i]:
        # Filled gold star
        renderer.setDrawColor(255, 215, 0, 220)
        drawFilledRect(renderer, sx.cint, starY.cint, starSize.cint, starSize.cint)
        renderer.setDrawColor(255, 245, 157, 120)
        drawFilledRect(renderer, (sx - 2).cint, (starY - 2).cint,
                       (starSize + 4).cint, (starSize + 4).cint)
      else:
        # Gray outline
        renderer.setDrawColor(120, 120, 120, 160)
        drawOutlineRect(renderer, sx.cint, starY.cint, starSize.cint, starSize.cint)
    renderer.setDrawBlendMode(BlendMode_None)

proc renderCredits(renderer: RendererPtr, game: Game) =
  ## Render the full credits sequence after completing level 30.
  const
    # Character parade timing.
    CharDelay = 1.0
    DescendDur = 1.5
    TitleDelay = 0.5
    TitleFadeDur = 0.8
    # Poetry timing.
    PoetryStart = 8.5
    PoetryGap = 2.0
    PoetryFadeDur = 1.2
    # Final screen timing.
    FinalStart = 17.0
    FinalFadeDur = 1.5
    PromptTime = 19.5
    # Layout for character parade.
    CharSize = 28
    CharX = 240
    CharFinalY: array[6, int] = [75, 135, 195, 255, 315, 375]
    TitleX = 280
    TitleH = 14
    # Heart formation positions.
    HeartSize = 28
    HeartPos: array[6, tuple[x, y: int]] = [
      (x: 338, y: 190), (x: 434, y: 190),
      (x: 294, y: 240), (x: 478, y: 240),
      (x: 358, y: 295), (x: 400, y: 345),
    ]
    # Title card name widths (character count * spacing).
    NameLens: array[6, int] = [3, 4, 5, 4, 5, 3]       # Pip, Luca, Bruno, Cara, Felix, Ivy
    SubLens: array[6, int] = [15, 10, 13, 14, 11, 12]   # The Curious One, etc.
    PoetryLens: array[4, int] = [36, 43, 33, 19]
    NameCharW = 10
    SubCharW = 7
    PoetryCharW = 8
    PoetryLineH = 16
    # TOGETHER letter colors (indices into CHAR_COLORS).
    TogetherColorIdx: array[8, int] = [0, 1, 2, 3, 4, 5, 0, 1]

  let t = game.creditsTimer

  # Dark gradient background.
  for i in 0 ..< 14:
    let bandY = i * (DEFAULT_HEIGHT div 14)
    let frac = i.float / 13.0
    let r = uint8(6.0 + 6.0 * frac)
    let g = uint8(6.0 + 8.0 * frac)
    let b = uint8(14.0 + 10.0 * frac)
    renderer.setDrawColor(r, g, b, 255)
    drawFilledRect(renderer, 0, bandY.cint, DEFAULT_WIDTH.cint,
                   (DEFAULT_HEIGHT div 14 + 1).cint)

  renderer.setDrawBlendMode(BlendMode_Blend)

  # Phase 1: Character parade with title cards (0 - ~8.5s).
  if t < 9.0:
    let phase1Fade = if t > 7.5: max(0.0, 1.0 - (t - 7.5) / 1.5) else: 1.0
    for i in 0 ..< 6:
      let charStart = float(i) * CharDelay
      if t < charStart:
        continue
      let charColor = CHAR_COLORS[i]
      # Descent: ease from y=-50 to final y.
      let descProgress = min(1.0, (t - charStart) / DescendDur)
      let eased = 1.0 - pow(1.0 - descProgress, 3.0)
      let currentY = -50.0 + (float(CharFinalY[i]) + 50.0) * eased
      let a = uint8(phase1Fade * 255.0)
      # Character square.
      renderer.setDrawColor(charColor.r, charColor.g, charColor.b, a)
      drawFilledRect(renderer, CharX.float, currentY, CharSize.float, CharSize.float)
      # Title card: appears after character settles.
      let titleStart = charStart + DescendDur + TitleDelay
      if t >= titleStart:
        let titleFade = min(1.0, (t - titleStart) / TitleFadeDur) * phase1Fade
        let titleY = currentY + float((CharSize - TitleH) div 2)
        # Name bar.
        let nameW = NameLens[i] * NameCharW
        renderer.setDrawColor(charColor.r, charColor.g, charColor.b,
                              uint8(titleFade * 255.0))
        drawFilledRect(renderer, TitleX.float, titleY, nameW.float, TitleH.float)
        # Dash separator.
        let dashX = TitleX + nameW + 8
        renderer.setDrawColor(charColor.r, charColor.g, charColor.b,
                              uint8(titleFade * 120.0))
        drawFilledRect(renderer, dashX.float, titleY + float(TitleH div 2) - 1.0,
                       12.0, 2.0)
        # Subtitle bar.
        let subX = dashX + 20
        let subW = SubLens[i] * SubCharW
        renderer.setDrawColor(charColor.r, charColor.g, charColor.b,
                              uint8(titleFade * 130.0))
        drawFilledRect(renderer, subX.float, titleY, subW.float, TitleH.float)

  # Phase 2: Poetry lines (8 - 17s).
  if t >= 7.5 and t < 17.5:
    let phase2Fade = if t < 8.5: (t - 7.5) / 1.0
                     elif t > 16.0: max(0.0, 1.0 - (t - 16.0) / 1.5)
                     else: 1.0
    for i in 0 ..< 4:
      let lineStart = PoetryStart + float(i) * PoetryGap
      if t < lineStart:
        continue
      let lineFade = min(1.0, (t - lineStart) / PoetryFadeDur) * phase2Fade
      let lineW = PoetryLens[i] * PoetryCharW
      let lineX = (DEFAULT_WIDTH - lineW) div 2
      let lineY = 160 + i * 60
      renderer.setDrawColor(210, 210, 230, uint8(lineFade * 255.0))
      drawFilledRect(renderer, lineX.cint, lineY.cint, lineW.cint,
                     PoetryLineH.cint)

  # Phase 3: TOGETHER with heart formation (16s+).
  if t >= 16.0:
    let phase3Fade = min(1.0, (t - 16.0) / FinalFadeDur)
    let a = uint8(phase3Fade * 255.0)
    # "TOGETHER" — each letter block in a character color.
    let letterW = 20
    let letterH = 32
    let letterGap = 4
    let totalW = 8 * letterW + 7 * letterGap
    let startX = (DEFAULT_WIDTH - totalW) div 2
    let letterY = 80
    for i in 0 ..< 8:
      let lx = startX + i * (letterW + letterGap)
      let color = CHAR_COLORS[TogetherColorIdx[i]]
      renderer.setDrawColor(color.r, color.g, color.b, a)
      drawFilledRect(renderer, lx.cint, letterY.cint, letterW.cint, letterH.cint)
    # Decorative lines above and below.
    let decoW = totalW + 60
    let decoX = (DEFAULT_WIDTH - decoW) div 2
    renderer.setDrawColor(255, 255, 255, a div 3)
    drawFilledRect(renderer, decoX.cint, (letterY - 12).cint, decoW.cint, 1)
    drawFilledRect(renderer, decoX.cint, (letterY + letterH + 11).cint,
                   decoW.cint, 1)
    # Heart formation of character squares.
    for i in 0 ..< 6:
      let charColor = CHAR_COLORS[i]
      let hx = HeartPos[i].x
      let hy = HeartPos[i].y
      # Soft glow behind.
      renderer.setDrawColor(charColor.r, charColor.g, charColor.b, a div 4)
      drawFilledRect(renderer, (hx - 4).cint, (hy - 4).cint,
                     (HeartSize + 8).cint, (HeartSize + 8).cint)
      # Character square.
      renderer.setDrawColor(charColor.r, charColor.g, charColor.b, a)
      drawFilledRect(renderer, hx.cint, hy.cint, HeartSize.cint, HeartSize.cint)
    # "Press Enter to return to menu" prompt.
    if t >= PromptTime:
      let promptFade = min(1.0, (t - PromptTime) / 1.0)
      let pulse = 0.6 + 0.4 * sin(t * PI)
      let promptAlpha = uint8(promptFade * pulse * 180.0)
      let promptW = 200
      let promptH = 10
      let promptX = (DEFAULT_WIDTH - promptW) div 2
      let promptY = 430
      renderer.setDrawColor(180, 180, 200, promptAlpha)
      drawFilledRect(renderer, promptX.cint, promptY.cint, promptW.cint,
                     promptH.cint)

  # Fade from white at start (transition from level 30 finale brightness).
  if t < 1.5:
    let fadeAlpha = uint8(max(0.0, (1.0 - t / 1.5)) * 255.0)
    renderer.setDrawColor(255, 255, 255, fadeAlpha)
    drawFilledRect(renderer, 0, 0, DEFAULT_WIDTH.cint, DEFAULT_HEIGHT.cint)

  renderer.setDrawBlendMode(BlendMode_None)

proc renderActTitle(renderer: RendererPtr, game: Game) =
  ## Render a cinematic act title card with fade in/out.
  let actIdx = actForLevel(game.actTitleTarget)
  if actIdx < 0:
    return

  let act = Acts[actIdx]
  let alpha = game.actTitleAlpha()
  let a = uint8(max(0.0, min(255.0, alpha * 255.0)))

  # Black background (full screen).
  renderer.setDrawColor(0, 0, 0, 255)
  drawFilledRect(renderer, 0, 0, DEFAULT_WIDTH.cint, DEFAULT_HEIGHT.cint)

  renderer.setDrawBlendMode(BlendMode_Blend)

  # "Act N" small text indicator — rendered as a colored bar near the top.
  let labelW = 80 + act.number * 10
  let labelX = (DEFAULT_WIDTH - labelW) div 2
  let labelY = 160
  renderer.setDrawColor(act.themeColor.r, act.themeColor.g, act.themeColor.b, a div 2)
  drawFilledRect(renderer, labelX.cint, labelY.cint, labelW.cint, 12)

  # Act name — large centered block.
  let nameW = act.name.len * 18
  let nameH = 28
  let nameX = (DEFAULT_WIDTH - nameW) div 2
  let nameY = (DEFAULT_HEIGHT - nameH) div 2
  renderer.setDrawColor(act.themeColor.r, act.themeColor.g, act.themeColor.b, a)
  drawFilledRect(renderer, nameX.cint, nameY.cint, nameW.cint, nameH.cint)

  # Subtle decorative lines above and below name.
  let lineW = nameW + 40
  let lineX = (DEFAULT_WIDTH - lineW) div 2
  renderer.setDrawColor(act.themeColor.r, act.themeColor.g, act.themeColor.b, a div 3)
  drawFilledRect(renderer, lineX.cint, (nameY - 8).cint, lineW.cint, 1)
  drawFilledRect(renderer, lineX.cint, (nameY + nameH + 7).cint, lineW.cint, 1)

  renderer.setDrawBlendMode(BlendMode_None)

proc renderGame*(renderer: RendererPtr, game: Game) =
  renderer.setDrawColor(BG_COLOR.r, BG_COLOR.g, BG_COLOR.b, 255)
  renderer.clear()

  case game.state
  of menu:
    renderMenu(renderer, game)
  of playing:
    renderGameplay(renderer, game)
  of paused:
    renderPaused(renderer, game)
  of levelWin:
    renderLevelWin(renderer, game)
  of credits:
    renderCredits(renderer, game)
  of actTitle:
    renderActTitle(renderer, game)
  of settings:
    if game.previousState == paused:
      renderPaused(renderer, game)
    else:
      renderMenu(renderer, game)

  # Screen flash overlay — fades out over time.
  if game.screenEffects.flashActive():
    let fc = game.screenEffects.flashColor
    let alpha = uint8(game.screenEffects.flashAlpha() * 255.0)
    renderer.setDrawBlendMode(BlendMode_Blend)
    renderer.setDrawColor(fc.r, fc.g, fc.b, alpha)
    drawFilledRect(renderer, 0, 0, DEFAULT_WIDTH.cint, DEFAULT_HEIGHT.cint)
    renderer.setDrawBlendMode(BlendMode_None)

  if transitionAlpha > 0.001:
    renderer.setDrawBlendMode(BlendMode_Blend)
    renderer.setDrawColor(transitionColor.r, transitionColor.g,
                          transitionColor.b, uint8(transitionAlpha * 255.0))
    drawFilledRect(renderer, 0, 0, DEFAULT_WIDTH.cint, DEFAULT_HEIGHT.cint)
    renderer.setDrawBlendMode(BlendMode_None)
