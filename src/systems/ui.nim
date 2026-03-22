## Silky-driven UI overlay for Together.

import std/[math, strformat, strutils]
import windy
import vmath
import bumpy
import pixie
import chroma
import silky
import "../constants"
import "../build_info"
import "../game"
import "../entities/character"
import "animation"
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

var
  menuTitleAlpha: float = 0.0
  menuCardOffsets: array[6, float]
  menuCardHoverAlphas: array[6, float]
  menuButtonScale: float = 0.0
  menuEntrancePlaying: bool = false
  menuTweenPool: TweenPool = initTweenPool()
  btnScale: float = 1.0
  btnHovered: bool = false
  pauseOverlayAlpha: float = 0.0
  pauseModalY: float = 0.0
  pauseBtn1Alpha: float = 0.0
  pauseBtn2Alpha: float = 0.0
  pauseBtn3Alpha: float = 0.0
  pauseTweenPool: TweenPool = initTweenPool()
  wasPaused: bool = false
  pauseExiting: bool = false
  # HUD contextual elements.
  hudTweenPool: TweenPool = initTweenPool()
  hudCharName: string = ""
  hudCharNameAlpha: float = 0.0
  hudCharNameX: float = -200.0
  hudCharNameTimer: float = 0.0
  hudCharColorIndex: int = 0
  hudCharXTween: int = -1
  hudCharAlphaTween: int = -1
  narrationText: string = ""
  narrationDisplayLen: int = 0
  narrationAlpha: float = 0.0
  narrationTimer: float = 0.0
  narrationAlphaTween: int = -1
  levelLabelAlpha: float = 0.0
  levelLabelTimer: float = 0.0
  levelLabelText: string = ""
  levelLabelAlphaTween: int = -1
  prevActiveCharIdx: int = -1
  prevLevel: int = -1
  prevNarrationText: string = ""

proc triggerMenuEntrance() =
  ## Reset animation state and start the menu entrance sequence.
  menuTitleAlpha = 0.0
  for i in 0..<6:
    menuCardOffsets[i] = 200.0
    menuCardHoverAlphas[i] = 0.0
  menuButtonScale = 0.0
  btnScale = 1.0
  btnHovered = false
  menuEntrancePlaying = true
  menuTweenPool = initTweenPool()

  discard startTween(menuTweenPool, 0.0, 1.0, 0.4, easeOutCubic,
    proc(v: float) = menuTitleAlpha = v)

  for i in 0..<6:
    let idx = i
    discard startTween(menuTweenPool, 200.0, 0.0, 0.5, easeOutCubic,
      proc(v: float) = menuCardOffsets[idx] = v,
      delay = float(idx) * 0.08)

  let buttonDelay = 5.0 * 0.08 + 0.5 + 0.2
  discard startTween(menuTweenPool, 0.0, 1.0, 0.3, easeOutElastic,
    proc(v: float) = menuButtonScale = v,
    delay = buttonDelay)

proc triggerPauseEnter() =
  ## Start the pause menu entrance animation.
  pauseTweenPool = initTweenPool()
  pauseExiting = false
  pauseOverlayAlpha = 0.0
  pauseModalY = -300.0
  pauseBtn1Alpha = 0.0
  pauseBtn2Alpha = 0.0
  pauseBtn3Alpha = 0.0
  discard startTween(pauseTweenPool, 0.0, 0.6, 0.2, easeOutCubic,
    proc(v: float) = pauseOverlayAlpha = v)
  discard startTween(pauseTweenPool, -300.0, 0.0, 0.25, easeOutCubic,
    proc(v: float) = pauseModalY = v)
  discard startTween(pauseTweenPool, 0.0, 1.0, 0.15, easeOutCubic,
    proc(v: float) = pauseBtn1Alpha = v, delay = 0.05)
  discard startTween(pauseTweenPool, 0.0, 1.0, 0.15, easeOutCubic,
    proc(v: float) = pauseBtn2Alpha = v, delay = 0.10)
  discard startTween(pauseTweenPool, 0.0, 1.0, 0.15, easeOutCubic,
    proc(v: float) = pauseBtn3Alpha = v, delay = 0.15)

