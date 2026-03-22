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
import "../entities/character"
import "audio"
import "levels"
import "ui_assets"

type
  UiLayout = object
    scale*: float32
    origin*: Vec2
    frameSize*: IVec2

  UiContext* = object
    wantsMouse*: bool
    wantsKeyboard*: bool
    hotWidget*: string

  UiRenderer* = ref object
    silky*: Silky
    context*: UiContext
    menuSpotlight*: int
    pauseSelection*: int

proc newUiRenderer*(): UiRenderer =
  let atlas = ensureUiAtlas()
  UiRenderer(
    silky: newSilky(atlas.pngPath, atlas.jsonPath),
    context: UiContext(),
    menuSpotlight: 0,
    pauseSelection: 0,
  )

proc noteHot(ui: UiRenderer, widgetId: string, wantsMouse = true,
             wantsKeyboard = false) =
  ui.context.wantsMouse = ui.context.wantsMouse or wantsMouse
  ui.context.wantsKeyboard = ui.context.wantsKeyboard or wantsKeyboard
  if widgetId.len > 0:
    ui.context.hotWidget = widgetId

proc cycleMenuSpotlight*(ui: UiRenderer, delta: int) =
  const count = 6
  ui.menuSpotlight = (ui.menuSpotlight + delta + count * 4) mod count

proc cyclePauseSelection*(ui: UiRenderer, delta: int) =
  const count = 3
  ui.pauseSelection = (ui.pauseSelection + delta + count * 4) mod count

proc activateFocusedAction*(ui: UiRenderer, game: var Game) =
  case game.state
  of menu:
    game.startGame()
    playSound(soundCharSwitch)
  of paused:
    case ui.pauseSelection
    of 0:
      game.state = playing
    of 1:
      game.restartLevel()
      game.state = playing
    of 2:
      game.state = menu
    else:
      discard
  else:
    discard

proc bright(color: ColorRGBX, amount: int): ColorRGBX =
  rgbx(
    min(255, color.r.int + amount).uint8,
    min(255, color.g.int + amount).uint8,
    min(255, color.b.int + amount).uint8,
    color.a
  )

proc muted(color: ColorRGBX, alpha: uint8): ColorRGBX =
  rgbx(color.r, color.g, color.b, alpha)

proc characterName(ch: Character): string =
  ch.id.capitalizeAscii()

proc characterGift(ch: Character): string =
  case ch.ability
  of doubleJump: "Gift: Double jump"
  of floatAbility: "Gift: Float"
  of heavy: "Gift: Heavy pressure"
  of wallJump: "Gift: Wall jump"
  of coyoteTime: "Gift: Late jump grace"
  of gracefulFall: "Gift: Graceful fall"

proc exitCount(game: Game): int =
  for ch in game.characters:
    if ch.atExit:
      inc result

proc initLayout(frameSize: IVec2): UiLayout =
  let sx = frameSize.x.float32 / DEFAULT_WIDTH.float32
  let sy = frameSize.y.float32 / DEFAULT_HEIGHT.float32
  result.scale = min(sx, sy)
  result.origin = vec2(
    (frameSize.x.float32 - DEFAULT_WIDTH.float32 * result.scale) * 0.5,
    (frameSize.y.float32 - DEFAULT_HEIGHT.float32 * result.scale) * 0.5
  )
  result.frameSize = frameSize

proc px(layout: UiLayout, value: float32): float32 =
  round(value * layout.scale)

proc snap(v: Vec2): Vec2 =
  vec2(round(v.x), round(v.y))

proc p(layout: UiLayout, x, y: float32): Vec2 =
  snap(layout.origin + vec2(layout.px(x), layout.px(y)))

proc d(layout: UiLayout, x, y: float32): Vec2 =
  vec2(layout.px(x), layout.px(y))

proc sz(layout: UiLayout, w, h: float32): Vec2 =
  vec2(layout.px(w), layout.px(h))

