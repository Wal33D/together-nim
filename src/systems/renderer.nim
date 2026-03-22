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
import math

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

proc renderMenu(renderer: RendererPtr, game: Game) =
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

proc renderGameplay(renderer: RendererPtr, game: Game) =
  if game.currentLevel < 0 or game.currentLevel >= allLevels.len:
    return

  let level = game.currentLevelState

  # Scenic backdrop — rendered BEFORE platforms and characters.
  renderBackdrop(renderer, level, game.camera.x, game.elapsedTime)
  renderAtmosphereOverlay(renderer, game.atmosphere)

  # Camera offset — subtract from all world-space coordinates
  let camX = game.camera.x.cint
  let camY = game.camera.y.cint

  # Platforms
  renderer.setDrawColor(90, 90, 110, 255)
  for p in level.platforms:
    drawFilledRect(renderer, p.x.cint - camX, p.y.cint - camY, p.width.cint, p.height.cint)
    # Top edge highlight
    renderer.setDrawColor(120, 120, 145, 255)
    drawFilledRect(renderer, p.x.cint - camX, p.y.cint - camY, p.width.cint, 2)
    renderer.setDrawColor(90, 90, 110, 255)

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
    # Glow behind
    renderer.setDrawColor(exitColor.r, exitColor.g, exitColor.b, 40)
    drawFilledRect(renderer, (e.x - 4).cint - camX, (e.y - 4).cint - camY,
                   (e.width + 8).cint, (e.height + 8).cint)
    # Outline
    renderer.setDrawColor(exitColor.r, exitColor.g, exitColor.b, 200)
    drawOutlineRect(renderer, e.x.cint - camX, e.y.cint - camY, e.width.cint, e.height.cint)
  renderer.setDrawBlendMode(BlendMode_None)

  renderParticleSystem(renderer, game.particles, camX, camY)

  # Characters
  for i, ch in game.characters:
    # Hide sprite during dissolve and respawn phases
    if ch.dissolving or ch.respawning:
      continue
    let isActive = i == game.activeCharacterIndex
    let chColor = CHAR_COLORS[ch.colorIndex mod 6]

    let dx = ch.drawX().cint - camX
    let dy = (ch.drawY() + ch.idleSway()).cint - camY
    let dw = ch.drawWidth().cint
    let dh = ch.drawHeight().cint

    # Colored halo glow behind character (3-pass soft falloff with additive blending)
    block:
      let glowScale = if isActive: 2.7 else: 1.8
      let glowAlpha = if isActive: 0.25 else: 0.15
      let pulse = glowAlpha + 0.05 * sin(game.elapsedTime * PI * 2.0 / 3.0)
      let charW = dw.float
      let charH = dh.float
      let charX = dx.float
      let charY = dy.float
      renderer.setDrawBlendMode(BlendMode_Add)
      for pass in 0 .. 2:
        let t = float(2 - pass) / 2.0  # 1.0, 0.5, 0.0
        let scale = 1.0 + (glowScale - 1.0) * (0.4 + 0.6 * t)
        let alpha = pulse * (0.3 + 0.35 * t)
        let gw = charW * scale
        let gh = charH * scale
        let gx = charX - (gw - charW) / 2.0
        let gy = charY - (gh - charH) / 2.0
        renderer.setDrawColor(chColor.r, chColor.g, chColor.b, uint8(alpha * 255.0))
        drawFilledRect(renderer, gx, gy, gw, gh)
      renderer.setDrawBlendMode(BlendMode_None)

    # Character body
    renderer.setDrawColor(chColor.r, chColor.g, chColor.b, 255)
    drawFilledRect(renderer, dx, dy, dw, dh)

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

proc renderPaused(renderer: RendererPtr, game: Game) =
  ## Render gameplay only; the animated dim overlay is handled by the Silky UI layer.
  renderGameplay(renderer, game)

proc renderLevelWin(renderer: RendererPtr, game: Game) =
  renderGameplay(renderer, game)
  renderer.setDrawBlendMode(BlendMode_Blend)
  renderer.setDrawColor(0, 0, 0, 120)
  drawFilledRect(renderer, 0, 0, DEFAULT_WIDTH.cint, DEFAULT_HEIGHT.cint)
  renderer.setDrawBlendMode(BlendMode_None)

proc renderCredits(renderer: RendererPtr, game: Game) =
  renderMenu(renderer, game)

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

  if transitionAlpha > 0.001:
    renderer.setDrawBlendMode(BlendMode_Blend)
    renderer.setDrawColor(transitionColor.r, transitionColor.g,
                          transitionColor.b, uint8(transitionAlpha * 255.0))
    drawFilledRect(renderer, 0, 0, DEFAULT_WIDTH.cint, DEFAULT_HEIGHT.cint)
    renderer.setDrawBlendMode(BlendMode_None)