proc triggerPauseExit() =
  ## Start the pause menu exit animation.
  pauseTweenPool = initTweenPool()
  pauseExiting = true
  pauseBtn1Alpha = 0.0
  pauseBtn2Alpha = 0.0
  pauseBtn3Alpha = 0.0
  discard startTween(pauseTweenPool, pauseOverlayAlpha, 0.0, 0.15, linear,
    proc(v: float) = pauseOverlayAlpha = v)
  discard startTween(pauseTweenPool, pauseModalY, -300.0, 0.15, easeIn,
    proc(v: float) = pauseModalY = v,
    onComplete = proc() = pauseExiting = false)

proc triggerCharInfoStrip(name: string, colorIdx: int) =
  ## Trigger the character info strip slide-in animation.
  hudCharName = name
  hudCharColorIndex = colorIdx
  hudCharNameTimer = 2.0
  if hudCharXTween >= 0: cancelTween(hudTweenPool, hudCharXTween)
  if hudCharAlphaTween >= 0: cancelTween(hudTweenPool, hudCharAlphaTween)
  hudCharXTween = startTween(hudTweenPool, -200.0, 20.0, 0.2, easeOutCubic,
    proc(v: float) = hudCharNameX = v)
  hudCharAlphaTween = startTween(hudTweenPool, 0.0, 1.0, 0.15, easeOutCubic,
    proc(v: float) = hudCharNameAlpha = v)

proc triggerNarrationRibbon(text: string) =
  ## Trigger the narration ribbon typewriter animation.
  narrationText = text
  narrationDisplayLen = 0
  narrationAlpha = 1.0
  narrationTimer = -1.0
  if narrationAlphaTween >= 0:
    cancelTween(hudTweenPool, narrationAlphaTween)
    narrationAlphaTween = -1

proc triggerLevelLabel(text: string) =
  ## Trigger the level indicator fade-in animation.
  levelLabelText = text
  levelLabelTimer = 3.0
  if levelLabelAlphaTween >= 0: cancelTween(hudTweenPool, levelLabelAlphaTween)
  levelLabelAlphaTween = startTween(hudTweenPool, 0.0, 1.0, 0.3, easeOutCubic,
    proc(v: float) = levelLabelAlpha = v)

proc updateHud(dt: float) =
  ## Advance HUD tween pool and manage hold timers.
  updateTweens(hudTweenPool, dt)

  # Character info strip hold and exit.
  if hudCharNameTimer > 0.0:
    hudCharNameTimer -= dt
    if hudCharNameTimer <= 0.0:
      if hudCharXTween >= 0: cancelTween(hudTweenPool, hudCharXTween)
      if hudCharAlphaTween >= 0: cancelTween(hudTweenPool, hudCharAlphaTween)
      hudCharXTween = startTween(hudTweenPool, hudCharNameX, -200.0, 0.2,
        easeOutCubic, proc(v: float) = hudCharNameX = v)
      hudCharAlphaTween = startTween(hudTweenPool, hudCharNameAlpha, 0.0, 0.2,
        easeOutCubic, proc(v: float) = hudCharNameAlpha = v)

  # Narration typewriter and fade.
  if narrationText.len > 0 and narrationAlpha > 0.001:
    if narrationTimer < 0.0:
      narrationDisplayLen = min(narrationDisplayLen + int(40.0 * dt + 0.5),
        narrationText.len)
      if narrationDisplayLen >= narrationText.len:
        narrationTimer = max(2.0, narrationText.len.float / 10.0)
    elif narrationTimer > 0.0:
      narrationTimer -= dt
      if narrationTimer <= 0.0:
        narrationTimer = 0.0
        if narrationAlphaTween >= 0: cancelTween(hudTweenPool, narrationAlphaTween)
        narrationAlphaTween = startTween(hudTweenPool, narrationAlpha, 0.0, 0.3,
          easeOutCubic, proc(v: float) = narrationAlpha = v)

  # Level label hold and exit.
  if levelLabelTimer > 0.0:
    levelLabelTimer -= dt
    if levelLabelTimer <= 0.0:
      if levelLabelAlphaTween >= 0: cancelTween(hudTweenPool, levelLabelAlphaTween)
      levelLabelAlphaTween = startTween(hudTweenPool, levelLabelAlpha, 0.0, 0.5,
        easeOutCubic, proc(v: float) = levelLabelAlpha = v)

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
  let prev = ui.menuSpotlight
  ui.menuSpotlight = (ui.menuSpotlight + delta + count * 4) mod count
  if ui.menuSpotlight != prev:
    playSound(soundMenuHover)