proc left(layout: UiLayout): float32 = layout.origin.x
proc top(layout: UiLayout): float32 = layout.origin.y
proc right(layout: UiLayout): float32 = layout.origin.x + DEFAULT_WIDTH.float32 * layout.scale
proc bottom(layout: UiLayout): float32 = layout.origin.y + DEFAULT_HEIGHT.float32 * layout.scale
proc centerX(layout: UiLayout): float32 = layout.origin.x + DEFAULT_WIDTH.float32 * layout.scale * 0.5

proc fontName(layout: UiLayout, role: string): string =
  if layout.scale >= 1.5:
    case role
    of "Display": "DisplayHd"
    of "Body": "BodyHd"
    of "Small": "SmallHd"
    else: role
  else:
    role

proc uiTextSize(sk: Silky, layout: UiLayout, role, text: string): Vec2 =
  sk.getTextSize(layout.fontName(role), text)

proc drawUiText(sk: Silky, layout: UiLayout, role, text: string, pos: Vec2,
                color: ColorRGBX, maxWidth = float32.high,
                maxHeight = float32.high, wordWrap = false): Vec2 =
  sk.drawText(layout.fontName(role), text, snap(pos), color, maxWidth, maxHeight, true, wordWrap)

proc drawCenteredText(sk: Silky, layout: UiLayout, role, text: string,
                      centerX, y: float32, color: ColorRGBX) =
  let size = sk.uiTextSize(layout, role, text)
  discard sk.drawUiText(layout, role, text, vec2(centerX - size.x * 0.5, y), color)

proc drawPanel(sk: Silky, pos, size: Vec2, fill, border: ColorRGBX) =
  let p = snap(pos)
  let s = vec2(round(size.x), round(size.y))
  sk.drawRect(p + vec2(0, 10), s, rgbx(0, 0, 0, 42))
  sk.drawRect(p + vec2(0, 4), s, rgbx(0, 0, 0, 24))
  sk.drawRect(p, s, fill)
  sk.drawRect(p, vec2(s.x, 2), border)
  sk.drawRect(p, vec2(2, s.y), border)
  sk.drawRect(vec2(p.x + s.x - 2, p.y), vec2(2, s.y), border)
  sk.drawRect(vec2(p.x, p.y + s.y - 2), vec2(s.x, 2), border)

proc drawSoftPanel(sk: Silky, pos, size: Vec2, fill, edge: ColorRGBX) =
  let p = snap(pos)
  let s = vec2(round(size.x), round(size.y))
  sk.drawRect(p + vec2(0, 12), s, rgbx(0, 0, 0, 32))
  sk.drawRect(p + vec2(0, 4), s, rgbx(0, 0, 0, 18))
  sk.drawRect(p, s, fill)
  sk.drawRect(p, vec2(s.x, 2), edge)
  sk.drawRect(vec2(p.x, p.y + s.y - 1), vec2(s.x, 1), muted(edge, 110))

proc button(ui: UiRenderer, sk: Silky, window: Window, layout: UiLayout, pos, size: Vec2,
            label, detail, widgetId: string, accent: ColorRGBX,
            selected = false): bool =
  let r = rect(pos.x, pos.y, size.x, size.y)
  let hovered = window.mousePos.vec2.overlaps(r)
  let clicked = hovered and window.buttonPressed[MouseLeft]
  let active = hovered or selected
  let fill =
    if active: rgbx(28, 34, 44, 244)
    else: rgbx(24, 28, 36, 236)

  if hovered:
    ui.noteHot(widgetId, wantsMouse = true, wantsKeyboard = clicked)

  sk.drawSoftPanel(pos, size, fill, muted(accent, if active: 255'u8 else: 210'u8))
  sk.drawRect(pos, vec2(size.x, layout.px(5)), muted(accent, if active: 255'u8 else: 210'u8))

  discard sk.drawUiText(layout, "Body", label, pos + layout.d(18, 16),
                        if active: rgbx(244, 247, 250, 255) else: rgbx(232, 236, 242, 255))
  if detail.len > 0:
    discard sk.drawUiText(layout, "Small", detail, pos + layout.d(18, 46),
                          if active: rgbx(156, 168, 188, 255) else: rgbx(136, 148, 168, 255))
  clicked

