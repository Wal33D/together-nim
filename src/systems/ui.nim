## Silky-driven UI overlay for Together.

import std/[math, strformat, strutils]
import windy
import vmath
import bumpy
import pixie
import silky
import "../constants"
import "../build_info"
import "../game"
import "audio"
import "levels"
import "ui_assets"

type
  UiRenderer* = ref object
    silky*: Silky

proc newUiRenderer*(): UiRenderer =
  let atlas = ensureUiAtlas()
  UiRenderer(silky: newSilky(atlas.pngPath, atlas.jsonPath))

proc bright(color: ColorRGBX, amount: int): ColorRGBX =
  rgbx(
    min(255, color.r.int + amount).uint8,
    min(255, color.g.int + amount).uint8,
    min(255, color.b.int + amount).uint8,
    color.a
  )

proc muted(color: ColorRGBX, alpha: uint8): ColorRGBX =
  rgbx(color.r, color.g, color.b, alpha)

proc drawCenteredText(sk: Silky, font, text: string, centerX, y: float32,
                      color: ColorRGBX) =
  let size = sk.getTextSize(font, text)
  discard sk.drawText(font, text, vec2(centerX - size.x * 0.5, y), color)

proc drawPanel(sk: Silky, pos, size: Vec2, fill, border: ColorRGBX) =
  sk.drawRect(pos, size, fill)
  sk.drawRect(pos, vec2(size.x, 2), border)
  sk.drawRect(pos, vec2(2, size.y), border)
  sk.drawRect(vec2(pos.x + size.x - 2, pos.y), vec2(2, size.y), border)
  sk.drawRect(vec2(pos.x, pos.y + size.y - 2), vec2(size.x, 2), border)

proc button(sk: Silky, window: Window, pos, size: Vec2, label, detail: string,
            accent: ColorRGBX): bool =
  let r = rect(pos.x, pos.y, size.x, size.y)
  let hovered = window.mousePos.vec2.overlaps(r)
  let clicked = hovered and window.buttonPressed[MouseLeft]
  let fill =
    if hovered: rgbx(34, 40, 50, 248)
    else: rgbx(24, 28, 36, 236)

  sk.drawPanel(pos, size, fill, muted(accent, 255))
  sk.drawRect(pos, vec2(size.x, 6), muted(accent, if hovered: 255'u8 else: 220'u8))

  discard sk.drawText("Body", label, vec2(pos.x + 18, pos.y + 16),
                      rgbx(238, 242, 247, 255))
  if detail.len > 0:
    discard sk.drawText("Small", detail, vec2(pos.x + 18, pos.y + 46),
                        rgbx(142, 154, 174, 255))
  clicked

proc actionButton(sk: Silky, window: Window, x, y, w: float32, label, detail: string,
                  accent: ColorRGBX): bool =
  sk.button(window, vec2(x, y), vec2(w, 74), label, detail, accent)

proc renderBuildStamp(sk: Silky, frameSize: IVec2) =
  let
    label = "v" & GameVersion
    size = sk.getTextSize("Small", label)
    pos = vec2(16, frameSize.y.float32 - size.y - 18)
    boxPos = pos - vec2(10, 8)
    boxSize = vec2(size.x + 20, size.y + 16)
  sk.drawPanel(boxPos, boxSize, rgbx(8, 10, 14, 170), rgbx(66, 76, 94, 220))
  discard sk.drawText("Small", label, pos, rgbx(150, 160, 182, 255))

proc renderCharacterStrip(sk: Silky, game: Game, frameSize: IVec2) =
  if game.characters.len == 0:
    return

  let
    slotW = 58.0
    slotH = 46.0
    spacing = 12.0
    totalW = game.characters.len.float32 * slotW +
      max(0, game.characters.len - 1).float32 * spacing
    panelPos = vec2(frameSize.x.float32 * 0.5 - totalW * 0.5 - 18, frameSize.y.float32 - 86)
    panelSize = vec2(totalW + 36, 64)

  sk.drawPanel(panelPos, panelSize, rgbx(8, 10, 14, 150), rgbx(46, 54, 68, 210))

  for i, ch in game.characters:
    let
      slotX = panelPos.x + 18 + i.float32 * (slotW + spacing)
      slotPos = vec2(slotX, panelPos.y + 9)
      color = CHAR_COLORS[ch.colorIndex mod CHAR_COLORS.len]
      tile = rgbx(color.r, color.g, color.b, 255)
      keyText = $(i + 1)
    if i == game.activeCharacterIndex:
      sk.drawPanel(slotPos - vec2(4, 4), vec2(slotW + 8, slotH + 8),
                   rgbx(16, 18, 24, 120), rgbx(240, 244, 248, 255))
    sk.drawPanel(slotPos, vec2(slotW, slotH), tile, bright(tile, 24))
    discard sk.drawText("Small", keyText, vec2(slotPos.x + 6, slotPos.y - 14),
                        rgbx(198, 204, 220, 255))
    let name = ch.id.capitalizeAscii()
    drawCenteredText(sk, "Small", name, slotPos.x + slotW * 0.5, slotPos.y + slotH + 6,
                     tile)