proc cyclePauseSelection*(ui: UiRenderer, delta: int) =
  const count = 4
  let prev = ui.pauseSelection
  ui.pauseSelection = (ui.pauseSelection + delta + count * 4) mod count
  if ui.pauseSelection != prev:
    playSound(soundMenuHover)

proc cycleSettingsCursor*(game: var Game, delta: int) =
  ## Move settings cursor up/down (0=WindowSize, 1=Fullscreen, 2=VSync, 3=Back).
  const count = 4
  let prev = game.settingsCursor
  game.settingsCursor = (game.settingsCursor + delta + count * 4) mod count
  if game.settingsCursor != prev:
    playSound(soundMenuHover)

proc activateFocusedAction*(ui: UiRenderer, game: var Game) =
  case game.state
  of menu:
    game.startGame()
    playSound(soundMenuSelect)
  of paused:
    playSound(soundMenuSelect)
    case ui.pauseSelection
    of 0:
      game.state = playing
    of 1:
      game.restartLevel()
      game.state = playing
    of 2:
      game.state = menu
    of 3:
      game.openSettings()
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

proc renderCharInfoStrip(sk: Silky, layout: UiLayout) =
  ## Draw the transient character name and color swatch strip.
  if hudCharNameAlpha <= 0.001:
    return
  let
    alpha = uint8(clamp(hudCharNameAlpha * 255.0, 0.0, 255.0))
    base = CHAR_COLORS[hudCharColorIndex mod CHAR_COLORS.len]
    accent = rgbx(base.r, base.g, base.b, alpha)
    x = layout.origin.x + layout.px(hudCharNameX.float32)
    y = layout.origin.y + layout.px(30)
    swatchPos = snap(vec2(x, y))
    swatchSize = layout.sz(12, 12)
    textPos = snap(vec2(x + swatchSize.x + layout.px(8), y - layout.px(2)))
  sk.drawRect(swatchPos, swatchSize, accent)
  discard sk.drawUiText(layout, "Body", hudCharName, textPos,
                        rgbx(244, 247, 250, alpha))

proc renderNarrationRibbon(sk: Silky, layout: UiLayout, game: Game) =
  ## Draw the narration ribbon with typewriter reveal.
  if narrationAlpha <= 0.001 or narrationText.len == 0 or narrationDisplayLen <= 0:
    return
  let
    displayText = narrationText[0..<min(narrationDisplayLen, narrationText.len)]
    alpha = uint8(clamp(narrationAlpha * 255.0, 0.0, 255.0))
    maxWidth = min(layout.px(540), layout.right - layout.left - layout.px(80))
    lineCount = max(1, (displayText.len + 38) div 39)
    boxW = maxWidth
    boxH = layout.px(24 + lineCount.float32 * 18.0)
    bottomInset = if game.characters.len > 1: 122.0 else: 68.0
    boxPos = vec2(layout.centerX - boxW * 0.5,
      layout.bottom - boxH - layout.px(bottomInset))
    panelFill = rgbx(10, 12, 18,
      uint8(clamp(188.0 * narrationAlpha, 0.0, 255.0)))
    panelEdge = rgbx(74, 84, 102,
      uint8(clamp(190.0 * narrationAlpha, 0.0, 255.0)))
  sk.drawSoftPanel(boxPos, vec2(boxW, boxH), panelFill, panelEdge)
  discard sk.drawUiText(layout, "Body", displayText,
                        boxPos + layout.d(18, 12), rgbx(236, 239, 244, alpha),
                        maxWidth = boxW - layout.px(36),
                        maxHeight = boxH - layout.px(24), wordWrap = true)