proc actionButton(ui: UiRenderer, sk: Silky, window: Window, layout: UiLayout, x, y, w: float32,
                  label, detail, widgetId: string, accent: ColorRGBX): bool =
  button(ui, sk, window, layout, layout.p(x, y), layout.sz(w, 74), label, detail, widgetId, accent)

proc renderBuildStamp(sk: Silky, layout: UiLayout) =
  let
    label = "v" & GameVersion
    size = sk.uiTextSize(layout, "Small", label)
    pos = vec2(layout.left + layout.px(16), layout.bottom - size.y - layout.px(18))
    boxPos = pos - layout.d(10, 8)
    boxSize = vec2(size.x + layout.px(20), size.y + layout.px(16))
  sk.drawPanel(boxPos, boxSize, rgbx(8, 10, 14, 170), rgbx(66, 76, 94, 220))
  discard sk.drawUiText(layout, "Small", label, pos, rgbx(150, 160, 182, 255))

proc renderCharacterStrip(sk: Silky, layout: UiLayout, game: Game) =
  if game.characters.len <= 1:
    return

  let
    slotW = 60.0
    slotH = 48.0
    spacing = 12.0
    totalW = game.characters.len.float32 * slotW +
      max(0, game.characters.len - 1).float32 * spacing
    panelPos = layout.p(DEFAULT_WIDTH.float32 * 0.5 - totalW * 0.5 - 18, DEFAULT_HEIGHT.float32 - 90)
    panelSize = layout.sz(totalW + 36, 68)

  sk.drawPanel(panelPos, panelSize, rgbx(8, 10, 14, 150), rgbx(46, 54, 68, 210))

  for i, ch in game.characters:
    let
      slotX = panelPos.x + layout.px(18 + i.float32 * (slotW + spacing))
      slotPos = vec2(slotX, panelPos.y + layout.px(9))
      color = CHAR_COLORS[ch.colorIndex mod CHAR_COLORS.len]
      tile = rgbx(color.r, color.g, color.b, 255)
      keyText = $(i + 1)
    if i == game.activeCharacterIndex:
      let pulse = (sin(game.elapsedTime.float32 * 5.0) + 1.0) * 0.5
      let activeBorder = bright(rgbx(214, 222, 236, 255), int(pulse * 18.0))
      sk.drawPanel(slotPos - layout.d(4, 4), layout.sz(slotW + 8, slotH + 8),
                   rgbx(16, 18, 24, 120), activeBorder)
    sk.drawPanel(slotPos, layout.sz(slotW, slotH), tile, bright(tile, 24))
    if ch.atExit:
      sk.drawRect(slotPos + layout.d(slotW - 14, 6), layout.sz(8, 8), rgbx(248, 228, 132, 255))
    discard sk.drawUiText(layout, "Small", keyText, slotPos + layout.d(6, -14),
                          rgbx(198, 204, 220, 255))
    let name = ch.characterName()
    drawCenteredText(sk, layout, "Small", name, slotPos.x + layout.px(slotW * 0.5),
                     slotPos.y + layout.px(slotH + 6),
                     tile)