proc renderGameplayHud(sk: Silky, game: Game, frameSize: IVec2) =
  if game.currentLevel >= 0 and game.currentLevel < allLevels.len:
    let
      level = game.currentLevelState
      levelText = &"Level {level.id}: {level.name}"
      size = sk.getTextSize("Small", levelText)
      boxPos = vec2(frameSize.x.float32 - size.x - 34, 16)
      boxSize = vec2(size.x + 18, size.y + 14)
    sk.drawPanel(boxPos, boxSize, rgbx(10, 12, 18, 150), rgbx(60, 70, 92, 220))
    discard sk.drawText("Small", levelText, boxPos + vec2(9, 7), rgbx(204, 211, 224, 255))

  renderCharacterStrip(sk, game, frameSize)

  if game.narrationActive or game.narrationRevealed > 0:
    let text = game.narrationText[0..<min(game.narrationRevealed, game.narrationText.len)]
    if text.len > 0:
      let
        maxWidth = min(frameSize.x.float32 - 180, 720.0)
        textSize = sk.getTextSize("Body", text)
        boxW = min(maxWidth, textSize.x + 40)
        boxH = max(56.0, textSize.y + 22)
        boxPos = vec2(frameSize.x.float32 * 0.5 - boxW * 0.5, 20)
      sk.drawPanel(boxPos, vec2(boxW, boxH), rgbx(10, 12, 18, 188), rgbx(86, 98, 122, 220))
      discard sk.drawText("Body", text, boxPos + vec2(20, 13), rgbx(236, 239, 244, 255),
                          maxWidth = boxW - 40, maxHeight = boxH - 22, wordWrap = true)

proc renderCastCard(sk: Silky, x, y: float32, idx: int, name, role: string) =
  let
    base = CHAR_COLORS[idx mod CHAR_COLORS.len]
    accent = rgbx(base.r, base.g, base.b, 255)
    pos = vec2(x, y)
    size = vec2(156, 88)
  sk.drawPanel(pos, size, rgbx(16, 19, 26, 206), muted(accent, 220))
  sk.drawRect(pos + vec2(16, 18), vec2(30, 30), accent)
  discard sk.drawText("Body", name, pos + vec2(58, 14), rgbx(238, 242, 247, 255))
  discard sk.drawText("Small", role, pos + vec2(58, 44), rgbx(156, 166, 184, 255))

proc renderMenu(sk: Silky, window: Window, game: var Game, frameSize: IVec2) =
  let
    leftPos = vec2(64, 54)
    leftSize = vec2(396, 424)
    rightPos = vec2(frameSize.x.float32 - 404, 72)
    rightSize = vec2(340, 336)
    startY = leftPos.y + leftSize.y - 106

  sk.drawPanel(leftPos, leftSize, rgbx(10, 12, 18, 210), rgbx(78, 92, 116, 230))
  discard sk.drawText("Display", "TOGETHER", leftPos + vec2(28, 24), rgbx(246, 248, 251, 255))
  discard sk.drawText("Small", "A quiet platformer about color, cooperation, and timing.",
                      leftPos + vec2(30, 86), rgbx(160, 171, 192, 255))
  discard sk.drawText("Body", "Guide the whole cast through layered spaces.", leftPos + vec2(30, 136),
                      rgbx(228, 233, 241, 255))
  discard sk.drawText("Body", "Swap bodies. Share paths. Land together.",
                      leftPos + vec2(30, 168), rgbx(228, 233, 241, 255))
  discard sk.drawText("Small", "Keyboard: arrows or A/D to move, Space to jump, 1-6 to switch.",
                      leftPos + vec2(30, 236), rgbx(148, 159, 177, 255))
  discard sk.drawText("Small", "Gamepad: D-pad or stick to move, A to jump, bumpers to switch.",
                      leftPos + vec2(30, 262), rgbx(148, 159, 177, 255))
  discard sk.drawText("Small", "F11 toggles fullscreen.", leftPos + vec2(30, 288),
                      rgbx(148, 159, 177, 255))

  if sk.actionButton(window, leftPos.x + 28, startY, leftSize.x - 56,
                     "Begin Journey", "Start from the opening level.",
                     rgbx(108, 168, 232, 255)):
    game.startGame()
    playSound(soundCharSwitch)

  sk.drawPanel(rightPos, rightSize, rgbx(10, 12, 18, 172), rgbx(68, 78, 98, 214))
  discard sk.drawText("Body", "The Cast", rightPos + vec2(24, 18), rgbx(240, 243, 248, 255))
  renderCastCard(sk, rightPos.x + 22, rightPos.y + 60, 0, "Pip", "nimble, precise")
  renderCastCard(sk, rightPos.x + 182, rightPos.y + 60, 1, "Luca", "steady runner")
  renderCastCard(sk, rightPos.x + 22, rightPos.y + 160, 2, "Bruno", "heavy pressure")
  renderCastCard(sk, rightPos.x + 182, rightPos.y + 160, 3, "Cara", "air control")
  renderCastCard(sk, rightPos.x + 22, rightPos.y + 260, 4, "Felix", "late jumps")
  renderCastCard(sk, rightPos.x + 182, rightPos.y + 260, 5, "Ivy", "extra leap")

