## Code-rendered ambient backdrops for Together.
## The goal is mood and depth, not literal scenery props.

import math
import "../constants"
import "../entities/level"
import "render_backend"

type
  BackdropScene* = enum
    dawnMeadow, riverValley, stoneRuins, nightSky

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

proc levelBackdropScene*(levelId: int): BackdropScene =
  case levelId
  of 1..4: dawnMeadow
  of 5..7: riverValley
  of 8..10: stoneRuins
  else: nightSky

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

proc renderStars(renderer: RendererPtr, theme: BackdropTheme, levelId: int, time: float) =
  if theme.scene != nightSky:
    return

  renderer.setDrawBlendMode(BlendMode_Blend)
  for i in 0..<36:
    let x = (i * 97 + levelId * 23) mod DEFAULT_WIDTH
    let y = (i * 53 + levelId * 41) mod (DEFAULT_HEIGHT div 2)
    let twinkle = 26 + int(24.0 * (0.5 + 0.5 * sin(time * 1.8 + float(i) * 0.37)))
    renderer.setDrawColor(theme.glow.r, theme.glow.g, theme.glow.b, uint8(twinkle))
    drawFilledRect(renderer, cint(x), cint(y), 2, 2)
  renderer.setDrawBlendMode(BlendMode_None)

proc renderAurora(renderer: RendererPtr, theme: BackdropTheme, time: float) =
  if theme.scene != nightSky:
    return

  renderer.setDrawBlendMode(BlendMode_Blend)
  for i in 0..<5:
    let x = 80 + i * 132 + int(10.0 * sin(time * 0.4 + float(i)))
    let width = 56 + (i mod 2) * 18
    let height = 180 + (i mod 3) * 26
    let alpha = uint8(16 + i * 5)
    renderer.setDrawColor(theme.haze.r, theme.haze.g, theme.haze.b, alpha)
    drawFilledRect(renderer, cint(x), 12, cint(width), cint(height))
  renderer.setDrawBlendMode(BlendMode_None)

proc renderHorizonBands(renderer: RendererPtr, theme: BackdropTheme, camX: float) =
  let bandBaseY = DEFAULT_HEIGHT - 158
  let parallax = case theme.scene
    of dawnMeadow: 0.08
    of riverValley: 0.12
    of stoneRuins: 0.10
    of nightSky: 0.05

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
  renderer.setDrawBlendMode(BlendMode_None)

proc renderBackdrop*(renderer: RendererPtr, level: Level, camX, time: float) =
  let theme = backdropThemeForLevel(level.id)
  renderSkyGradient(renderer, theme)
  renderCelestialBody(renderer, theme, theme.scene, time)
  renderAmbientStrata(renderer, theme, theme.scene)
  renderStars(renderer, theme, level.id, time)
  renderAurora(renderer, theme, time)
  renderHorizonBands(renderer, theme, camX)
  renderMist(renderer, theme, theme.scene, time)
  renderWaterShimmer(renderer, theme, time)