proc renderStatusPanel(sk: Silky, layout: UiLayout, game: Game) =
  if game.characters.len == 0 or
     game.activeCharacterIndex < 0 or
     game.activeCharacterIndex >= game.characters.len:
    return

  let
    active = game.characters[game.activeCharacterIndex]
    base = CHAR_COLORS[active.colorIndex mod CHAR_COLORS.len]
    accent = rgbx(base.r, base.g, base.b, 255)
    border = muted(accent, 220)
    pos = layout.p(18, 16)
    levelText =
      if game.currentLevel >= 0 and game.currentLevel < allLevels.len:
        let level = game.currentLevelState
        &"Level {level.id}: {level.name}"
      else:
        ""
    exitsText = &"{game.exitCount()} / {game.characters.len} exits"
    size = layout.sz(308, if game.characters.len > 1: 88 else: 74)
    progress = if game.characters.len > 0: game.exitCount().float32 / game.characters.len.float32 else: 0.0
    meterPos = pos + layout.d(18, 64)
    meterSize = vec2(size.x - layout.px(44), layout.px(10))
    levelSize = if levelText.len > 0: sk.uiTextSize(layout, "Small", levelText) else: vec2(0, 0)
    exitsSize = sk.uiTextSize(layout, "Small", exitsText)

  sk.drawSoftPanel(pos, size, rgbx(10, 12, 18, 166), border)
  sk.drawRect(pos + layout.d(18, 18), layout.sz(12, 12), accent)
  discard sk.drawUiText(layout, "Body", active.characterName(), pos + layout.d(38, 10), rgbx(244, 247, 250, 255))
  discard sk.drawUiText(layout, "Small", active.characterGift(), pos + layout.d(18, 38),
                        rgbx(156, 166, 184, 255))
  if levelText.len > 0:
    discard sk.drawUiText(layout, "Small", levelText,
                          pos + vec2(size.x - levelSize.x - layout.px(18), layout.px(12)),
                          rgbx(190, 198, 212, 255))
  discard sk.drawUiText(layout, "Small", exitsText,
                        pos + vec2(size.x - exitsSize.x - layout.px(18), layout.px(38)),
                        rgbx(208, 214, 226, 255))
  if game.characters.len > 1:
    sk.drawRect(meterPos, meterSize, rgbx(24, 28, 36, 220))
    sk.drawRect(meterPos, vec2(meterSize.x * progress, meterSize.y), accent)

proc renderGameplayHud(sk: Silky, layout: UiLayout, game: Game) =
  renderStatusPanel(sk, layout, game)
  renderCharacterStrip(sk, layout, game)

  if game.narrationActive or game.narrationRevealed > 0:
    let text = game.narrationText[0..<min(game.narrationRevealed, game.narrationText.len)]
    if text.len > 0:
      let
        maxWidth = min(layout.px(540), layout.right - layout.left - layout.px(80))
        lineCount = max(1, (text.len + 38) div 39)
        boxW = maxWidth
        boxH = layout.px(24 + lineCount.float32 * 18.0)
        bottomInset = if game.characters.len > 1: 122.0 else: 68.0
        boxPos = vec2(layout.centerX - boxW * 0.5, layout.bottom - boxH - layout.px(bottomInset))
      sk.drawSoftPanel(boxPos, vec2(boxW, boxH), rgbx(10, 12, 18, 188), rgbx(74, 84, 102, 190))
      discard sk.drawUiText(layout, "Body", text, boxPos + layout.d(18, 12), rgbx(236, 239, 244, 255),
                            maxWidth = boxW - layout.px(36), maxHeight = boxH - layout.px(24), wordWrap = true)

proc renderCastCard(ui: UiRenderer, sk: Silky, window: Window, layout: UiLayout,
                    x, y: float32, idx: int, name, gift: string) =
  let
    base = CHAR_COLORS[idx mod CHAR_COLORS.len]
    accent = rgbx(base.r, base.g, base.b, 255)
    posBase = layout.p(x, y)
    cardSize = layout.sz(96, 40)
    cardRect = rect(posBase.x, posBase.y, cardSize.x, cardSize.y)
    hovered = window.mousePos.vec2.overlaps(cardRect)
    selected = idx == ui.menuSpotlight
    pos = posBase
    size = cardSize
    fill = if hovered or selected: rgbx(18, 22, 30, 210) else: rgbx(12, 15, 22, 146)
    border =
      if hovered:
        bright(accent, 20)
      elif selected:
        muted(accent, 232)
      else:
        muted(accent, 120)
  if hovered:
    ui.menuSpotlight = idx
    ui.noteHot("cast_" & name)
  discard gift
  sk.drawSoftPanel(pos, size, fill, border)
  sk.drawRect(pos + layout.d(12, 13), layout.sz(14, 14), accent)
  discard sk.drawUiText(layout, "Small", name, pos + layout.d(34, 10),
                        if hovered or selected: rgbx(238, 242, 247, 255) else: rgbx(178, 188, 204, 255))