proc renderLevelLabel(sk: Silky, layout: UiLayout) =
  ## Draw the transient level indicator at top-center.
  if levelLabelAlpha <= 0.001 or levelLabelText.len == 0:
    return
  let alpha = uint8(clamp(levelLabelAlpha * 255.0, 0.0, 255.0))
  drawCenteredText(sk, layout, "Display", levelLabelText, layout.centerX,
                   layout.origin.y + layout.px(40),
                   rgbx(248, 249, 251, alpha))

proc renderGameplayHud(sk: Silky, layout: UiLayout, game: Game) =
  renderStatusPanel(sk, layout, game)
  renderCharacterStrip(sk, layout, game)
  renderNarrationRibbon(sk, layout, game)
  renderCharInfoStrip(sk, layout)
  renderLevelLabel(sk, layout)

proc renderCastCard(ui: UiRenderer, sk: Silky, window: Window, layout: UiLayout,
                    x, y: float32, idx: int, name, gift: string,
                    time, dt: float) =
  let
    base = CHAR_COLORS[idx mod CHAR_COLORS.len]
    selected = idx == ui.menuSpotlight

    # Color brightness pulse via HSL.
    chromaBase = chroma.color(
      base.r.float32 / 255.0,
      base.g.float32 / 255.0,
      base.b.float32 / 255.0)
    hslBase = chromaBase.hsl
    pulsedL = clamp(
      hslBase.l + sin(time + float(idx) * 0.33).float32 * 10.0,
      0.0'f32, 100.0'f32)
    pulsedColor = hsl(hslBase.h, hslBase.s, pulsedL).color
    accent = rgbx(
      clamp(pulsedColor.r * 255.0, 0.0, 255.0).uint8,
      clamp(pulsedColor.g * 255.0, 0.0, 255.0).uint8,
      clamp(pulsedColor.b * 255.0, 0.0, 255.0).uint8,
      255'u8)

    # Scale breathing — disabled for selected card.
    breathe =
      if selected: 1.0'f32
      else: 1.0'f32 + 0.02'f32 * sin(
        time.float32 * PI.float32 / 2.0'f32 + idx.float32 * 0.33'f32)

    posBase = layout.p(x, y)
    baseSize = layout.sz(96, 40)
    scaledW = baseSize.x * breathe
    scaledH = baseSize.y * breathe
    pos = snap(vec2(
      posBase.x + (baseSize.x - scaledW) * 0.5,
      posBase.y + (baseSize.y - scaledH) * 0.5))
    size = vec2(scaledW, scaledH)
    cardRect = rect(pos.x, pos.y, size.x, size.y)
    hovered = window.mousePos.vec2.overlaps(cardRect)
    fill = if hovered or selected: rgbx(18, 22, 30, 210) else: rgbx(12, 15, 22, 146)
    border =
      if hovered: bright(accent, 20)
      elif selected: muted(accent, 232)
      else: muted(accent, 120)

  # Hover alpha ramp.
  if hovered or selected:
    menuCardHoverAlphas[idx] = min(menuCardHoverAlphas[idx] + dt / 0.15, 1.0)
  else:
    menuCardHoverAlphas[idx] = max(menuCardHoverAlphas[idx] - dt / 0.15, 0.0)

  if hovered:
    ui.menuSpotlight = idx
    ui.noteHot("cast_" & name)

  # Glow ring.
  let glowAlpha = menuCardHoverAlphas[idx]
  if glowAlpha > 0.0:
    let
      glowA =
        if selected: uint8(40.0 * glowAlpha)
        else: uint8(30.0 * glowAlpha)
      glowColor = rgbx(accent.r, accent.g, accent.b, glowA)
      glowPos = vec2(pos.x - layout.px(4), pos.y - layout.px(4))
      glowSize = vec2(size.x + layout.px(8), size.y + layout.px(8))
    sk.drawRect(glowPos, glowSize, glowColor)

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
  let titleAlpha = clamp(menuTitleAlpha * 255.0, 0.0, 255.0).uint8
  drawCenteredText(sk, layout, "Display", "TOGETHER", heroCenter, heroPos.y + layout.px(30), rgbx(246, 248, 251, titleAlpha))
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

  let
    combinedScale = menuButtonScale.float32 * btnScale.float32
    scaledBtnW = buttonSize.x * combinedScale
    scaledBtnH = buttonSize.y * combinedScale
    scaledBtnPos = vec2(
      buttonPos.x + (buttonSize.x - scaledBtnW) * 0.5,
      buttonPos.y + (buttonSize.y - scaledBtnH) * 0.5)
    scaledBtnSize = vec2(scaledBtnW, scaledBtnH)

  # Idle glow halo.
  if combinedScale > 0.0:
    let
      glowA = uint8(20 + 15 * sin(game.elapsedTime * PI))
      glowColor = rgbx(108, 168, 232, glowA)
      glowExpand = layout.px(8)
      glowPos = vec2(scaledBtnPos.x - glowExpand, scaledBtnPos.y - glowExpand)
      glowSize = vec2(scaledBtnW + glowExpand * 2, scaledBtnH + glowExpand * 2)
    sk.drawRect(glowPos, glowSize, glowColor)

  # Hover detection for tween triggers.
  let btnRect = rect(scaledBtnPos.x, scaledBtnPos.y, scaledBtnW, scaledBtnH)
  let hoveredNow = window.mousePos.vec2.overlaps(btnRect) and combinedScale > 0.0
  if hoveredNow and not btnHovered:
    discard startTween(menuTweenPool, btnScale, 1.05, 0.15, easeIn,
      proc(v: float) = btnScale = v)
  elif not hoveredNow and btnHovered:
    discard startTween(menuTweenPool, btnScale, 1.0, 0.15, easeOutCubic,
      proc(v: float) = btnScale = v)
  btnHovered = hoveredNow

  if button(ui, sk, window, layout, scaledBtnPos, scaledBtnSize,
            "Begin Journey", "Press Enter or click to start.",
            "begin_journey", rgbx(108, 168, 232, 255), selected = true):
    # Press bounce: squash down then elastic bounce back.
    discard startTween(menuTweenPool, 1.0, 0.95, 0.05, linear,
      proc(v: float) = btnScale = v,
      onComplete = proc() =
        discard startTween(menuTweenPool, 0.95, 1.0, 0.2, easeOutElastic,
          proc(v: float) = btnScale = v))
    game.startGame()
    playSound(soundMenuSelect)

  sk.drawSoftPanel(ribbonPos, ribbonSize, rgbx(10, 12, 18, 110), rgbx(52, 62, 82, 120))
  for i in 0 ..< castNames.len:
    let tileX = DEFAULT_WIDTH.float32 * 0.5 - 324 + 12 + i.float32 * 104.0
    let tileY = DEFAULT_HEIGHT.float32 - 72 + 6 + menuCardOffsets[i].float32
    renderCastCard(ui, sk, window, layout, tileX, tileY, i,
                   castNames[i], castGifts[i],
                   game.elapsedTime, game.deltaTime)
  # Settings link at bottom-right.
  let settingsLabel = "Settings"
  let settingsTextSize = sk.uiTextSize(layout, "Small", settingsLabel)
  let settingsLinkPos = vec2(layout.right - settingsTextSize.x - layout.px(20),
                             layout.bottom - settingsTextSize.y - layout.px(18))
  let settingsLinkRect = rect(settingsLinkPos.x - layout.px(6),
                              settingsLinkPos.y - layout.px(4),
                              settingsTextSize.x + layout.px(12),
                              settingsTextSize.y + layout.px(8))
  let settingsHovered = window.mousePos.vec2.overlaps(settingsLinkRect)
  let settingsColor = if settingsHovered: rgbx(220, 226, 236, 255)
                      else: rgbx(150, 160, 182, 255)
  discard sk.drawUiText(layout, "Small", settingsLabel, settingsLinkPos, settingsColor)
  if settingsHovered and window.buttonPressed[MouseLeft]:
    game.openSettings()
    playSound(soundMenuSelect)

  drawCenteredText(sk, layout, "Small", "1-6 or arrow keys preview the cast • Enter begins",
                   heroCenter, layout.bottom - layout.px(28), rgbx(122, 134, 152, 255))

proc renderPauseModal(ui: UiRenderer, sk: Silky, window: Window,
                      layout: UiLayout, game: var Game) =
  let
    baseX = DEFAULT_WIDTH.float32 * 0.5 - 168
    baseY = DEFAULT_HEIGHT.float32 * 0.5 - 116 + pauseModalY
    pos = layout.p(baseX, baseY)
    size = layout.sz(336, 240)
    levelText =
      if game.currentLevel >= 0 and game.currentLevel < allLevels.len:
        let level = game.currentLevelState
        &"Level {level.id}: {level.name}"
      else:
        "Current room"
    resumePos = layout.p(baseX + 34, baseY + 102)
    resumeSize = layout.sz(336 - 68, 54)
    restartPos = layout.p(baseX + 34, baseY + 166)
    restartSize = layout.sz(118, 42)
    menuPos = layout.p(baseX + 34 + 130, baseY + 166)
    menuSize = layout.sz(336 - 68 - 130, 42)
    settingsPos = layout.p(baseX + 34, baseY + 218)
    settingsSize = layout.sz(336 - 68, 42)
  sk.drawSoftPanel(pos, size, rgbx(10, 12, 18, 232), rgbx(90, 104, 132, 180))
  discard sk.drawUiText(layout, "Display", "Paused", pos + layout.d(34, 24), rgbx(248, 249, 251, 255))
  discard sk.drawUiText(layout, "Small", levelText, pos + layout.d(36, 72), rgbx(162, 174, 194, 255))
  discard sk.drawUiText(layout, "Small", "Esc resumes • arrows change focus • Enter confirms",
                        pos + layout.d(36, 90), rgbx(134, 146, 166, 255))

  if pauseBtn1Alpha > 0.01:
    if window.mousePos.vec2.overlaps(rect(resumePos.x, resumePos.y, resumeSize.x, resumeSize.y)):
      ui.pauseSelection = 0
    if button(ui, sk, window, layout, resumePos, resumeSize,
              "Resume", "Back to the current level.",
              "pause_resume", muted(rgbx(108, 168, 232, 255), uint8(pauseBtn1Alpha * 255)),
              selected = ui.pauseSelection == 0):
      ui.pauseSelection = 0
      ui.activateFocusedAction(game)

  if pauseBtn2Alpha > 0.01:
    if window.mousePos.vec2.overlaps(rect(restartPos.x, restartPos.y, restartSize.x, restartSize.y)):
      ui.pauseSelection = 1
    if button(ui, sk, window, layout, restartPos, restartSize,
              "Restart", "",
              "pause_restart", muted(rgbx(232, 178, 92, 255), uint8(pauseBtn2Alpha * 255)),
              selected = ui.pauseSelection == 1):
      ui.pauseSelection = 1
      ui.activateFocusedAction(game)

  if pauseBtn3Alpha > 0.01:
    if window.mousePos.vec2.overlaps(rect(menuPos.x, menuPos.y, menuSize.x, menuSize.y)):
      ui.pauseSelection = 2
    if button(ui, sk, window, layout, menuPos, menuSize,
              "Menu", "",
              "pause_menu", muted(rgbx(178, 112, 128, 255), uint8(pauseBtn3Alpha * 255)),
              selected = ui.pauseSelection == 2):
      ui.pauseSelection = 2
      ui.activateFocusedAction(game)

  if pauseBtn3Alpha > 0.01:
    if window.mousePos.vec2.overlaps(rect(settingsPos.x, settingsPos.y, settingsSize.x, settingsSize.y)):
      ui.pauseSelection = 3
    if button(ui, sk, window, layout, settingsPos, settingsSize,
              "Settings", "",
              "pause_settings", muted(rgbx(160, 160, 180, 255), uint8(pauseBtn3Alpha * 255)),
              selected = ui.pauseSelection == 3):
      ui.pauseSelection = 3
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

proc renderSettings(ui: UiRenderer, sk: Silky, window: Window,
                     layout: UiLayout, game: var Game) =
  ## Render the settings screen with option rows and Back button.
  let
    panelW = 420.0'f32
    panelH = 280.0'f32
    baseX = DEFAULT_WIDTH.float32 * 0.5 - panelW * 0.5
    baseY = DEFAULT_HEIGHT.float32 * 0.5 - panelH * 0.5
    pos = layout.p(baseX, baseY)
    size = layout.sz(panelW, panelH)

  # Dark background overlay.
  sk.drawRect(vec2(0, 0), vec2(layout.frameSize.x.float32, layout.frameSize.y.float32),
              rgbx(0, 0, 0, 180))

  sk.drawSoftPanel(pos, size, rgbx(10, 12, 18, 232), rgbx(90, 104, 132, 180))
  drawCenteredText(sk, layout, "Display", "Settings", layout.centerX,
                   pos.y + layout.px(24), rgbx(248, 249, 251, 255))

  # Option rows.
  let rowStartY = baseY + 80
  let rowH = 38.0'f32
  let labelX = baseX + 40
  let valueX = baseX + panelW - 40

  for i in 0 ..< 3:
    let rowY = rowStartY + i.float32 * rowH
    let focused = game.settingsCursor == i
    let textAlpha: uint8 = if focused: 255 else: 180
    let textColor = rgbx(244, 247, 250, textAlpha)
    let valueColor = rgbx(180, 196, 220, textAlpha)

    # Highlight bar for focused row.
    if focused:
      sk.drawRect(layout.p(baseX + 20, rowY - 4),
                  layout.sz(panelW - 40, rowH),
                  rgbx(40, 48, 64, 160))

    let label = case i
      of 0: "Window Size"
      of 1: "Fullscreen"
      of 2: "VSync"
      else: ""

    let value = case i
      of 0:
        let preset = WindowPresets[game.settingsWindowPreset]
        $preset.w & " x " & $preset.h
      of 1:
        if game.fullscreenEnabled: "On" else: "Off"
      of 2:
        if game.vsyncEnabled: "On" else: "Off"
      else: ""

    discard sk.drawUiText(layout, "Body", label,
                          layout.p(labelX, rowY), textColor)
    let valSize = sk.uiTextSize(layout, "Body", value)
    discard sk.drawUiText(layout, "Body", value,
                          layout.p(valueX, rowY) - vec2(valSize.x, 0),
                          valueColor)

    # Arrow hints for focused row.
    if focused:
      let arrowColor = rgbx(140, 155, 180, 200)
      let leftArrowPos = layout.p(valueX, rowY) - vec2(valSize.x + layout.px(20), 0)
      let rightArrowPos = layout.p(valueX, rowY) + vec2(layout.px(8), 0)
      discard sk.drawUiText(layout, "Body", "<", leftArrowPos, arrowColor)
      discard sk.drawUiText(layout, "Body", ">", rightArrowPos, arrowColor)

  # Back button.
  let backY = rowStartY + 3.0 * rowH + 10
  let focused = game.settingsCursor == 3
  let backColor = if focused: rgbx(244, 247, 250, 255) else: rgbx(180, 196, 220, 180)
  if focused:
    sk.drawRect(layout.p(baseX + 20, backY - 4),
                layout.sz(panelW - 40, rowH),
                rgbx(40, 48, 64, 160))
  drawCenteredText(sk, layout, "Body", "Back", layout.centerX,
                   layout.p(0, backY).y, backColor)

  # Mouse interaction for rows.
  for i in 0 ..< 4:
    let rowY = if i < 3: rowStartY + i.float32 * rowH
               else: rowStartY + 3.0 * rowH + 10
    let rowRect = rect(layout.p(baseX + 20, rowY - 4).x,
                       layout.p(baseX + 20, rowY - 4).y,
                       layout.px(panelW - 40),
                       layout.px(rowH))
    if window.mousePos.vec2.overlaps(rowRect):
      if game.settingsCursor != i:
        game.settingsCursor = i
        playSound(soundMenuHover)

proc renderOverlay*(ui: UiRenderer, window: Window, game: var Game,
                    frameSize: IVec2) =
  let layout = initLayout(frameSize)
  let sk = ui.silky
  ui.context = UiContext()
  sk.beginUi(window, frameSize)

  let inMenu = game.state == menu
  if inMenu and not menuEntrancePlaying:
    triggerMenuEntrance()
  if not inMenu:
    menuEntrancePlaying = false
  if inMenu:
    updateTweens(menuTweenPool, game.deltaTime)

  # Detect pause state transitions.
  let nowPaused = game.state == paused
  if nowPaused and not wasPaused:
    triggerPauseEnter()
  elif not nowPaused and wasPaused:
    triggerPauseExit()
  wasPaused = nowPaused

  if nowPaused or pauseExiting:
    updateTweens(pauseTweenPool, game.deltaTime)

  # HUD event detection.
  let currentCharIdx = game.activeCharacterIndex
  if currentCharIdx != prevActiveCharIdx and prevActiveCharIdx >= 0 and
     currentCharIdx >= 0 and currentCharIdx < game.characters.len:
    let ch = game.characters[currentCharIdx]
    triggerCharInfoStrip(ch.characterName(), ch.colorIndex)
  prevActiveCharIdx = currentCharIdx

  if game.currentLevel != prevLevel and
     game.currentLevel >= 0 and game.currentLevel < allLevels.len:
    let level = game.currentLevelState
    triggerLevelLabel(&"Level {level.id} — {level.name}")
  prevLevel = game.currentLevel

  if game.narrationText != prevNarrationText and game.narrationText.len > 0:
    triggerNarrationRibbon(game.narrationText)
  prevNarrationText = game.narrationText

  updateHud(game.deltaTime)

  case game.state
  of menu:
    sk.drawRect(vec2(0, 0), vec2(frameSize.x.float32, frameSize.y.float32),
                rgbx(0, 0, 0, 24))
    ui.renderMenu(sk, window, layout, game)
  of playing:
    sk.renderGameplayHud(layout, game)
  of paused:
    let overlayA = uint8(pauseOverlayAlpha * 255)
    sk.drawRect(vec2(0, 0), vec2(frameSize.x.float32, frameSize.y.float32),
                rgbx(0, 0, 0, overlayA))
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
  of actTitle:
    discard
  of settings:
    ui.renderSettings(sk, window, layout, game)

  # Render pause exit animation overlay even after state leaves paused.
  if pauseExiting and not nowPaused and pauseOverlayAlpha > 0.001:
    let overlayA = uint8(pauseOverlayAlpha * 255)
    sk.drawRect(vec2(0, 0), vec2(frameSize.x.float32, frameSize.y.float32),
                rgbx(0, 0, 0, overlayA))
    ui.renderPauseModal(sk, window, layout, game)

  sk.renderBuildStamp(layout)
  sk.endUi()
