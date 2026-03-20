## Code-rendered scenic backdrops for Together.
## These are intentionally geometric so they stay in style with the characters.

import sdl2
import math
import "../constants"
import "../entities/level"

type
  BackdropScene* = enum
    dawnMeadow, riverValley, stoneRuins, nightSky

  BackdropTheme* = object
    scene*: BackdropScene
    skyTop*: constants.Color
    skyBottom*: constants.Color
    horizon*: constants.Color
    silhouette*: constants.Color
    glow*: constants.Color
    accent*: constants.Color

proc drawFilledRect(renderer: RendererPtr, x, y, w, h: cint) =
  var r = rect(x, y, w, h)
  renderer.fillRect(r.addr)

proc clamp01(value: float): float =
  result = max(0.0, min(1.0, value))

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
      skyTop: (r: 32'u8, g: 44'u8, b: 74'u8),
      skyBottom: (r: 112'u8, g: 128'u8, b: 150'u8),
      horizon: (r: 74'u8, g: 92'u8, b: 86'u8),
      silhouette: (r: 42'u8, g: 60'u8, b: 54'u8),
      glow: (r: 255'u8, g: 224'u8, b: 144'u8),
      accent: (r: 140'u8, g: 180'u8, b: 120'u8),
    )
  of riverValley:
    BackdropTheme(
      scene: scene,
      skyTop: (r: 22'u8, g: 36'u8, b: 70'u8),
      skyBottom: (r: 88'u8, g: 116'u8, b: 150'u8),
      horizon: (r: 52'u8, g: 74'u8, b: 100'u8),
      silhouette: (r: 28'u8, g: 44'u8, b: 68'u8),
      glow: (r: 180'u8, g: 230'u8, b: 255'u8),
      accent: (r: 118'u8, g: 160'u8, b: 190'u8),
    )
  of stoneRuins:
    BackdropTheme(
      scene: scene,
      skyTop: (r: 38'u8, g: 36'u8, b: 64'u8),
      skyBottom: (r: 104'u8, g: 90'u8, b: 120'u8),
      horizon: (r: 84'u8, g: 78'u8, b: 94'u8),
      silhouette: (r: 46'u8, g: 42'u8, b: 58'u8),
      glow: (r: 220'u8, g: 200'u8, b: 240'u8),
      accent: (r: 160'u8, g: 140'u8, b: 180'u8),
    )
  of nightSky:
    BackdropTheme(
      scene: scene,
      skyTop: (r: 10'u8, g: 14'u8, b: 32'u8),
      skyBottom: (r: 26'u8, g: 28'u8, b: 54'u8),
      horizon: (r: 30'u8, g: 36'u8, b: 64'u8),
      silhouette: (r: 18'u8, g: 22'u8, b: 40'u8),
      glow: (r: 140'u8, g: 200'u8, b: 255'u8),
      accent: (r: 96'u8, g: 132'u8, b: 180'u8),
    )

proc levelBackdropScene*(levelId: int): BackdropScene =
  case levelId
  of 1..4: dawnMeadow
  of 5..7: riverValley
  of 8..10: stoneRuins
  else: nightSky

proc backdropThemeForLevel*(levelId: int): BackdropTheme =
  themeForScene(levelBackdropScene(levelId))

proc renderBackdropSky(renderer: RendererPtr, theme: BackdropTheme, time: float) =
  let bands = 14
  let bandH = max(1, DEFAULT_HEIGHT div bands)
  for i in 0..<bands:
    let t = float(i) / float(max(1, bands - 1))
    let color = mixColor(theme.skyTop, theme.skyBottom, t)
    renderer.setDrawColor(color.r, color.g, color.b, 255)
    drawFilledRect(renderer, 0.cint, cint(i * bandH), DEFAULT_WIDTH.cint, cint(bandH + 1))

  let shimmer = 0.5 + 0.5 * sin(time * 0.8)
  renderer.setDrawBlendMode(BlendMode_Blend)
  renderer.setDrawColor(theme.glow.r, theme.glow.g, theme.glow.b, uint8(24 + shimmer * 18.0))
  drawFilledRect(renderer, 0.cint, 0.cint, DEFAULT_WIDTH.cint, (DEFAULT_HEIGHT div 2).cint)
  renderer.setDrawBlendMode(BlendMode_None)

proc renderStars(renderer: RendererPtr, levelId: int, theme: BackdropTheme, time: float) =
  if theme.scene != nightSky:
    return

  renderer.setDrawBlendMode(BlendMode_Blend)
  for i in 0..<36:
    let x = (i * 97 + levelId * 23) mod DEFAULT_WIDTH
    let y = (i * 53 + levelId * 41) mod (DEFAULT_HEIGHT div 2)
    let twinkle = 32 + int(22.0 * (0.5 + 0.5 * sin(time * 1.8 + float(i) * 0.37)))
    renderer.setDrawColor(theme.glow.r, theme.glow.g, theme.glow.b, uint8(twinkle))
    drawFilledRect(renderer, cint(x), cint(y), 2.cint, 2.cint)
  renderer.setDrawBlendMode(BlendMode_None)

proc renderClouds(renderer: RendererPtr, theme: BackdropTheme, levelId: int, time: float) =
  renderer.setDrawBlendMode(BlendMode_Blend)
  for i in 0..<5:
    let baseX = int((float(levelId) * 73.0 + float(i) * 167.0 + time * (12.0 + float(i) * 3.0))) mod (DEFAULT_WIDTH + 140) - 70
    let baseY = 36 + i * 28
    let width = 90 + (i mod 3) * 20
    let alpha = uint8(18 + i * 4)
    renderer.setDrawColor(theme.glow.r, theme.glow.g, theme.glow.b, alpha)
    drawFilledRect(renderer, cint(baseX), cint(baseY), cint(width), 10.cint)
    drawFilledRect(renderer, cint(baseX + 18), cint(baseY - 6), cint(width - 36), 12.cint)
    drawFilledRect(renderer, cint(baseX + 36), cint(baseY + 4), cint(width - 64), 8.cint)
  renderer.setDrawBlendMode(BlendMode_None)

proc renderHills(renderer: RendererPtr, theme: BackdropTheme, levelId: int, camX: float) =
  let parallax = case theme.scene
    of dawnMeadow: 0.10
    of riverValley: 0.16
    of stoneRuins: 0.12
    of nightSky: 0.05

  let bandY = DEFAULT_HEIGHT - 126
  let offset = int(camX * parallax)
  for layer in 0..2:
    let layerColor = mixColor(theme.horizon, theme.silhouette, float(layer) * 0.22)
    renderer.setDrawColor(layerColor.r, layerColor.g, layerColor.b, 255)
    let y = bandY + layer * 24
    let height = 52 + layer * 18
    let widthShift = (levelId * 37 + layer * 91) mod 220
    for x in -2..6:
      let segmentX = x * 150 - offset + widthShift div 2
      drawFilledRect(renderer, cint(segmentX), cint(y), 120.cint, cint(height))

proc renderMotifs(renderer: RendererPtr, theme: BackdropTheme, levelId: int, camX: float, time: float) =
  let horizonY = DEFAULT_HEIGHT - 138
  case theme.scene
  of dawnMeadow:
    renderer.setDrawColor(theme.accent.r, theme.accent.g, theme.accent.b, 255)
    for i in 0..<7:
      let x = (i * 103 + levelId * 19) mod (DEFAULT_WIDTH + 120) - 60
      let trunkH = 18 + (i mod 3) * 6
      drawFilledRect(renderer, cint(x), cint(horizonY - trunkH), 6.cint, cint(trunkH))
      drawFilledRect(renderer, cint(x - 10), cint(horizonY - trunkH - 12), 26.cint, 12.cint)
      drawFilledRect(renderer, cint(x - 14), cint(horizonY - trunkH - 4), 34.cint, 8.cint)
  of riverValley:
    renderer.setDrawColor(theme.accent.r, theme.accent.g, theme.accent.b, 255)
    for i in 0..<5:
      let x = int((float(levelId) * 61.0 + float(i) * 143.0 + camX * 0.2)) mod (DEFAULT_WIDTH + 160) - 80
      drawFilledRect(renderer, cint(x), cint(horizonY - 26 - (i mod 2) * 8), 18.cint, 34.cint)
      drawFilledRect(renderer, cint(x - 10), cint(horizonY - 42), 38.cint, 10.cint)
    renderer.setDrawColor(theme.glow.r, theme.glow.g, theme.glow.b, 90)
    drawFilledRect(renderer, 0.cint, cint(horizonY + 10), DEFAULT_WIDTH.cint, 10.cint)
  of stoneRuins:
    renderer.setDrawColor(theme.accent.r, theme.accent.g, theme.accent.b, 255)
    for i in 0..<6:
      let x = (i * 116 + levelId * 17) mod (DEFAULT_WIDTH + 150) - 75
      let h = 46 + (i mod 3) * 18
      drawFilledRect(renderer, cint(x), cint(horizonY - h), 20.cint, cint(h))
      drawFilledRect(renderer, cint(x - 8), cint(horizonY - h - 10), 36.cint, 10.cint)
      if i mod 2 == 0:
        renderer.setDrawColor(theme.glow.r, theme.glow.g, theme.glow.b, 50)
        drawFilledRect(renderer, cint(x + 5), cint(horizonY - h + 12), 8.cint, 12.cint)
        renderer.setDrawColor(theme.accent.r, theme.accent.g, theme.accent.b, 255)
  of nightSky:
    renderer.setDrawColor(theme.accent.r, theme.accent.g, theme.accent.b, 255)
    for i in 0..<5:
      let x = (i * 172 + levelId * 13) mod (DEFAULT_WIDTH + 120) - 60
      let pHeight = 40 + (i mod 3) * 20
      drawFilledRect(renderer, cint(x), cint(horizonY - pHeight), 14.cint, cint(pHeight))
      drawFilledRect(renderer, cint(x - 6), cint(horizonY - pHeight - 10), 26.cint, 10.cint)
    renderer.setDrawBlendMode(BlendMode_Blend)
    renderer.setDrawColor(theme.glow.r, theme.glow.g, theme.glow.b, 42)
    drawFilledRect(renderer, 0.cint, cint(horizonY - 48), DEFAULT_WIDTH.cint, 36.cint)
    renderer.setDrawBlendMode(BlendMode_None)

proc renderBackdrop*(renderer: RendererPtr, level: Level, camX, time: float) =
  let theme = backdropThemeForLevel(level.id)
  renderBackdropSky(renderer, theme, time)
  renderStars(renderer, level.id, theme, time)
  renderClouds(renderer, theme, level.id, time)
  renderHills(renderer, theme, level.id, camX)
  renderMotifs(renderer, theme, level.id, camX, time)
