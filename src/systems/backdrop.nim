## Code-rendered ambient backdrops for Together.
## The goal is mood and depth, not literal scenery props.

import math
import chroma
import "../constants"
import "../entities/level"
import "render_backend"

type
  BackdropScene* = enum
    dawnMeadow, riverValley, stoneRuins, nightSky, aetherPlane

  BackdropTheme* = object
    scene*: BackdropScene
    skyTop*: constants.Color
    skyBottom*: constants.Color
    haze*: constants.Color
    horizon*: constants.Color
    silhouette*: constants.Color
    glow*: constants.Color

proc clamp01(value: float): float =
  max(0.0, min(1.0, value))

proc mixColor(a, b: constants.Color, t: float): constants.Color =
  let clamped = clamp01(t)
  result.r = uint8(float(a.r) + (float(b.r) - float(a.r)) * clamped)
  result.g = uint8(float(a.g) + (float(b.g) - float(a.g)) * clamped)
  result.b = uint8(float(a.b) + (float(b.b) - float(a.b)) * clamped)

const
  ActColors: array[5, constants.Color] = [
    (r: 220'u8, g: 160'u8, b: 60'u8),   # Act 1: warm amber
    (r: 80'u8, g: 160'u8, b: 200'u8),    # Act 2: soft cyan
    (r: 140'u8, g: 100'u8, b: 180'u8),   # Act 3: muted purple
    (r: 60'u8, g: 60'u8, b: 160'u8),     # Act 4: deep indigo
    (r: 220'u8, g: 220'u8, b: 240'u8),   # Act 5: near-white
  ]
  CrossfadeDuration = 0.5
  MidGroundScrollSpeed = 0.4
  MidGroundShapeMin = 6
  MidGroundShapeMax = 10
  NearGroundScrollSpeed = 0.8
  NearGroundClusterMin = 12
  NearGroundClusterMax = 16

proc toChroma(c: constants.Color): chroma.Color =
  chroma.color(c.r.float32 / 255.0, c.g.float32 / 255.0, c.b.float32 / 255.0)

proc actForLevel(levelId: int): int =
  ## Return act number (1-5) based on level ID.
  min(5, (levelId - 1) div 6 + 1)

proc seededVal(seed, index, lo, hi: int): int =
  ## Deterministic pseudo-random value from seed and index.
  let hash = ((seed * 7919 + index * 6271) and 0x7FFFFFFF) mod 65521
  lo + hash mod (hi - lo + 1)

type
  PaletteState = object
    currentAct: int
    paletteBlend: float
    prevActColor: chroma.Color
    nextActColor: chroma.Color
    transitionStart: float

var palette: PaletteState

proc actColorForLevel(levelId: int, time: float): chroma.Color =
  ## Return the act palette color, crossfading over CrossfadeDuration at act boundaries.
  let act = actForLevel(levelId)
  if palette.currentAct == 0:
    palette.currentAct = act
    palette.nextActColor = ActColors[act - 1].toChroma
    palette.prevActColor = palette.nextActColor
    palette.paletteBlend = 1.0
  elif act != palette.currentAct:
    palette.prevActColor = palette.nextActColor
    palette.nextActColor = ActColors[act - 1].toChroma
    palette.transitionStart = time
    palette.paletteBlend = 0.0
    palette.currentAct = act

  if palette.paletteBlend < 1.0:
    let elapsed = time - palette.transitionStart
    palette.paletteBlend = clamp01(elapsed / CrossfadeDuration)
    result = chroma.mix(palette.prevActColor, palette.nextActColor, palette.paletteBlend)
  else:
    result = palette.nextActColor

proc themeForScene(scene: BackdropScene): BackdropTheme =
  case scene
  of dawnMeadow:
    BackdropTheme(
      scene: scene,
      skyTop: (r: 28'u8, g: 36'u8, b: 64'u8),
      skyBottom: (r: 128'u8, g: 142'u8, b: 156'u8),
      haze: (r: 255'u8, g: 211'u8, b: 156'u8),
      horizon: (r: 86'u8, g: 110'u8, b: 92'u8),
      silhouette: (r: 48'u8, g: 66'u8, b: 56'u8),
      glow: (r: 255'u8, g: 232'u8, b: 184'u8),
    )
  of riverValley:
    BackdropTheme(
      scene: scene,
      skyTop: (r: 18'u8, g: 34'u8, b: 68'u8),
      skyBottom: (r: 92'u8, g: 118'u8, b: 152'u8),
      haze: (r: 176'u8, g: 214'u8, b: 236'u8),
      horizon: (r: 52'u8, g: 78'u8, b: 102'u8),
      silhouette: (r: 26'u8, g: 48'u8, b: 72'u8),
      glow: (r: 196'u8, g: 236'u8, b: 255'u8),
    )
  of stoneRuins:
    BackdropTheme(
      scene: scene,
      skyTop: (r: 30'u8, g: 30'u8, b: 54'u8),
      skyBottom: (r: 112'u8, g: 94'u8, b: 118'u8),
      haze: (r: 214'u8, g: 182'u8, b: 210'u8),
      horizon: (r: 78'u8, g: 74'u8, b: 90'u8),
      silhouette: (r: 42'u8, g: 40'u8, b: 54'u8),
      glow: (r: 228'u8, g: 210'u8, b: 240'u8),
    )
  of nightSky:
    BackdropTheme(
      scene: scene,
      skyTop: (r: 8'u8, g: 12'u8, b: 28'u8),
      skyBottom: (r: 24'u8, g: 28'u8, b: 54'u8),
      haze: (r: 86'u8, g: 126'u8, b: 168'u8),
      horizon: (r: 26'u8, g: 34'u8, b: 62'u8),
      silhouette: (r: 14'u8, g: 18'u8, b: 34'u8),
      glow: (r: 148'u8, g: 206'u8, b: 255'u8),
    )
  of aetherPlane:
    BackdropTheme(
      scene: scene,
      skyTop: (r: 230'u8, g: 235'u8, b: 255'u8),
      skyBottom: (r: 210'u8, g: 218'u8, b: 248'u8),
      haze: (r: 248'u8, g: 248'u8, b: 255'u8),
      horizon: (r: 180'u8, g: 190'u8, b: 220'u8),
      silhouette: (r: 160'u8, g: 168'u8, b: 210'u8),
      glow: (r: 255'u8, g: 255'u8, b: 255'u8),
    )

proc levelBackdropScene*(levelId: int): BackdropScene =
  case actForLevel(levelId)
  of 1: dawnMeadow
  of 2: riverValley
  of 3: stoneRuins
  of 4: nightSky
  else: aetherPlane   # Act 5 — Transcendence

proc backdropThemeForLevel*(levelId: int): BackdropTheme =
  themeForScene(levelBackdropScene(levelId))

proc renderSkyGradient(renderer: RendererPtr, theme: BackdropTheme) =
  let bands = 18
  let bandH = max(1, DEFAULT_HEIGHT div bands)
  for i in 0..<bands:
    let t = float(i) / float(max(1, bands - 1))
    let color = mixColor(theme.skyTop, theme.skyBottom, t)
    renderer.setDrawColor(color.r, color.g, color.b, 255)
    drawFilledRect(renderer, 0, cint(i * bandH), DEFAULT_WIDTH.cint, cint(bandH + 1))

proc renderGlow(renderer: RendererPtr, x, y, w, h: int, color: constants.Color, alpha: uint8) =
  renderer.setDrawBlendMode(BlendMode_Blend)
  for layer in 0..4:
    let inset = layer * 12
    let layerAlpha = max(0, int(alpha) - layer * 18).uint8
    renderer.setDrawColor(color.r, color.g, color.b, layerAlpha)
    drawFilledRect(
      renderer,
      cint(x - w div 2 + inset),
      cint(y - h div 2 + inset),
      cint(max(1, w - inset * 2)),
      cint(max(1, h - inset * 2))
    )
  renderer.setDrawBlendMode(BlendMode_None)

proc renderCelestialBody(renderer: RendererPtr, theme: BackdropTheme, scene: BackdropScene, time: float) =
  case scene
  of dawnMeadow:
    renderGlow(renderer, 150, 116, 180, 180, theme.glow, 62)
  of riverValley:
    renderGlow(renderer, 610, 104, 150, 150, theme.glow, 40)
  of stoneRuins:
    renderGlow(renderer, 212, 132, 150, 150, theme.glow, 34)
  of nightSky:
    let driftY = int(6.0 * sin(time * 0.18))
    renderGlow(renderer, 628, 98 + driftY, 120, 120, theme.glow, 54)
  of aetherPlane:
    renderGlow(renderer, DEFAULT_WIDTH div 2, 80, 260, 260, theme.glow, 48)

proc renderStars(renderer: RendererPtr, theme: BackdropTheme, levelId: int, time: float) =
  if theme.scene == nightSky:
    renderer.setDrawBlendMode(BlendMode_Blend)
    for i in 0..<36:
      let x = (i * 97 + levelId * 23) mod DEFAULT_WIDTH
      let y = (i * 53 + levelId * 41) mod (DEFAULT_HEIGHT div 2)
      let twinkle = 26 + int(24.0 * (0.5 + 0.5 * sin(time * 1.8 + float(i) * 0.37)))
      renderer.setDrawColor(theme.glow.r, theme.glow.g, theme.glow.b, uint8(twinkle))
      drawFilledRect(renderer, cint(x), cint(y), 2, 2)
    renderer.setDrawBlendMode(BlendMode_None)
  elif theme.scene == aetherPlane:
    renderer.setDrawBlendMode(BlendMode_Blend)
    for i in 0..<20:
      let x = (i * 113 + levelId * 31) mod DEFAULT_WIDTH
      let y = (i * 67 + levelId * 47) mod DEFAULT_HEIGHT
      renderer.setDrawColor(230, 235, 255, 40)
      drawFilledRect(renderer, cint(x), cint(y), 2, 2)
    renderer.setDrawBlendMode(BlendMode_None)

proc renderAurora(renderer: RendererPtr, theme: BackdropTheme, time: float) =
  if theme.scene == nightSky:
    renderer.setDrawBlendMode(BlendMode_Blend)
    for i in 0..<5:
      let x = 80 + i * 132 + int(10.0 * sin(time * 0.4 + float(i)))
      let width = 56 + (i mod 2) * 18
      let height = 180 + (i mod 3) * 26
      let alpha = uint8(16 + i * 5)
      renderer.setDrawColor(theme.haze.r, theme.haze.g, theme.haze.b, alpha)
      drawFilledRect(renderer, cint(x), 12, cint(width), cint(height))
    renderer.setDrawBlendMode(BlendMode_None)
  elif theme.scene == aetherPlane:
    renderer.setDrawBlendMode(BlendMode_Blend)
    for i in 0..<6:
      let x = 60 + i * (DEFAULT_WIDTH div 6)
      let width = 80 + (i mod 2) * 20
      renderer.setDrawColor(theme.haze.r, theme.haze.g, theme.haze.b, 12)
      drawFilledRect(renderer, cint(x), 0, cint(width), DEFAULT_HEIGHT.cint)
    renderer.setDrawBlendMode(BlendMode_None)

proc renderHorizonBands(renderer: RendererPtr, theme: BackdropTheme, camX: float) =
  let bandBaseY = DEFAULT_HEIGHT - 158
  let parallax = case theme.scene
    of dawnMeadow: 0.08
    of riverValley: 0.12
    of stoneRuins: 0.10
    of nightSky: 0.05
    of aetherPlane: 0.06

  let offset = int(camX * parallax)
  for layer in 0..2:
    let bandColor = mixColor(theme.horizon, theme.silhouette, float(layer) * 0.28)
    let alpha = uint8(210 - layer * 28)
    renderer.setDrawBlendMode(BlendMode_Blend)
    renderer.setDrawColor(bandColor.r, bandColor.g, bandColor.b, alpha)
    let y = bandBaseY + layer * 30
    let height = 48 + layer * 14
    let segmentW = 260 + layer * 40
    let shift = (offset + layer * 44) mod segmentW
    for segment in -1..4:
      let x = segment * segmentW - shift
      drawFilledRect(renderer, cint(x), cint(y), cint(segmentW + 28), cint(height))
  renderer.setDrawBlendMode(BlendMode_None)

proc renderMist(renderer: RendererPtr, theme: BackdropTheme, scene: BackdropScene, time: float) =
  renderer.setDrawBlendMode(BlendMode_Blend)
  for layer in 0..3:
    let width = 240 + layer * 80
    let speed = 7.0 + float(layer) * 2.8
    let baseX = int((time * speed).floor) mod (DEFAULT_WIDTH + width) - width div 2
    let y = DEFAULT_HEIGHT - 176 + layer * 22
    let alpha = case scene
      of dawnMeadow: uint8(20 + layer * 5)
      of riverValley: uint8(28 + layer * 6)
      of stoneRuins: uint8(16 + layer * 5)
      of nightSky: uint8(10 + layer * 4)
      of aetherPlane: uint8(30 + layer * 6)
    renderer.setDrawColor(theme.haze.r, theme.haze.g, theme.haze.b, alpha)
    drawFilledRect(renderer, cint(baseX), cint(y), cint(width), 18)
    drawFilledRect(renderer, cint(baseX - 180), cint(y + 8), cint(width - 40), 14)
  renderer.setDrawBlendMode(BlendMode_None)

proc renderWaterShimmer(renderer: RendererPtr, theme: BackdropTheme, time: float) =
  if theme.scene != riverValley:
    return

  renderer.setDrawBlendMode(BlendMode_Blend)
  for i in 0..<8:
    let y = DEFAULT_HEIGHT - 96 + i * 6
    let width = 200 + i * 60
    let x = DEFAULT_WIDTH div 2 - width div 2 + int(14.0 * sin(time * 0.6 + float(i)))
    let alpha = uint8(14 + (7 - i) * 3)
    renderer.setDrawColor(theme.glow.r, theme.glow.g, theme.glow.b, alpha)
    drawFilledRect(renderer, cint(x), cint(y), cint(width), 2)
  renderer.setDrawBlendMode(BlendMode_None)

proc renderAmbientStrata(renderer: RendererPtr, theme: BackdropTheme, scene: BackdropScene) =
  renderer.setDrawBlendMode(BlendMode_Blend)
  case scene
  of dawnMeadow:
    renderer.setDrawColor(theme.haze.r, theme.haze.g, theme.haze.b, 24)
    drawFilledRect(renderer, 0, 92, DEFAULT_WIDTH.cint, 96)
  of riverValley:
    renderer.setDrawColor(theme.haze.r, theme.haze.g, theme.haze.b, 20)
    drawFilledRect(renderer, 0, 118, DEFAULT_WIDTH.cint, 84)
  of stoneRuins:
    renderer.setDrawColor(theme.haze.r, theme.haze.g, theme.haze.b, 18)
    drawFilledRect(renderer, 0, 136, DEFAULT_WIDTH.cint, 74)
  of nightSky:
    renderer.setDrawColor(theme.haze.r, theme.haze.g, theme.haze.b, 14)
    drawFilledRect(renderer, 0, 74, DEFAULT_WIDTH.cint, 110)
  of aetherPlane:
    renderer.setDrawColor(theme.haze.r, theme.haze.g, theme.haze.b, 16)
    drawFilledRect(renderer, 0, 100, DEFAULT_WIDTH.cint, 90)
    drawFilledRect(renderer, 0, 160, DEFAULT_WIDTH.cint, 90)
  renderer.setDrawBlendMode(BlendMode_None)

proc renderMidGroundSilhouettes(renderer: RendererPtr, actColor: chroma.Color, act: int, camX: float, scene: BackdropScene) =
  ## Procedurally generated column shapes scrolling at 0.4x camera speed.
  let darkColor = chroma.darken(actColor, 0.4)
  let cr = uint8(darkColor.r * 255.0)
  let cg = uint8(darkColor.g * 255.0)
  let cb = uint8(darkColor.b * 255.0)
  let count = seededVal(act, 999, MidGroundShapeMin, MidGroundShapeMax)
  let scrollShift = int(camX * MidGroundScrollSpeed) mod DEFAULT_WIDTH

  renderer.setDrawBlendMode(BlendMode_Blend)
  renderer.setDrawColor(cr, cg, cb, 200)

  for i in 0..<count:
    let baseX = seededVal(act, i * 3, 0, DEFAULT_WIDTH - 1)
    let h = seededVal(act, i * 3 + 1, 60, 180)
    let w = seededVal(act, i * 3 + 2, 20, 50)
    let x = ((baseX - scrollShift) mod DEFAULT_WIDTH + DEFAULT_WIDTH) mod DEFAULT_WIDTH
    let y = DEFAULT_HEIGHT - h

    case scene
    of dawnMeadow:
      # Tapered tree silhouettes: wide base + narrower top (2:1 width ratio).
      let topW = w div 2
      let topH = h div 3
      let baseH = h - topH
      let topX = x + (w - topW) div 2
      drawFilledRect(renderer, cint(x), cint(y + topH), cint(w), cint(baseH))
      drawFilledRect(renderer, cint(x - DEFAULT_WIDTH), cint(y + topH), cint(w), cint(baseH))
      drawFilledRect(renderer, cint(topX), cint(y), cint(topW), cint(topH))
      drawFilledRect(renderer, cint(topX - DEFAULT_WIDTH), cint(y), cint(topW), cint(topH))
    of riverValley:
      # Rounded bush mounds: 2-3 stacked rects of decreasing width, centered.
      let layers = seededVal(act, i * 3 + 50, 2, 3)
      let layerH = h div layers
      for layer in 0..<layers:
        let shrink = layer * w div (layers * 2)
        let lw = max(4, w - shrink * 2)
        let lx = x + shrink
        let ly = y + layer * layerH
        drawFilledRect(renderer, cint(lx), cint(ly), cint(lw), cint(layerH + 1))
        drawFilledRect(renderer, cint(lx - DEFAULT_WIDTH), cint(ly), cint(lw), cint(layerH + 1))
    of stoneRuins:
      # Broken columns: pillar with a 30-50% narrower cap offset left or right.
      let capNarrow = seededVal(act, i * 3 + 60, 30, 50)
      let capW = max(4, w * (100 - capNarrow) div 100)
      let capH = h div 4
      let pillarH = h - capH
      let offsetDir = if (i mod 2) == 0: -capW div 4 else: capW div 4
      let capX = x + (w - capW) div 2 + offsetDir
      drawFilledRect(renderer, cint(x), cint(y + capH), cint(w), cint(pillarH))
      drawFilledRect(renderer, cint(x - DEFAULT_WIDTH), cint(y + capH), cint(w), cint(pillarH))
      drawFilledRect(renderer, cint(capX), cint(y), cint(capW), cint(capH))
      drawFilledRect(renderer, cint(capX - DEFAULT_WIDTH), cint(y), cint(capW), cint(capH))
    of nightSky:
      # Crystal spires: tall narrow base with a short pointed tip (4px wide).
      let tipH = min(20, h div 4)
      let baseH = h - tipH
      let tipX = x + (w - 4) div 2
      drawFilledRect(renderer, cint(x), cint(y + tipH), cint(w), cint(baseH))
      drawFilledRect(renderer, cint(x - DEFAULT_WIDTH), cint(y + tipH), cint(w), cint(baseH))
      drawFilledRect(renderer, cint(tipX), cint(y), 4, cint(tipH))
      drawFilledRect(renderer, cint(tipX - DEFAULT_WIDTH), cint(y), 4, cint(tipH))
    of aetherPlane:
      # Floating disconnected blocks: 2 rects separated by a seeded gap.
      let gap = seededVal(act, i * 3 + 70, 10, 20)
      let topH = h div 3
      let botH = h - topH - gap
      drawFilledRect(renderer, cint(x), cint(y), cint(w), cint(topH))
      drawFilledRect(renderer, cint(x - DEFAULT_WIDTH), cint(y), cint(w), cint(topH))
      drawFilledRect(renderer, cint(x), cint(y + topH + gap), cint(w), cint(botH))
      drawFilledRect(renderer, cint(x - DEFAULT_WIDTH), cint(y + topH + gap), cint(w), cint(botH))

  renderer.setDrawBlendMode(BlendMode_None)

proc renderNearGroundDetail(renderer: RendererPtr, actColor: chroma.Color, act: int, camX: float) =
  ## Small rect clusters at ground level scrolling at 0.8x camera speed.
  let lightColor = chroma.lighten(actColor, 0.1)
  let cr = uint8(lightColor.r * 255.0)
  let cg = uint8(lightColor.g * 255.0)
  let cb = uint8(lightColor.b * 255.0)
  let count = seededVal(act, 888, NearGroundClusterMin, NearGroundClusterMax)
  let scrollShift = int(camX * NearGroundScrollSpeed) mod DEFAULT_WIDTH
  let groundZone = DEFAULT_HEIGHT * 15 div 100
  let groundTop = DEFAULT_HEIGHT - groundZone

  renderer.setDrawBlendMode(BlendMode_Blend)
  renderer.setDrawColor(cr, cg, cb, 180)

  for i in 0..<count:
    let baseX = seededVal(act, i * 5 + 100, 0, DEFAULT_WIDTH - 1)
    let h = seededVal(act, i * 5 + 101, 4, 12)
    let w = seededVal(act, i * 5 + 102, 6, 20)
    let yOff = seededVal(act, i * 5 + 103, 0, max(1, groundZone - h))
    let x = ((baseX - scrollShift) mod DEFAULT_WIDTH + DEFAULT_WIDTH) mod DEFAULT_WIDTH
    let y = groundTop + yOff
    drawFilledRect(renderer, cint(x), cint(y), cint(w), cint(h))
    drawFilledRect(renderer, cint(x - DEFAULT_WIDTH), cint(y), cint(w), cint(h))

  renderer.setDrawBlendMode(BlendMode_None)

proc renderForegroundStrip(renderer: RendererPtr, actColor: chroma.Color, act: int, camX: float) =
  ## Dense fast-scrolling rect strip at the very bottom of the viewport (1.2x).
  let lightColor = chroma.lighten(actColor, 0.15)
  let cr = uint8(lightColor.r * 255.0)
  let cg = uint8(lightColor.g * 255.0)
  let cb = uint8(lightColor.b * 255.0)
  let count = seededVal(act, 777, 24, 36)
  let scrollShift = int(camX * 1.2) mod DEFAULT_WIDTH
  let stripTop = DEFAULT_HEIGHT - 20

  renderer.setDrawBlendMode(BlendMode_Blend)
  renderer.setDrawColor(cr, cg, cb, 160)

  for i in 0..<count:
    let baseX = seededVal(act, i * 7 + 200, 0, DEFAULT_WIDTH - 1)
    let h = seededVal(act, i * 7 + 201, 4, 16)
    let w = seededVal(act, i * 7 + 202, 8, 28)
    let yOff = seededVal(act, i * 7 + 203, 0, max(1, 20 - h))
    let x = ((baseX - scrollShift) mod DEFAULT_WIDTH + DEFAULT_WIDTH) mod DEFAULT_WIDTH
    let y = stripTop + yOff
    drawFilledRect(renderer, cint(x), cint(y), cint(w), cint(h))
    drawFilledRect(renderer, cint(x - DEFAULT_WIDTH), cint(y), cint(w), cint(h))

  renderer.setDrawBlendMode(BlendMode_None)

proc renderBackdrop*(renderer: RendererPtr, level: Level, camX, time: float) =
  let theme = backdropThemeForLevel(level.id)
  let act = actForLevel(level.id)
  let actColor = actColorForLevel(level.id, time)
  renderSkyGradient(renderer, theme)
  renderCelestialBody(renderer, theme, theme.scene, time)
  renderAmbientStrata(renderer, theme, theme.scene)
  renderStars(renderer, theme, level.id, time)
  renderAurora(renderer, theme, time)
  renderHorizonBands(renderer, theme, camX)
  renderMidGroundSilhouettes(renderer, actColor, act, camX, theme.scene)
  renderMist(renderer, theme, theme.scene, time)
  renderNearGroundDetail(renderer, actColor, act, camX)
  renderForegroundStrip(renderer, actColor, act, camX)
  renderWaterShimmer(renderer, theme, time)
