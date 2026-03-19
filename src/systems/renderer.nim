## SDL2 renderer for Together game elements

import sdl2
import "../game"
import "../entities/level"
import "levels"
import "../constants"

proc charColor(id: string): tuple[r, g, b: uint8] =
  case id
  of "pip":   (r: 255'u8, g: 182'u8, b: 193'u8)
  of "luca":  (r: 255'u8, g: 220'u8, b:  50'u8)
  of "bruno": (r: 139'u8, g:  90'u8, b:  43'u8)
  of "cara":  (r: 255'u8, g: 210'u8, b: 220'u8)
  of "felix": (r: 210'u8, g: 180'u8, b: 140'u8)
  of "ivy":   (r:   0'u8, g: 128'u8, b: 128'u8)
  else:       (r: 200'u8, g: 200'u8, b: 200'u8)

proc renderGame*(renderer: RendererPtr, game: Game) =
  # Background
  renderer.setDrawColor(26, 26, 46, 255)
  renderer.clear()

  if game.state != playing and game.state != paused:
    return

  if game.currentLevel < 0 or game.currentLevel >= allLevels.len:
    return

  let level = allLevels[game.currentLevel]

  # Platforms (gray filled rectangles)
  renderer.setDrawColor(128, 128, 128, 255)
  for p in level.platforms:
    var r = rect(p.x.cint, p.y.cint, p.width.cint, p.height.cint)
    renderer.fillRect(r.addr)

  # Hazards (red filled rectangles)
  renderer.setDrawColor(220, 60, 60, 255)
  for h in level.hazards:
    var r = rect(h.x.cint, h.y.cint, h.width.cint, h.height.cint)
    renderer.fillRect(r.addr)

  # Doors (semi-transparent; disappear when open)
  renderer.setDrawBlendMode(BlendMode_Blend)
  for d in level.doors:
    if not d.isOpen:
      renderer.setDrawColor(80, 80, 200, 180)
      var r = rect(d.x.cint, d.y.cint, d.width.cint, d.height.cint)
      renderer.fillRect(r.addr)
  renderer.setDrawBlendMode(BlendMode_None)

  # Buttons (small colored rectangles, lit when pressed)
  for b in level.buttons:
    renderer.setDrawColor(255, 220, 50, 255)
    var r = rect(b.x.cint, b.y.cint, b.width.cint, b.height.cint)
    renderer.fillRect(r.addr)

  # Exits (character-colored outlined rectangles)
  for e in level.exits:
    let c = charColor(e.characterId)
    renderer.setDrawColor(c.r, c.g, c.b, 255)
    var r = rect(e.x.cint, e.y.cint, e.width.cint, e.height.cint)
    renderer.drawRect(r.addr)

  # Characters (colored filled rectangles)
  for i, ch in game.characters:
    let c = CHAR_COLORS[ch.colorIndex mod 6]
    renderer.setDrawColor(c.r, c.g, c.b, 255)
    var r = rect(ch.x.cint, ch.y.cint, CHAR_WIDTH.cint, CHAR_HEIGHT.cint)
    renderer.fillRect(r.addr)
    # Active character white outline highlight
    if i == game.activeCharacterIndex:
      renderer.setDrawColor(255, 255, 255, 255)
      var outline = rect(ch.x.cint - 2, ch.y.cint - 2,
                         (CHAR_WIDTH + 4).cint, (CHAR_HEIGHT + 4).cint)
      renderer.drawRect(outline.addr)

  # Character bar at bottom
  let charSize = 40
  let spacing = 10
  let barY = DEFAULT_HEIGHT - charSize - 10
  let totalWidth = level.characters.len * charSize +
                   max(0, level.characters.len - 1) * spacing
  let barX = (DEFAULT_WIDTH - totalWidth) div 2

  for i, charId in level.characters:
    let c = charColor(charId)
    let cx = barX + i * (charSize + spacing)
    # Highlight active character with white outline
    if i == game.activeCharacterIndex:
      renderer.setDrawColor(255, 255, 255, 255)
      var highlight = rect((cx - 3).cint, (barY - 3).cint,
                           (charSize + 6).cint, (charSize + 6).cint)
      renderer.drawRect(highlight.addr)
    renderer.setDrawColor(c.r, c.g, c.b, 255)
    var r = rect(cx.cint, barY.cint, charSize.cint, charSize.cint)
    renderer.fillRect(r.addr)