proc renderMenu(ui: UiRenderer, sk: Silky, window: Window,
                layout: UiLayout, game: var Game) =
  const
    castNames = ["Pip", "Luca", "Bruno", "Cara", "Felix", "Ivy"]
    castRoles = [
      "nimble, precise", "steady runner", "heavy pressure",
      "air control", "late jumps", "extra leap"
    ]
    castGifts = [
      "double jump", "float", "button weight",
      "wall jump", "coyote time", "graceful fall"
    ]
    castHeroLines = [
      "Pip bends momentum into a second chance.",
      "Luca softens space and gives the team time to breathe.",
      "Bruno turns presence into leverage and pressure.",
      "Cara makes verticality feel playful instead of harsh.",
      "Felix rewards patience with a wider landing window.",
      "Ivy keeps the fall elegant and the group composed."
    ]

  let spotlight = max(0, min(ui.menuSpotlight, castNames.len - 1))
  let heroColor = CHAR_COLORS[spotlight mod CHAR_COLORS.len]
  let heroAccent = rgbx(heroColor.r, heroColor.g, heroColor.b, 255)
  let
    heroPos = layout.p(DEFAULT_WIDTH.float32 * 0.5 - 204, 92)
    heroSize = layout.sz(408, 212)
    buttonPos = vec2(heroPos.x + layout.px(42), heroPos.y + heroSize.y - layout.px(86))
    buttonSize = vec2(heroSize.x - layout.px(84), layout.px(58))
    ribbonPos = layout.p(DEFAULT_WIDTH.float32 * 0.5 - 324, DEFAULT_HEIGHT.float32 - 72)
    ribbonSize = layout.sz(648, 52)
    heroCenter = layout.centerX
    tagline = "A quiet platformer about color, cooperation, and timing."
    heroLinePos = vec2(heroPos.x + layout.px(46), heroPos.y + layout.px(128))
    heroLineWidth = heroSize.x - layout.px(92)

  sk.drawSoftPanel(heroPos, heroSize, rgbx(10, 12, 18, 184), muted(heroAccent, 185))
  drawCenteredText(sk, layout, "Display", "TOGETHER", heroCenter, heroPos.y + layout.px(30), rgbx(246, 248, 251, 255))
  drawCenteredText(sk, layout, "Small", tagline,
                   heroCenter, heroPos.y + layout.px(84), rgbx(160, 171, 192, 255))
  sk.drawRect(vec2(heroCenter - layout.px(16), heroPos.y + layout.px(112)), layout.sz(32, 32), heroAccent)
  drawCenteredText(sk, layout, "Body", castNames[spotlight], heroCenter, heroPos.y + layout.px(154),
                   rgbx(242, 245, 248, 255))
  drawCenteredText(sk, layout, "Small", castRoles[spotlight] & " • " & castGifts[spotlight], heroCenter,
                   heroPos.y + layout.px(184), heroAccent)
  discard sk.drawUiText(layout, "Small", castHeroLines[spotlight], heroLinePos,
                        rgbx(220, 226, 236, 255),
                        maxWidth = heroLineWidth, maxHeight = layout.px(36), wordWrap = true)

  if button(ui, sk, window, layout, buttonPos, buttonSize,
            "Begin Journey", "Press Enter or click to start.",
            "begin_journey", rgbx(108, 168, 232, 255), selected = true):
    game.startGame()
    playSound(soundCharSwitch)

  sk.drawSoftPanel(ribbonPos, ribbonSize, rgbx(10, 12, 18, 110), rgbx(52, 62, 82, 120))
  for i in 0 ..< castNames.len:
    let tileX = DEFAULT_WIDTH.float32 * 0.5 - 324 + 12 + i.float32 * 104.0
    renderCastCard(ui, sk, window, layout, tileX, DEFAULT_HEIGHT.float32 - 72 + 6, i,
                   castNames[i], castGifts[i])
  drawCenteredText(sk, layout, "Small", "1-6 or arrow keys preview the cast • Enter begins",
                   heroCenter, layout.bottom - layout.px(28), rgbx(122, 134, 152, 255))