proc renderPauseModal(sk: Silky, window: Window, game: var Game, frameSize: IVec2) =
  let
    pos = vec2(frameSize.x.float32 * 0.5 - 220, frameSize.y.float32 * 0.5 - 150)
    size = vec2(440, 300)
  sk.drawPanel(pos, size, rgbx(10, 12, 18, 228), rgbx(90, 104, 132, 240))
  discard sk.drawText("Display", "Paused", pos + vec2(42, 28), rgbx(248, 249, 251, 255))
  discard sk.drawText("Small", "Press Esc or choose an action below.",
                      pos + vec2(44, 92), rgbx(156, 166, 184, 255))

  if sk.actionButton(window, pos.x + 42, pos.y + 132, size.x - 84,
                     "Resume", "Back to the current level.",
                     rgbx(108, 168, 232, 255)):
    game.state = playing

  if sk.actionButton(window, pos.x + 42, pos.y + 214, (size.x - 96) * 0.5,
                     "Restart", "Reload this level.",
                     rgbx(232, 178, 92, 255)):
    game.restartLevel()
    game.state = playing

  if sk.actionButton(window, pos.x + 54 + (size.x - 96) * 0.5, pos.y + 214, (size.x - 96) * 0.5,
                     "Menu", "Return to the title screen.",
                     rgbx(178, 112, 128, 255)):
    game.state = menu

proc renderWinModal(sk: Silky, window: Window, game: var Game, frameSize: IVec2) =
  let
    pos = vec2(frameSize.x.float32 * 0.5 - 226, frameSize.y.float32 * 0.5 - 132)
    size = vec2(452, 264)
  sk.drawPanel(pos, size, rgbx(12, 14, 18, 220), rgbx(132, 110, 54, 240))
  discard sk.drawText("Display", "Together", pos + vec2(42, 28), rgbx(248, 232, 178, 255))
  discard sk.drawText("Body", "Everyone made it through.", pos + vec2(46, 94),
                      rgbx(238, 240, 244, 255))
  discard sk.drawText("Small", "Press Enter or continue to the next room.",
                      pos + vec2(46, 126), rgbx(160, 170, 186, 255))
  if sk.actionButton(window, pos.x + 46, pos.y + 166, size.x - 92,
                     "Continue", "Advance to the next level.",
                     rgbx(232, 184, 88, 255)):
    game.nextLevel()

proc renderCredits(sk: Silky, window: Window, game: var Game, frameSize: IVec2) =
  let
    pos = vec2(frameSize.x.float32 * 0.5 - 250, 72)
    size = vec2(500, 360)
  sk.drawPanel(pos, size, rgbx(10, 12, 18, 214), rgbx(78, 92, 116, 230))
  discard sk.drawText("Display", "Together", pos + vec2(48, 28), rgbx(248, 249, 251, 255))
  discard sk.drawText("Body", "They were shapes.", pos + vec2(52, 104), rgbx(228, 233, 241, 255))
  discard sk.drawText("Body", "They were colors.", pos + vec2(52, 136), rgbx(228, 233, 241, 255))
  discard sk.drawText("Body", "They were love in geometric form.",
                      pos + vec2(52, 168), rgbx(228, 233, 241, 255))
  discard sk.drawText("Small", "UI iteration now runs on Windy + Boxy + Silky.",
                      pos + vec2(52, 230), rgbx(150, 160, 180, 255))
  if sk.actionButton(window, pos.x + 52, pos.y + 276, size.x - 104,
                     "Return to Menu", "Back to the title screen.",
                     rgbx(108, 168, 232, 255)):
    game.state = menu

proc renderOverlay*(ui: UiRenderer, window: Window, game: var Game,
                    frameSize: IVec2) =
  let sk = ui.silky
  sk.beginUi(window, frameSize)

  case game.state
  of menu:
    sk.drawRect(vec2(0, 0), vec2(frameSize.x.float32, frameSize.y.float32),
                rgbx(0, 0, 0, 24))
    sk.renderMenu(window, game, frameSize)
  of playing:
    sk.renderGameplayHud(game, frameSize)
  of paused:
    sk.renderGameplayHud(game, frameSize)
    sk.drawRect(vec2(0, 0), vec2(frameSize.x.float32, frameSize.y.float32),
                rgbx(0, 0, 0, 80))
    sk.renderPauseModal(window, game, frameSize)
  of levelWin:
    sk.renderGameplayHud(game, frameSize)
    sk.drawRect(vec2(0, 0), vec2(frameSize.x.float32, frameSize.y.float32),
                rgbx(4, 4, 6, 72))
    sk.renderWinModal(window, game, frameSize)
  of credits:
    sk.drawRect(vec2(0, 0), vec2(frameSize.x.float32, frameSize.y.float32),
                rgbx(0, 0, 0, 34))
    sk.renderCredits(window, game, frameSize)

  sk.renderBuildStamp(frameSize)
  sk.endUi()
