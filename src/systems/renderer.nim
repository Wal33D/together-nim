## SDL2 renderer for Together — menu, gameplay, narration, win screen

import sdl2
import "../entities/character"
import "../entities/level"
import "levels"
import "../constants"
import "../game"
import "camera"
import "atmosphere"
import "backdrop"
import math

proc drawFilledRect(renderer: RendererPtr, x, y, w, h: cint) =
  var r = rect(x, y, w, h)
  renderer.fillRect(r.addr)

proc drawOutlineRect(renderer: RendererPtr, x, y, w, h: cint) =
  var r = rect(x, y, w, h)
  renderer.drawRect(r.addr)

# Simple bitmap font — draws text as small pixel blocks
proc drawChar(renderer: RendererPtr, ch: char, x, y, scale: int) =
  # Tiny 3x5 pixel font for basic ASCII
  const glyphs: array[128, array[5, uint8]] = block:
    var g: array[128, array[5, uint8]]
    # Space
    g[' '.int] = [0b000'u8, 0b000, 0b000, 0b000, 0b000]
    # Letters (uppercase)
    g['A'.int] = [0b010'u8, 0b101, 0b111, 0b101, 0b101]
    g['B'.int] = [0b110'u8, 0b101, 0b110, 0b101, 0b110]
    g['C'.int] = [0b011'u8, 0b100, 0b100, 0b100, 0b011]
    g['D'.int] = [0b110'u8, 0b101, 0b101, 0b101, 0b110]
    g['E'.int] = [0b111'u8, 0b100, 0b110, 0b100, 0b111]
    g['F'.int] = [0b111'u8, 0b100, 0b110, 0b100, 0b100]
    g['G'.int] = [0b011'u8, 0b100, 0b101, 0b101, 0b011]
    g['H'.int] = [0b101'u8, 0b101, 0b111, 0b101, 0b101]
    g['I'.int] = [0b111'u8, 0b010, 0b010, 0b010, 0b111]
    g['J'.int] = [0b001'u8, 0b001, 0b001, 0b101, 0b010]
    g['K'.int] = [0b101'u8, 0b110, 0b100, 0b110, 0b101]
    g['L'.int] = [0b100'u8, 0b100, 0b100, 0b100, 0b111]
    g['M'.int] = [0b101'u8, 0b111, 0b111, 0b101, 0b101]
    g['N'.int] = [0b101'u8, 0b111, 0b111, 0b111, 0b101]
    g['O'.int] = [0b010'u8, 0b101, 0b101, 0b101, 0b010]
    g['P'.int] = [0b110'u8, 0b101, 0b110, 0b100, 0b100]
    g['Q'.int] = [0b010'u8, 0b101, 0b101, 0b110, 0b011]
    g['R'.int] = [0b110'u8, 0b101, 0b110, 0b101, 0b101]
    g['S'.int] = [0b011'u8, 0b100, 0b010, 0b001, 0b110]
    g['T'.int] = [0b111'u8, 0b010, 0b010, 0b010, 0b010]
    g['U'.int] = [0b101'u8, 0b101, 0b101, 0b101, 0b010]
    g['V'.int] = [0b101'u8, 0b101, 0b101, 0b101, 0b010]
    g['W'.int] = [0b101'u8, 0b101, 0b111, 0b111, 0b101]
    g['X'.int] = [0b101'u8, 0b101, 0b010, 0b101, 0b101]
    g['Y'.int] = [0b101'u8, 0b101, 0b010, 0b010, 0b010]
    g['Z'.int] = [0b111'u8, 0b001, 0b010, 0b100, 0b111]
    # Numbers
    g['0'.int] = [0b010'u8, 0b101, 0b101, 0b101, 0b010]
    g['1'.int] = [0b010'u8, 0b110, 0b010, 0b010, 0b111]
    g['2'.int] = [0b110'u8, 0b001, 0b010, 0b100, 0b111]
    g['3'.int] = [0b110'u8, 0b001, 0b010, 0b001, 0b110]
    g['4'.int] = [0b101'u8, 0b101, 0b111, 0b001, 0b001]
    g['5'.int] = [0b111'u8, 0b100, 0b110, 0b001, 0b110]
    g['6'.int] = [0b011'u8, 0b100, 0b110, 0b101, 0b010]
    g['7'.int] = [0b111'u8, 0b001, 0b010, 0b010, 0b010]
    g['8'.int] = [0b010'u8, 0b101, 0b010, 0b101, 0b010]
    g['9'.int] = [0b010'u8, 0b101, 0b011, 0b001, 0b110]
    # Punctuation
    g['.'.int] = [0b000'u8, 0b000, 0b000, 0b000, 0b010]
    g[','.int] = [0b000'u8, 0b000, 0b000, 0b010, 0b100]
    g['!'.int] = [0b010'u8, 0b010, 0b010, 0b000, 0b010]
    g['?'.int] = [0b110'u8, 0b001, 0b010, 0b000, 0b010]
    g['-'.int] = [0b000'u8, 0b000, 0b111, 0b000, 0b000]
    g['\''.int] = [0b010'u8, 0b010, 0b000, 0b000, 0b000]
    g['"'.int] = [0b101'u8, 0b101, 0b000, 0b000, 0b000]
    g[':'.int] = [0b000'u8, 0b010, 0b000, 0b010, 0b000]
    # Lowercase maps to uppercase
    for c in 'a'..'z':
      g[c.int] = g[(c.int - 32)]
    g

  let idx = ch.int
  if idx < 0 or idx >= 128: return
  let glyph = glyphs[idx]
  for row in 0..4:
    for col in 0..2:
      if (glyph[row] and (1'u8 shl (2 - col))) != 0:
        drawFilledRect(renderer, cint(x + col * scale), cint(y + row * scale),
                       cint(scale), cint(scale))

proc drawText(renderer: RendererPtr, text: string, x, y: int, scale: int = 2) =
  let charW = 3 * scale + scale  # 3 pixel width + 1 pixel spacing
  for i, ch in text:
    drawChar(renderer, ch, x + i * charW, y, scale)

proc textWidth(text: string, scale: int = 2): int =
  let charW = 3 * scale + scale
  text.len * charW

proc renderMenu(renderer: RendererPtr, game: Game) =
  # Dark background
  renderer.setDrawColor(BG_COLOR.r, BG_COLOR.g, BG_COLOR.b, 255)
  renderer.clear()

  # Floating color particles behind the cast display
  renderer.setDrawBlendMode(BlendMode_Blend)
  for p in game.menuAtmosphere.particles:
    renderer.setDrawColor(p.color.r, p.color.g, p.color.b, p.alpha)
    let sz = max(1, p.size.cint)
    drawFilledRect(renderer, p.x.cint, p.y.cint, sz, sz)
  renderer.setDrawBlendMode(BlendMode_None)

  let centerX = DEFAULT_WIDTH div 2
  let t = game.menuTime

  # Title glow — render slightly larger transparent copy behind solid text
  let titleScale = 6
  let titleText = "TOGETHER"
  let titleW = textWidth(titleText, titleScale)
  let titleX = centerX - titleW div 2
  let titleY = 80
  renderer.setDrawBlendMode(BlendMode_Blend)
  renderer.setDrawColor(255, 255, 255, 40)
  drawText(renderer, titleText, titleX - 2, titleY - 2, titleScale + 1)
  renderer.setDrawBlendMode(BlendMode_None)
  # Solid title on top
  renderer.setDrawColor(255, 255, 255, 255)
  drawText(renderer, titleText, titleX, titleY, titleScale)

  # Tagline — pick based on time (alternates every 6 seconds)
  let taglines = ["A game about shapes who learned to feel.",
                   "They were rectangles. They were family."]
  let tagIdx = (int(t / 6.0)) mod taglines.len
  let subScale = 2
  let subText = taglines[tagIdx]
  let subW = textWidth(subText, subScale)
  renderer.setDrawColor(180, 180, 200, 255)
  drawText(renderer, subText, centerX - subW div 2, 160, subScale)

  # Character cast — 6 colored squares with names
  let castY = 220
  let sqSize = 36
  let spacing = 16
  let names = ["Pip", "Luca", "Bruno", "Cara", "Felix", "Ivy"]
  let colors = [PIP_COLOR, LUCA_COLOR, BRUNO_COLOR, CARA_COLOR, FELIX_COLOR, IVY_COLOR]
  let totalCastW = 6 * sqSize + 5 * spacing
  let castStartX = centerX - totalCastW div 2

  # Animated bobbing — sine wave, amplitude 3px, period 2s, offset by index
  for i in 0..5:
    let cx = castStartX + i * (sqSize + spacing)
    let bobOffset = int(3.0 * sin(t * PI + float(i) * 0.8))
    let cy = castY + bobOffset
    let c = colors[i]
    # Filled square
    renderer.setDrawColor(c.r, c.g, c.b, 255)
    drawFilledRect(renderer, cint(cx), cint(cy), cint(sqSize), cint(sqSize))
    # Name below
    renderer.setDrawColor(c.r, c.g, c.b, 255)
    let nameW = textWidth(names[i], 1)
    drawText(renderer, names[i], cx + sqSize div 2 - nameW div 2, cy + sqSize + 6, 1)

  # Line separator
  renderer.setDrawColor(60, 60, 80, 255)
  drawFilledRect(renderer, cint(centerX - 120), cint(320), 240, 1)

  # "Press ENTER to begin" with pulsing opacity (alpha 100-255 over 2 seconds)
  let promptScale = 2
  let promptText = "Press ENTER to begin"
  let promptW = textWidth(promptText, promptScale)
  let pulseAlpha = uint8(177.5 + 77.5 * sin(t * PI))  # oscillates 100..255
  renderer.setDrawBlendMode(BlendMode_Blend)
  renderer.setDrawColor(140, 140, 170, pulseAlpha)
  drawText(renderer, promptText, centerX - promptW div 2, 350, promptScale)
  renderer.setDrawBlendMode(BlendMode_None)

  # Controls hint
  let ctrlScale = 1
  let ctrl1 = "Arrow keys: move   Space: jump"
  let ctrl2 = "1-6: switch character   ESC: pause"
  let ctrl3 = "Gamepad: A=jump, Bumpers=switch, Start=pause"
  let ctrl1W = textWidth(ctrl1, ctrlScale)
  let ctrl2W = textWidth(ctrl2, ctrlScale)
  let ctrl3W = textWidth(ctrl3, ctrlScale)
  renderer.setDrawColor(80, 80, 110, 255)
  drawText(renderer, ctrl1, centerX - ctrl1W div 2, 400, ctrlScale)
  drawText(renderer, ctrl2, centerX - ctrl2W div 2, 418, ctrlScale)
  drawText(renderer, ctrl3, centerX - ctrl3W div 2, 436, ctrlScale)

proc renderGameplay(renderer: RendererPtr, game: Game) =
  if game.currentLevel < 0 or game.currentLevel >= allLevels.len:
    return

  let level = game.currentLevelState

  # Scenic backdrop — rendered BEFORE platforms and characters.
  renderBackdrop(renderer, level, game.camera.x, game.elapsedTime)

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

  # Characters
  for i, ch in game.characters:
    let isActive = i == game.activeCharacterIndex
    let chColor = CHAR_COLORS[ch.colorIndex mod 6]

    let dx = ch.drawX().cint - camX
    let dy = (ch.drawY() + ch.idleSway()).cint - camY
    let dw = ch.drawWidth().cint
    let dh = ch.drawHeight().cint

    # Selection glow behind active character
    if isActive:
      renderer.setDrawBlendMode(BlendMode_Blend)
      renderer.setDrawColor(chColor.r, chColor.g, chColor.b, 30)
      drawFilledRect(renderer, dx - 6, dy - 6, dw + 12, dh + 12)
      renderer.setDrawBlendMode(BlendMode_None)

    # Character body
    renderer.setDrawColor(chColor.r, chColor.g, chColor.b, 255)
    drawFilledRect(renderer, dx, dy, dw, dh)

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

  # --- UI: fixed screen positions (not affected by camera) ---

  # Character bar at bottom
  let barH = 30
  let barSpacing = 8
  let barY = DEFAULT_HEIGHT - barH - 8
  let totalBarW = level.characters.len * barH + max(0, level.characters.len - 1) * barSpacing
  let barStartX = (DEFAULT_WIDTH - totalBarW) div 2

  # Bar background
  renderer.setDrawBlendMode(BlendMode_Blend)
  renderer.setDrawColor(0, 0, 0, 100)
  drawFilledRect(renderer, cint(barStartX - 8), cint(barY - 4),
                 cint(totalBarW + 16), cint(barH + 8))
  renderer.setDrawBlendMode(BlendMode_None)

  for i in 0..<level.characters.len:
    let cx = barStartX + i * (barH + barSpacing)
    let c = CHAR_COLORS[game.characters[i].colorIndex mod 6]

    # Highlight active
    if i == game.activeCharacterIndex:
      renderer.setDrawColor(255, 255, 255, 255)
      drawOutlineRect(renderer, cint(cx - 2), cint(barY - 2), cint(barH + 4), cint(barH + 4))

    # Character square
    renderer.setDrawColor(c.r, c.g, c.b, 255)
    drawFilledRect(renderer, cx.cint, barY.cint, barH.cint, barH.cint)

    # Number key hint
    renderer.setDrawColor(200, 200, 220, 255)
    drawText(renderer, $(i + 1), cx + barH div 2 - 2, barY - 12, 1)

  # Narration
  if game.narrationActive or game.narrationRevealed > 0:
    let text = game.narrationText[0..<min(game.narrationRevealed, game.narrationText.len)]
    if text.len > 0:
      renderer.setDrawBlendMode(BlendMode_Blend)
      let narW = textWidth(text, 2) + 24
      let narX = (DEFAULT_WIDTH - narW) div 2
      renderer.setDrawColor(0, 0, 0, 180)
      drawFilledRect(renderer, narX.cint, 20, narW.cint, 30)
      renderer.setDrawBlendMode(BlendMode_None)
      renderer.setDrawColor(220, 220, 240, 255)
      drawText(renderer, text, narX + 12, 26, 2)

  # Level name (top right)
  renderer.setDrawColor(60, 60, 80, 255)
  let levelLabel = "Level " & $level.id & ": " & level.name
  drawText(renderer, levelLabel, DEFAULT_WIDTH - textWidth(levelLabel, 1) - 10, 6, 1)

proc renderPaused(renderer: RendererPtr, game: Game) =
  renderGameplay(renderer, game)
  # Overlay
  renderer.setDrawBlendMode(BlendMode_Blend)
  renderer.setDrawColor(0, 0, 0, 150)
  drawFilledRect(renderer, 0, 0, DEFAULT_WIDTH.cint, DEFAULT_HEIGHT.cint)
  renderer.setDrawBlendMode(BlendMode_None)
  # Paused text
  let pauseText = "PAUSED"
  let pw = textWidth(pauseText, 4)
  renderer.setDrawColor(255, 255, 255, 255)
  drawText(renderer, pauseText, DEFAULT_WIDTH div 2 - pw div 2, 200, 4)
  let resumeText = "Press ESC to resume"
  let rw = textWidth(resumeText, 2)
  renderer.setDrawColor(150, 150, 180, 255)
  drawText(renderer, resumeText, DEFAULT_WIDTH div 2 - rw div 2, 270, 2)

proc renderLevelWin(renderer: RendererPtr, game: Game) =
  renderGameplay(renderer, game)
  renderer.setDrawBlendMode(BlendMode_Blend)
  renderer.setDrawColor(0, 0, 0, 120)
  drawFilledRect(renderer, 0, 0, DEFAULT_WIDTH.cint, DEFAULT_HEIGHT.cint)
  renderer.setDrawBlendMode(BlendMode_None)

  let winText = "TOGETHER"
  let ww = textWidth(winText, 4)
  renderer.setDrawColor(255, 220, 100, 255)
  drawText(renderer, winText, DEFAULT_WIDTH div 2 - ww div 2, 180, 4)

  let nextText = "Press ENTER to continue"
  let nw = textWidth(nextText, 2)
  renderer.setDrawColor(180, 180, 200, 255)
  drawText(renderer, nextText, DEFAULT_WIDTH div 2 - nw div 2, 260, 2)

proc renderCredits(renderer: RendererPtr, game: Game) =
  renderer.setDrawColor(BG_COLOR.r, BG_COLOR.g, BG_COLOR.b, 255)
  renderer.clear()

  let centerX = DEFAULT_WIDTH div 2
  renderer.setDrawColor(255, 255, 255, 255)
  let t1 = "TOGETHER"
  drawText(renderer, t1, centerX - textWidth(t1, 4) div 2, 100, 4)

  renderer.setDrawColor(180, 180, 200, 255)
  let t2 = "They were shapes."
  let t3 = "They were colors."
  let t4 = "They were love in geometric form."
  drawText(renderer, t2, centerX - textWidth(t2, 2) div 2, 200, 2)
  drawText(renderer, t3, centerX - textWidth(t3, 2) div 2, 230, 2)
  drawText(renderer, t4, centerX - textWidth(t4, 2) div 2, 280, 2)

  renderer.setDrawColor(100, 100, 130, 255)
  let t5 = "Press ENTER for menu"
  drawText(renderer, t5, centerX - textWidth(t5, 1) div 2, 400, 1)

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