proc renderPauseModal(ui: UiRenderer, sk: Silky, window: Window,
                      layout: UiLayout, game: var Game) =
  let
    pos = layout.p(DEFAULT_WIDTH.float32 * 0.5 - 168, DEFAULT_HEIGHT.float32 * 0.5 - 96)
    size = layout.sz(336, 192)
    levelText =
      if game.currentLevel >= 0 and game.currentLevel < allLevels.len:
        let level = game.currentLevelState
        &"Level {level.id}: {level.name}"
      else:
        "Current room"
    resumePos = layout.p(DEFAULT_WIDTH.float32 * 0.5 - 168 + 34, DEFAULT_HEIGHT.float32 * 0.5 - 96 + 102)
    resumeSize = layout.sz(336 - 68, 54)
    restartPos = layout.p(DEFAULT_WIDTH.float32 * 0.5 - 168 + 34, DEFAULT_HEIGHT.float32 * 0.5 - 96 + 166)
    restartSize = layout.sz(118, 42)
    menuPos = layout.p(DEFAULT_WIDTH.float32 * 0.5 - 168 + 34 + 130, DEFAULT_HEIGHT.float32 * 0.5 - 96 + 166)
    menuSize = layout.sz(336 - 68 - 130, 42)
  sk.drawSoftPanel(pos, size, rgbx(10, 12, 18, 232), rgbx(90, 104, 132, 180))
  discard sk.drawUiText(layout, "Display", "Paused", pos + layout.d(34, 24), rgbx(248, 249, 251, 255))
  discard sk.drawUiText(layout, "Small", levelText, pos + layout.d(36, 72), rgbx(162, 174, 194, 255))
  discard sk.drawUiText(layout, "Small", "Esc resumes • arrows change focus • Enter confirms",
                        pos + layout.d(36, 90), rgbx(134, 146, 166, 255))

  if window.mousePos.vec2.overlaps(rect(resumePos.x, resumePos.y, resumeSize.x, resumeSize.y)):
    ui.pauseSelection = 0
  if window.mousePos.vec2.overlaps(rect(restartPos.x, restartPos.y, restartSize.x, restartSize.y)):
    ui.pauseSelection = 1
  if window.mousePos.vec2.overlaps(rect(menuPos.x, menuPos.y, menuSize.x, menuSize.y)):
    ui.pauseSelection = 2

  if button(ui, sk, window, layout, resumePos, resumeSize,
            "Resume", "Back to the current level.",
            "pause_resume", rgbx(108, 168, 232, 255),
            selected = ui.pauseSelection == 0):
    ui.pauseSelection = 0
    ui.activateFocusedAction(game)

  if button(ui, sk, window, layout, restartPos, restartSize,
            "Restart", "",
            "pause_restart", rgbx(232, 178, 92, 255),
            selected = ui.pauseSelection == 1):
    ui.pauseSelection = 1
    ui.activateFocusedAction(game)

  if button(ui, sk, window, layout, menuPos, menuSize,
            "Menu", "",
            "pause_menu", rgbx(178, 112, 128, 255),
            selected = ui.pauseSelection == 2):
    ui.pauseSelection = 2
    ui.activateFocusedAction(game)

proc renderWinModal(ui: UiRenderer, sk: Silky, window: Window,
                    layout: UiLayout, game: var Game) =
  let
    pos = layout.p(DEFAULT_WIDTH.float32 * 0.5 - 226, DEFAULT_HEIGHT.float32 * 0.5 - 132)
    size = layout.sz(452, 264)
  sk.drawPanel(pos, size, rgbx(12, 14, 18, 220), rgbx(132, 110, 54, 240))
  discard sk.drawUiText(layout, "Display", "Together", pos + layout.d(42, 28), rgbx(248, 232, 178, 255))
  discard sk.drawUiText(layout, "Body", "Everyone made it through.", pos + layout.d(46, 94),
                        rgbx(238, 240, 244, 255))
  discard sk.drawUiText(layout, "Small", "Press Enter or continue to the next room.",
                        pos + layout.d(46, 126), rgbx(160, 170, 186, 255))
  if ui.actionButton(sk, window, layout, DEFAULT_WIDTH.float32 * 0.5 - 226 + 46, DEFAULT_HEIGHT.float32 * 0.5 - 132 + 166, 452 - 92,
                     "Continue", "Advance to the next level.",
                     "win_continue", rgbx(232, 184, 88, 255)):
    game.nextLevel()

proc renderCredits(ui: UiRenderer, sk: Silky, window: Window,
                   layout: UiLayout, game: var Game) =
  let
    pos = layout.p(DEFAULT_WIDTH.float32 * 0.5 - 250, 72)
    size = layout.sz(500, 360)
  sk.drawPanel(pos, size, rgbx(10, 12, 18, 214), rgbx(78, 92, 116, 230))
  discard sk.drawUiText(layout, "Display", "Together", pos + layout.d(48, 28), rgbx(248, 249, 251, 255))
  discard sk.drawUiText(layout, "Body", "They were shapes.", pos + layout.d(52, 104), rgbx(228, 233, 241, 255))
  discard sk.drawUiText(layout, "Body", "They were colors.", pos + layout.d(52, 136), rgbx(228, 233, 241, 255))
  discard sk.drawUiText(layout, "Body", "They were love in geometric form.",
                        pos + layout.d(52, 168), rgbx(228, 233, 241, 255))
  discard sk.drawUiText(layout, "Small", "UI iteration now runs on Windy + Boxy + Silky.",
                        pos + layout.d(52, 230), rgbx(150, 160, 180, 255))
  if ui.actionButton(sk, window, layout, DEFAULT_WIDTH.float32 * 0.5 - 250 + 52, 72 + 276, 500 - 104,
                     "Return to Menu", "Back to the title screen.",
                     "credits_menu", rgbx(108, 168, 232, 255)):
    game.state = menu

proc renderOverlay*(ui: UiRenderer, window: Window, game: var Game,
                    frameSize: IVec2) =
  let layout = initLayout(frameSize)
  let sk = ui.silky
  ui.context = UiContext()
  sk.beginUi(window, frameSize)

  case game.state
  of menu:
    sk.drawRect(vec2(0, 0), vec2(frameSize.x.float32, frameSize.y.float32),
                rgbx(0, 0, 0, 24))
    ui.renderMenu(sk, window, layout, game)
  of playing:
    sk.renderGameplayHud(layout, game)
  of paused:
    sk.drawRect(vec2(0, 0), vec2(frameSize.x.float32, frameSize.y.float32),
                rgbx(0, 0, 0, 136))
    ui.renderPauseModal(sk, window, layout, game)
  of levelWin:
    sk.renderGameplayHud(layout, game)
    sk.drawRect(vec2(0, 0), vec2(frameSize.x.float32, frameSize.y.float32),
                rgbx(4, 4, 6, 72))
    ui.renderWinModal(sk, window, layout, game)
  of credits:
    sk.drawRect(vec2(0, 0), vec2(frameSize.x.float32, frameSize.y.float32),
                rgbx(0, 0, 0, 34))
    ui.renderCredits(sk, window, layout, game)

  sk.renderBuildStamp(layout)
  sk.endUi()
