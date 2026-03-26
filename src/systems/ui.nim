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
import "save"
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
  menuCursor: int = 0
  menuBtnAlphas: array[5, float]
  menuHasSave: bool = false
  progressStripAlpha: float = 0.0
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
  # Card breathing phase offsets (staggered per card).
  cardPhases: array[6, float]
  # Menu button polish state.
  firstLaunch: bool = true
  warmthFlashAlpha: float = 0.0
  slideIndicatorY: float = -1.0

const
  # Level index (0-based) at which each cast member unlocks.
  CharUnlockLevels: array[6, int] = [0, 4, 5, 7, 10, 11]
  # Character ID to color index mapping.
  CharColorMap: array[6, string] = ["pip", "luca", "bruno", "cara", "felix", "ivy"]
  CardHoverQuotes: array[6, string] = ["What's up there?", "I was just... floating.",
    "I'll hold this.", "Watch me.", "...no rush.", "Gently, now."]

proc charColorIndex(id: string): int =
  ## Return the color index for a character ID string.
  for i, name in CharColorMap:
    if name == id:
      return i
  0

proc cardIdleOffset(charIndex: int, t: float): Vec2 =
  ## Per-character positional idle micro-animation.
  let phase = float(charIndex) * 0.8
  case charIndex
  of 0: vec2(0.0, sin(t * 4.0 + phase) * 3.0)                        # Pip: rapid small vertical bounces.
  of 1: vec2(sin(t * 1.2 + phase) * 4.0, 0.0)                        # Luca: slow left-right sway.
  of 2: vec2(0.0, 0.0)                                                 # Bruno: scale only.
  of 3: vec2(0.0, -abs(sin(t * 2.5 + phase)) * 3.0)                   # Cara: quick upward dart.
  of 4: vec2(sin(t * 0.5 + phase) * 2.0, 0.0)                        # Felix: very slow drift.
  of 5: vec2(sin(t * 1.0 + phase) * 3.5, 0.0)                        # Ivy: graceful sine sway.
  else: vec2(0.0, 0.0)

proc cardIdleScale(charIndex: int, t: float): float =
  ## Per-character scale idle micro-animation.
  let phase = float(charIndex) * 0.8
  case charIndex
  of 2: 1.0 + sin(t * 0.8 + phase) * 0.015                           # Bruno: slow settle pulse.
  of 5: 1.0 - sin(t * 1.0 + phase) * 0.008                           # Ivy: slight counter-scale.
  else: 1.0

proc isCharLocked(idx: int): bool =
  ## Return true when a cast member has not yet been encountered.
  ## Pip (idx 0) is always unlocked.
  if idx == 0: return false
  not levelCompleted(CharUnlockLevels[idx])

proc triggerMenuEntrance() =
  ## Reset animation state and start the menu entrance sequence.
  menuTitleAlpha = 0.0
  for i in 0..<6:
    menuCardOffsets[i] = 200.0
    menuCardHoverAlphas[i] = 0.0
    cardPhases[i] = float(i) * PI / 3.0
  menuButtonScale = 0.0
  btnScale = 1.0
  btnHovered = false
  menuEntrancePlaying = true
  menuTweenPool = initTweenPool()
  menuCursor = 0
  menuHasSave = hasSaveProgress()
  if menuHasSave:
    firstLaunch = false
  slideIndicatorY = -1.0
  progressStripAlpha = 0.0
  for i in 0..<5:
    menuBtnAlphas[i] = 1.0  # Buttons visible immediately.

  discard startTween(menuTweenPool, 0.0, 1.0, 0.6, easeOutCubic,
    proc(v: float) = menuTitleAlpha = v)

  for i in 0..<6:
    let idx = i
    discard startTween(menuTweenPool, 200.0, 0.0, 0.5, easeOutCubic,
      proc(v: float) = menuCardOffsets[idx] = v,
      delay = float(idx) * 0.08)

  # Progress strip fades in after a short delay.
  progressStripAlpha = 1.0

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
  ## Cycle the cast spotlight, skipping locked characters.
  const count = 6
  let prev = ui.menuSpotlight
  var next = (ui.menuSpotlight + delta + count * 4) mod count
  # Skip locked characters (wrap at most count times to avoid infinite loop).
  for _ in 0 ..< count:
    if not isCharLocked(next):
      break
    next = (next + delta + count * 4) mod count
  ui.menuSpotlight = next
  if ui.menuSpotlight != prev:
    playMenuHoverNote(ui.menuSpotlight)

proc cycleMenuCursor*(delta: int) =
  ## Move the main menu cursor up or down among the 5 buttons.
  const count = 5
  let prev = menuCursor
  menuCursor = (menuCursor + delta + count * 4) mod count
  if menuCursor != prev:
    playMenuHoverNote(menuCursor)

proc cyclePauseSelection*(ui: UiRenderer, delta: int) =
  const count = 5
  let prev = ui.pauseSelection
  ui.pauseSelection = (ui.pauseSelection + delta + count * 4) mod count
  if ui.pauseSelection != prev:
    playMenuHoverNote(ui.pauseSelection)

proc cycleSettingsCursor*(game: var Game, delta: int) =
  ## Move settings cursor up/down (0=WindowSize, 1=Fullscreen, 2=VSync, 3=Volume, 4=Back).
  const count = 5
  let prev = game.settingsCursor
  game.settingsCursor = (game.settingsCursor + delta + count * 4) mod count
  if game.settingsCursor != prev:
    playMenuHoverNote(game.settingsCursor)

proc activateFocusedAction*(ui: UiRenderer, game: var Game) =
  case game.state
  of menu:
    playSound(soundMenuSelect)
    warmthFlashAlpha = 1.0
    case menuCursor
    of 0:
      firstLaunch = false
      game.startGame()
    of 1:
      if menuHasSave:
        game.continueGame()
    of 2: game.state = levelSelect
    of 3: game.openSettings()
    of 4: game.state = credits
    else: discard
  of paused:
    playSound(soundMenuSelect)
    warmthFlashAlpha = 1.0
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
    of 4:
      game.state = levelSelect
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
  sk.drawRect(pos, vec2(size.x, layout.px(3)), muted(accent, if active: 255'u8 else: 210'u8))

  if detail.len > 0:
    discard sk.drawUiText(layout, "Body", label, pos + layout.d(18, 8),
                          if active: rgbx(244, 247, 250, 255) else: rgbx(232, 236, 242, 255))
    discard sk.drawUiText(layout, "Small", detail, pos + layout.d(18, 28),
                          if active: rgbx(156, 168, 188, 255) else: rgbx(136, 148, 168, 255))
  else:
    # Center label vertically in button when no detail text.
    let labelSize = sk.uiTextSize(layout, "Body", label)
    let labelY = (size.y - labelSize.y) * 0.5
    discard sk.drawUiText(layout, "Body", label, pos + vec2(layout.px(18), labelY),
                          if active: rgbx(244, 247, 250, 255) else: rgbx(232, 236, 242, 255))
  clicked

proc actionButton(ui: UiRenderer, sk: Silky, window: Window, layout: UiLayout, x, y, w: float32,
                  label, detail, widgetId: string, accent: ColorRGBX): bool =
  button(ui, sk, window, layout, layout.p(x, y), layout.sz(w, 56), label, detail, widgetId, accent)

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

proc renderThoughtBubble(sk: Silky, layout: UiLayout, game: Game) =
  ## Draw thought bubble above the thinking character.
  let alpha = game.thoughtBubbleAlpha()
  if alpha <= 0.001 or game.thoughtBubble.text.len == 0:
    return
  let idx = game.thoughtBubble.charIdx
  if idx < 0 or idx >= game.characters.len:
    return
  let ch = game.characters[idx]
  let camX = game.camera.x + game.camera.shakeOffsetX
  let camY = game.camera.y + game.camera.shakeOffsetY
  let screenX = (ch.x + float(ch.width) * 0.5 - camX).float32
  let screenY = (ch.drawY() - 10.0 - camY).float32
  let sx = layout.origin.x + screenX * layout.scale
  let sy = layout.origin.y + screenY * layout.scale
  let textSize = sk.uiTextSize(layout, "Small", game.thoughtBubble.text)
  let padX = layout.px(8)
  let padY = layout.px(4)
  let boxW = textSize.x + padX * 2
  let boxH = textSize.y + padY * 2
  let boxX = sx - boxW * 0.5
  let boxY = sy - boxH
  let a = uint8(clamp(alpha * 255.0, 0.0, 255.0))
  let bgA = uint8(clamp(alpha * 180.0, 0.0, 180.0))
  sk.drawRect(snap(vec2(boxX, boxY)), vec2(round(boxW), round(boxH)),
              rgbx(12, 14, 20, bgA))
  discard sk.drawUiText(layout, "Small", game.thoughtBubble.text,
                        snap(vec2(boxX + padX, boxY + padY)),
                        rgbx(230, 234, 240, a))

proc renderGameplayHud(sk: Silky, layout: UiLayout, game: Game) =
  renderStatusPanel(sk, layout, game)
  renderCharacterStrip(sk, layout, game)
  renderNarrationRibbon(sk, layout, game)
  renderCharInfoStrip(sk, layout)
  renderLevelLabel(sk, layout)
  renderThoughtBubble(sk, layout, game)

proc renderCastCard(ui: UiRenderer, sk: Silky, window: Window, layout: UiLayout,
                    x, y: float32, idx: int, name, gift: string,
                    time, dt, menuTime: float) =
  let
    base = CHAR_COLORS[idx mod CHAR_COLORS.len]
    selected = idx == ui.menuSpotlight

    # Color brightness pulse ±10% using chroma lighten/darken.
    chromaBase = chroma.color(
      base.r.float32 / 255.0,
      base.g.float32 / 255.0,
      base.b.float32 / 255.0)
    pulse = sin(menuTime * PI + idx.float * 0.9) * 0.1
    pulsedColor = if pulse > 0: lighten(chromaBase, pulse)
                  else: darken(chromaBase, -pulse)
    accent = rgbx(
      clamp(pulsedColor.r * 255.0, 0.0, 255.0).uint8,
      clamp(pulsedColor.g * 255.0, 0.0, 255.0).uint8,
      clamp(pulsedColor.b * 255.0, 0.0, 255.0).uint8,
      255'u8)

    # Scale breathing — 2s sine cycle, disabled for selected and locked cards.
    locked = isCharLocked(idx)
    breathe =
      if selected or locked: 1.0'f32
      else: 1.0'f32 + 0.02'f32 * sin(
        time.float32 * PI.float32 + cardPhases[idx].float32)

    posBase = layout.p(x, y)
    baseSize = layout.sz(96, 40)
    scaledW = baseSize.x * breathe
    scaledH = baseSize.y * breathe

    # Per-character idle micro-animation offsets and scale (disabled when selected or locked).
    idleOff =
      if selected or locked: vec2(0.0, 0.0)
      else: cardIdleOffset(idx, menuTime)
    idleScl =
      if selected or locked: 1.0'f32
      else: cardIdleScale(idx, menuTime).float32
    finalW = scaledW * idleScl
    finalH = scaledH * idleScl

    pos = snap(vec2(
      posBase.x + (baseSize.x - finalW) * 0.5 + idleOff.x.float32,
      posBase.y + (baseSize.y - finalH) * 0.5 + idleOff.y.float32))
    size = vec2(finalW, finalH)
    cardRect = rect(pos.x, pos.y, size.x, size.y)
    hovered = window.mousePos.vec2.overlaps(cardRect)

  if locked:
    # Dimmed card for locked characters — still shows name and color hint.
    let
      silFill = rgbx(18, 22, 30, 200)
      silBorder = muted(accent, 80)
    sk.drawSoftPanel(pos, size, silFill, silBorder)
    sk.drawRect(pos + layout.d(12, 13), layout.sz(14, 14), muted(accent, 60))
    discard sk.drawUiText(layout, "Small", name, pos + layout.d(34, 10),
                          rgbx(100, 108, 124, 255))
    return

  let
    fill = if hovered or selected: rgbx(18, 22, 30, 210) else: rgbx(12, 15, 22, 146)
    border =
      if hovered: bright(accent, 20)
      elif selected: muted(accent, 232)
      else: muted(accent, 120)

  # Hover alpha ramp.
  if hovered or selected:
    menuCardHoverAlphas[idx] = min(menuCardHoverAlphas[idx] + dt / 0.1, 1.0)
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

  sk.drawSoftPanel(pos, size, fill, border)
  sk.drawRect(pos + layout.d(12, 13), layout.sz(14, 14), accent)
  discard sk.drawUiText(layout, "Small", name, pos + layout.d(34, 10),
                        if hovered or selected: rgbx(238, 242, 247, 255) else: rgbx(178, 188, 204, 255))

  # Felix (idx 4): thin white blink bar at top 20% of card, every ~3s.
  if idx == 4 and not selected:
    let
      blinkCycle = menuTime.float32 mod 3.0'f32
      blinkT = blinkCycle - 2.6'f32
    if blinkT >= 0.0 and blinkT <= 0.4:
      let blinkAlpha = sin(blinkT / 0.4'f32 * PI.float32) * 0.3
      sk.drawRect(
        vec2(pos.x + layout.px(4), pos.y + size.y * 0.1),
        vec2(size.x - layout.px(8), layout.px(2)),
        rgbx(255, 255, 255, uint8(blinkAlpha * 255.0)))

  # Hover personality quote and ability name above card.
  if hovered or selected:
    let quoteAlpha = menuCardHoverAlphas[idx]
    drawCenteredText(sk, layout, "Small", gift,
                     pos.x + size.x * 0.5, pos.y - layout.px(22),
                     rgbx(accent.r, accent.g, accent.b, uint8(180.0 * quoteAlpha)))
    drawCenteredText(sk, layout, "Small", CardHoverQuotes[idx],
                     pos.x + size.x * 0.5, pos.y - layout.px(10),
                     rgbx(220, 226, 236, uint8(200.0 * quoteAlpha)))

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
    heroPos = layout.p(DEFAULT_WIDTH.float32 * 0.5 - 204, 20)
    heroSize = layout.sz(408, 160)
    ribbonPos = layout.p(80, DEFAULT_HEIGHT.float32 - 82)
    ribbonSize = layout.sz(640, 58)
    heroCenter = layout.centerX
    tagline = "A quiet platformer about color, cooperation, and timing."
    heroLinePos = vec2(heroPos.x + layout.px(46), heroPos.y + layout.px(126))
    heroLineWidth = heroSize.x - layout.px(92)

  sk.drawSoftPanel(heroPos, heroSize, rgbx(10, 12, 18, 230), muted(heroAccent, 185))
  let titleAlpha = clamp(menuTitleAlpha * 255.0, 0.0, 255.0).uint8

  # Title text with dark drop shadow.
  let
    titleText = "TOGETHER"
    titleY = heroPos.y + layout.px(18)
    titleSize = sk.uiTextSize(layout, "Display", titleText)
    titleX = heroCenter - titleSize.x * 0.5
    shadowAlpha = uint8(float(titleAlpha) * 0.25)

  # Drop shadow at (2, 3) px offset.
  drawCenteredText(sk, layout, "Display", titleText,
                   heroCenter + layout.px(2), titleY + layout.px(3),
                   rgbx(0, 0, 0, shadowAlpha))
  # White title on top.
  drawCenteredText(sk, layout, "Display", titleText, heroCenter, titleY, rgbx(246, 248, 251, titleAlpha))
  drawCenteredText(sk, layout, "Small", tagline,
                   heroCenter, heroPos.y + layout.px(50), rgbx(160, 171, 192, 255))
  sk.drawRect(vec2(heroCenter - layout.px(8), heroPos.y + layout.px(70)), layout.sz(16, 16), heroAccent)
  drawCenteredText(sk, layout, "Body", castNames[spotlight], heroCenter, heroPos.y + layout.px(92),
                   rgbx(242, 245, 248, 255))
  drawCenteredText(sk, layout, "Small", castRoles[spotlight] & " • " & castGifts[spotlight], heroCenter,
                   heroPos.y + layout.px(112), heroAccent)
  discard sk.drawUiText(layout, "Small", castHeroLines[spotlight], heroLinePos,
                        rgbx(220, 226, 236, 255),
                        maxWidth = heroLineWidth, maxHeight = layout.px(28), wordWrap = true)

  # 5-button vertical menu below hero panel.
  const
    MenuLabels = ["New Game", "Continue", "Level Select", "Settings", "Credits"]
    MenuAccents: array[5, ColorRGBX] = [
      rgbx(108, 168, 232, 255),
      rgbx(232, 184, 88, 255),
      rgbx(168, 200, 140, 255),
      rgbx(160, 160, 180, 255),
      rgbx(140, 152, 172, 255),
    ]
  let
    menuBtnW = 260.0'f32
    menuBtnH = 36.0'f32
    menuBtnGap = 6.0'f32
    menuColumnX = DEFAULT_WIDTH.float32 * 0.5 - menuBtnW * 0.5
    menuColumnY = 200.0'f32

  # Sliding indicator lerp toward focused button Y.
  let targetIndicatorY = layout.p(0, menuColumnY + menuCursor.float32 * (menuBtnH + menuBtnGap)).y
  if slideIndicatorY < 0.0:
    slideIndicatorY = targetIndicatorY
  else:
    slideIndicatorY = slideIndicatorY + (targetIndicatorY - slideIndicatorY) * min(1.0, game.deltaTime * 12.0)

  # Warmth flash decay.
  if warmthFlashAlpha > 0.0:
    warmthFlashAlpha = max(0.0, warmthFlashAlpha - game.deltaTime * 10.0)

  for i in 0..<5:
    let alpha = menuBtnAlphas[i]
    if alpha < 0.01:
      continue
    let
      bx = menuColumnX
      by = menuColumnY + i.float32 * (menuBtnH + menuBtnGap)
      pos = layout.p(bx, by)
      size = layout.sz(menuBtnW, menuBtnH)
      focused = menuCursor == i
      dimmed = i == 1 and not menuHasSave
      accent = MenuAccents[i]
      textAlpha = uint8(alpha * (if dimmed: 100.0 else: 255.0))
      accentMuted = rgbx(accent.r, accent.g, accent.b, textAlpha)
      fill = if focused and not dimmed: rgbx(28, 34, 44, uint8(alpha * 244.0))
             else: rgbx(20, 24, 32, uint8(alpha * 200.0))
      edgeAlpha = uint8(alpha * (if focused and not dimmed: 255.0 else: 140.0))
      edge = rgbx(accent.r, accent.g, accent.b, edgeAlpha)
      btnRect = rect(pos.x, pos.y, size.x, size.y)
      hovered = window.mousePos.vec2.overlaps(btnRect)

    if hovered and not dimmed:
      menuCursor = i

    # Focused button glow halo.
    if focused and not dimmed:
      let
        glowA = uint8((0.08 + 0.04 * sin(game.menuTime * 2.0)) * 255.0)
        glowPad = layout.px(4)
        glowPos = vec2(pos.x - glowPad, pos.y - glowPad)
        glowSize = vec2(size.x + glowPad * 2, size.y + glowPad * 2)
      sk.drawRect(glowPos, glowSize, rgbx(255, 255, 255, glowA))

    # "New Game" beckoning glow (first launch only).
    if i == 0 and firstLaunch:
      let
        beckonA = uint8((0.06 + 0.04 * sin(game.menuTime * 3.0)) * 255.0)
        beckonPad = layout.px(6)
        beckonPos = vec2(pos.x - beckonPad, pos.y - beckonPad)
        beckonSize = vec2(size.x + beckonPad * 2, size.y + beckonPad * 2)
      sk.drawRect(beckonPos, beckonSize, rgbx(accent.r, accent.g, accent.b, beckonA))

    sk.drawSoftPanel(pos, size, fill, edge)

    let labelColor = if dimmed: rgbx(120, 130, 148, textAlpha)
                     elif focused: rgbx(244, 247, 250, textAlpha)
                     else: rgbx(200, 208, 222, textAlpha)
    drawCenteredText(sk, layout, "Body", MenuLabels[i], layout.centerX,
                     pos.y + layout.px(8), labelColor)

    # Continue progress indicator: act-colored block strip.
    if i == 1 and menuHasSave and progressStripAlpha > 0.01:
      let
        sa = progressStripAlpha
        cellSz = layout.px(8)
        cellGap = layout.px(2)
        actGap = layout.px(6)
      # Total width: 30 cells (6 per act × 5 acts).
      var totalW: float32 = 0
      for ai, act in Acts:
        let count = act.endLevel - act.startLevel + 1
        totalW += count.float32 * cellSz + max(0, count - 1).float32 * cellGap
        if ai < Acts.len - 1:
          totalW += actGap
      let
        cellStartX = layout.centerX - totalW * 0.5
        cellY = pos.y + size.y + layout.px(5)
      var cx = cellStartX
      for ai, act in Acts:
        let
          tc = act.themeColor
          count = act.endLevel - act.startLevel + 1
          chromaTc = chroma.color(tc.r.float32 / 255.0,
                                  tc.g.float32 / 255.0,
                                  tc.b.float32 / 255.0)
          darkTc = chroma.darken(chromaTc, 0.4)
        for li in 0 ..< count:
          let levelIdx = act.startLevel - 1 + li
          if levelCompleted(levelIdx):
            # Filled: act color, full alpha.
            sk.drawRect(vec2(cx, cellY), vec2(cellSz, cellSz),
                        rgbx(tc.r, tc.g, tc.b, uint8(sa * 255.0)))
          elif levelAvailable(levelIdx):
            # Outlined: act color border, transparent fill.
            let borderC = rgbx(tc.r, tc.g, tc.b, uint8(sa * 220.0))
            sk.drawRect(vec2(cx, cellY), vec2(cellSz, 1), borderC)
            sk.drawRect(vec2(cx, cellY + cellSz - 1), vec2(cellSz, 1), borderC)
            sk.drawRect(vec2(cx, cellY), vec2(1, cellSz), borderC)
            sk.drawRect(vec2(cx + cellSz - 1, cellY), vec2(1, cellSz), borderC)
          else:
            # Locked: darkened act color at 25% alpha.
            let dr = uint8(darkTc.r * 255.0)
            let dg = uint8(darkTc.g * 255.0)
            let db = uint8(darkTc.b * 255.0)
            sk.drawRect(vec2(cx, cellY), vec2(cellSz, cellSz),
                        rgbx(dr, dg, db, uint8(sa * 64.0)))
          cx += cellSz + cellGap
        cx += actGap - cellGap

      # Character silhouettes for the saved party.
      let contLevel = savedContinueLevel()
      if contLevel >= 0 and contLevel < allLevels.len:
        let
          partyChars = allLevels[contLevel].characters
          silW = layout.px(6)
          silH = layout.px(6)
          silGap = layout.px(3)
          silTotalW = partyChars.len.float32 * silW + max(0, partyChars.len - 1).float32 * silGap
          silStartX = layout.centerX - silTotalW * 0.5
          silY = pos.y + size.y + layout.px(16)
        for ci, charId in partyChars:
          let
            cIdx = charColorIndex(charId)
            cColor = CHAR_COLORS[cIdx mod CHAR_COLORS.len]
            silColor = rgbx(cColor.r, cColor.g, cColor.b, uint8(alpha * 220.0))
            silX = silStartX + ci.float32 * (silW + silGap)
          sk.drawRect(vec2(silX, silY), vec2(silW, silH), silColor)

    if hovered and not dimmed and window.buttonPressed[MouseLeft]:
      menuCursor = i
      ui.activateFocusedAction(game)

  # Sliding selection indicator (thin accent bar on left edge).
  let
    indicatorAccent = MenuAccents[menuCursor]
    indicatorH = layout.px(menuBtnH)
    indicatorW = layout.px(3)
    indicatorX = layout.p(menuColumnX, 0).x - indicatorW - layout.px(4)
  sk.drawRect(vec2(indicatorX, slideIndicatorY), vec2(indicatorW, indicatorH), indicatorAccent)

  # Screen-wide warmth flash.
  if warmthFlashAlpha > 0.01:
    let flashA = uint8(warmthFlashAlpha * 28.0)
    sk.drawRect(vec2(0, 0), vec2(layout.frameSize.x.float32, layout.frameSize.y.float32),
                rgbx(255, 240, 220, flashA))

  sk.drawSoftPanel(ribbonPos, ribbonSize, rgbx(10, 12, 18, 110), rgbx(52, 62, 82, 120))
  for i in 0 ..< castNames.len:
    # 6 cards × 96px wide + 5 gaps × 8px = 616px total. Center in 800px → start at 92.
    let tileX = 92.0 + i.float32 * 104.0
    let tileY = DEFAULT_HEIGHT.float32 - 82 + 10 + menuCardOffsets[i].float32
    renderCastCard(ui, sk, window, layout, tileX, tileY, i,
                   castNames[i], castGifts[i],
                   game.elapsedTime, game.deltaTime, game.menuTime)

  drawCenteredText(sk, layout, "Small", "Up/Down selects • Enter confirms • 1-6 preview cast",
                   heroCenter, layout.bottom - layout.px(18), rgbx(122, 134, 152, 255))

proc renderPauseModal(ui: UiRenderer, sk: Silky, window: Window,
                      layout: UiLayout, game: var Game) =
  let
    panelW = 320.0'f32
    panelH = 280.0'f32
    baseX = DEFAULT_WIDTH.float32 * 0.5 - panelW * 0.5
    baseY = DEFAULT_HEIGHT.float32 * 0.5 - panelH * 0.5 + pauseModalY
    pos = layout.p(baseX, baseY)
    size = layout.sz(panelW, panelH)
    levelText =
      if game.currentLevel >= 0 and game.currentLevel < allLevels.len:
        let level = game.currentLevelState
        &"Level {level.id}: {level.name}"
      else:
        "Current room"
    insetX = 28.0'f32
    btnW = panelW - insetX * 2
    halfBtnW = (btnW - 10) * 0.5
    resumePos = layout.p(baseX + insetX, baseY + 100)
    resumeSize = layout.sz(btnW, 46)
    restartPos = layout.p(baseX + insetX, baseY + 158)
    restartSize = layout.sz(halfBtnW, 38)
    menuPos = layout.p(baseX + insetX + halfBtnW + 10, baseY + 158)
    menuSize = layout.sz(halfBtnW, 38)
    settingsPos = layout.p(baseX + insetX, baseY + 208)
    settingsSize = layout.sz(halfBtnW, 38)
    levelsPos = layout.p(baseX + insetX + halfBtnW + 10, baseY + 208)
    levelsSize = layout.sz(halfBtnW, 38)
  sk.drawSoftPanel(pos, size, rgbx(10, 12, 18, 232), rgbx(90, 104, 132, 180))
  discard sk.drawUiText(layout, "Display", "Paused", pos + layout.d(insetX + 6, 22), rgbx(248, 249, 251, 255))
  discard sk.drawUiText(layout, "Small", levelText, pos + layout.d(insetX + 8, 62), rgbx(162, 174, 194, 255))
  discard sk.drawUiText(layout, "Small", "Esc resumes • arrows change focus • Enter confirms",
                        pos + layout.d(insetX + 8, 80), rgbx(134, 146, 166, 255))

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

  if pauseBtn3Alpha > 0.01:
    if window.mousePos.vec2.overlaps(rect(levelsPos.x, levelsPos.y, levelsSize.x, levelsSize.y)):
      ui.pauseSelection = 4
    if button(ui, sk, window, layout, levelsPos, levelsSize,
              "Levels", "",
              "pause_levels", muted(rgbx(140, 180, 160, 255), uint8(pauseBtn3Alpha * 255)),
              selected = ui.pauseSelection == 4):
      ui.pauseSelection = 4
      ui.activateFocusedAction(game)

proc renderWinModal(ui: UiRenderer, sk: Silky, window: Window,
                    layout: UiLayout, game: var Game) =
  let
    winW = 400.0'f32
    winH = 220.0'f32
    winX = DEFAULT_WIDTH.float32 * 0.5 - winW * 0.5
    winY = DEFAULT_HEIGHT.float32 * 0.5 - winH * 0.5
    pos = layout.p(winX, winY)
    size = layout.sz(winW, winH)
  sk.drawPanel(pos, size, rgbx(12, 14, 18, 220), rgbx(132, 110, 54, 240))
  drawCenteredText(sk, layout, "Display", "Together", layout.centerX,
                   pos.y + layout.px(24), rgbx(248, 232, 178, 255))
  drawCenteredText(sk, layout, "Body", "Everyone made it through.", layout.centerX,
                   pos.y + layout.px(72), rgbx(238, 240, 244, 255))
  drawCenteredText(sk, layout, "Small", "Press Enter or continue to the next room.",
                   layout.centerX, pos.y + layout.px(100), rgbx(160, 170, 186, 255))
  if ui.actionButton(sk, window, layout, winX + 40, winY + 136, winW - 80,
                     "Continue", "Advance to the next level.",
                     "win_continue", rgbx(232, 184, 88, 255)):
    game.nextLevel()

proc renderCredits(ui: UiRenderer, sk: Silky, window: Window,
                   layout: UiLayout, game: var Game) =
  let
    credW = 440.0'f32
    credH = 340.0'f32
    credX = DEFAULT_WIDTH.float32 * 0.5 - credW * 0.5
    credY = DEFAULT_HEIGHT.float32 * 0.5 - credH * 0.5
    pos = layout.p(credX, credY)
    size = layout.sz(credW, credH)
  sk.drawPanel(pos, size, rgbx(10, 12, 18, 214), rgbx(78, 92, 116, 230))
  drawCenteredText(sk, layout, "Display", "Together", layout.centerX,
                   pos.y + layout.px(24), rgbx(248, 249, 251, 255))
  drawCenteredText(sk, layout, "Body", "They were shapes.", layout.centerX,
                   pos.y + layout.px(80), rgbx(228, 233, 241, 255))
  drawCenteredText(sk, layout, "Body", "They were colors.", layout.centerX,
                   pos.y + layout.px(108), rgbx(228, 233, 241, 255))
  drawCenteredText(sk, layout, "Body", "They were love in geometric form.",
                   layout.centerX, pos.y + layout.px(136), rgbx(228, 233, 241, 255))
  drawCenteredText(sk, layout, "Small", "UI iteration now runs on Windy + Boxy + Silky.",
                   layout.centerX, pos.y + layout.px(190), rgbx(150, 160, 180, 255))
  if ui.actionButton(sk, window, layout, credX + 46, credY + 230, credW - 92,
                     "Return to Menu", "Back to the title screen.",
                     "credits_menu", rgbx(108, 168, 232, 255)):
    game.state = menu

proc renderSettings(ui: UiRenderer, sk: Silky, window: Window,
                     layout: UiLayout, game: var Game) =
  ## Render the settings screen with option rows and Back button.
  let
    panelW = 380.0'f32
    panelH = 290.0'f32
    baseX = DEFAULT_WIDTH.float32 * 0.5 - panelW * 0.5
    baseY = DEFAULT_HEIGHT.float32 * 0.5 - panelH * 0.5
    pos = layout.p(baseX, baseY)
    size = layout.sz(panelW, panelH)

  # Dark background overlay.
  sk.drawRect(vec2(0, 0), vec2(layout.frameSize.x.float32, layout.frameSize.y.float32),
              rgbx(0, 0, 0, 180))

  sk.drawSoftPanel(pos, size, rgbx(10, 12, 18, 232), rgbx(90, 104, 132, 180))
  drawCenteredText(sk, layout, "Display", "Settings", layout.centerX,
                   pos.y + layout.px(22), rgbx(248, 249, 251, 255))

  # Option rows — consistent spacing with vertically centered text.
  let rowStartY = baseY + 68
  let rowH = 36.0'f32
  let rowInset = 24.0'f32
  let labelX = baseX + rowInset + 12
  let valueRightEdge = baseX + panelW - rowInset - 12

  for i in 0 ..< 4:
    let rowY = rowStartY + i.float32 * rowH
    let focused = game.settingsCursor == i
    let textAlpha: uint8 = if focused: 255 else: 180
    let textColor = rgbx(244, 247, 250, textAlpha)
    let valueColor = rgbx(180, 196, 220, textAlpha)

    # Highlight bar for focused row.
    if focused:
      sk.drawRect(layout.p(baseX + rowInset, rowY),
                  layout.sz(panelW - rowInset * 2, rowH),
                  rgbx(40, 48, 64, 160))

    let label = case i
      of 0: "Window Size"
      of 1: "Fullscreen"
      of 2: "VSync"
      of 3: "Volume"
      else: ""

    let value = case i
      of 0:
        let preset = WindowPresets[game.settingsWindowPreset]
        $preset.w & " x " & $preset.h
      of 1:
        if game.fullscreenEnabled: "On" else: "Off"
      of 2:
        if game.vsyncEnabled: "On" else: "Off"
      of 3:
        $int(getMasterVolume() * 100) & "%"
      else: ""

    # Vertically center text within the row.
    let textYOffset = rowY + (rowH - 16) * 0.5
    discard sk.drawUiText(layout, "Body", label,
                          layout.p(labelX, textYOffset), textColor)
    let valSize = sk.uiTextSize(layout, "Body", value)
    let valPos = layout.p(valueRightEdge, textYOffset) - vec2(valSize.x, 0)
    discard sk.drawUiText(layout, "Body", value, valPos, valueColor)

    # Arrow hints for focused row.
    if focused:
      let arrowColor = rgbx(140, 155, 180, 200)
      discard sk.drawUiText(layout, "Body", "<",
                            valPos - vec2(layout.px(18), 0), arrowColor)
      discard sk.drawUiText(layout, "Body", ">",
                            valPos + vec2(valSize.x + layout.px(8), 0), arrowColor)

  # Back button.
  let backY = rowStartY + 4.0 * rowH + 16
  let backFocused = game.settingsCursor == 4
  let backColor = if backFocused: rgbx(244, 247, 250, 255) else: rgbx(180, 196, 220, 180)
  if backFocused:
    sk.drawRect(layout.p(baseX + rowInset, backY),
                layout.sz(panelW - rowInset * 2, rowH),
                rgbx(40, 48, 64, 160))
  drawCenteredText(sk, layout, "Body", "Back", layout.centerX,
                   layout.p(0, backY + (rowH - 16) * 0.5).y, backColor)

  # Mouse interaction for rows.
  for i in 0 ..< 5:
    let rowY = if i < 4: rowStartY + i.float32 * rowH
               else: rowStartY + 4.0 * rowH + 16
    let rowRect = rect(layout.p(baseX + rowInset, rowY).x,
                       layout.p(baseX + rowInset, rowY).y,
                       layout.px(panelW - rowInset * 2),
                       layout.px(rowH))
    if window.mousePos.vec2.overlaps(rowRect):
      if game.settingsCursor != i:
        game.settingsCursor = i
        playMenuHoverNote(i)

proc renderLevelSelect(ui: UiRenderer, sk: Silky, window: Window,
                       layout: UiLayout, game: var Game) =
  ## Render the level select screen: 5 act rows, each with 6 level cells.
  const
    LevelsPerAct = 6
    CellW = 80.0'f32
    CellH = 50.0'f32
    CellGap = 8.0'f32
    RowGap = 12.0'f32
    ActLabelW = 100.0'f32

  let
    gridW = LevelsPerAct.float32 * CellW + (LevelsPerAct - 1).float32 * CellGap
    totalW = ActLabelW + gridW
    startX = DEFAULT_WIDTH.float32 * 0.5 - totalW * 0.5
    startY = 80.0'f32

  # Title.
  drawCenteredText(sk, layout, "Title", "Level Select", layout.centerX,
                   layout.p(0, 24).y, rgbx(230, 236, 244, 255))

  # Back hint.
  drawCenteredText(sk, layout, "Small", "Esc to return",
                   layout.centerX,
                   layout.bottom - layout.px(18), rgbx(122, 134, 152, 255))

  for ai in 0..<Acts.len:
    let
      act = Acts[ai]
      tc = act.themeColor
      rowY = startY + ai.float32 * (CellH + RowGap)

    # Act label.
    let
      labelPos = layout.p(startX, rowY + CellH * 0.5 - 10)
      actLabel = "Act " & $act.number
      labelColor = rgbx(tc.r, tc.g, tc.b, 220)
    discard sk.drawUiText(layout, "Body", actLabel, labelPos, labelColor)

    # Act name below label.
    let
      namePos = layout.p(startX, rowY + CellH * 0.5 + 4)
      nameColor = rgbx(tc.r, tc.g, tc.b, 140)
    discard sk.drawUiText(layout, "Small", act.name, namePos, nameColor)

    # Level cells.
    for li in 0..<LevelsPerAct:
      let
        levelIdx = act.startLevel - 1 + li
        cellX = startX + ActLabelW + li.float32 * (CellW + CellGap)
        cellPos = layout.p(cellX, rowY)
        cellSize = layout.sz(CellW, CellH)
        completed = levelCompleted(levelIdx)
        available = levelAvailable(levelIdx)
        locked = not completed and not available
        fill = if completed: rgbx(tc.r, tc.g, tc.b, 200)
               elif available: rgbx(tc.r, tc.g, tc.b, 40)
               else: rgbx(60, 64, 72, 200)
        edge = if completed: rgbx(tc.r, tc.g, tc.b, 180)
               elif available: rgbx(tc.r, tc.g, tc.b, 160)
               else: rgbx(60, 64, 72, 120)

      sk.drawSoftPanel(cellPos, cellSize, fill, edge)

      # Level number (hidden for locked cells).
      if not locked:
        let
          levelNum = $(levelIdx + 1)
          textColor = if completed: rgbx(240, 244, 250, 255)
                      else: rgbx(tc.r, tc.g, tc.b, 220)
        drawCenteredText(sk, layout, "Body", levelNum,
                         cellPos.x + cellSize.x * 0.5,
                         cellPos.y + layout.px(10), textColor)

      # Completion indicator.
      if completed:
        let checkPos = vec2(cellPos.x + cellSize.x * 0.5 - layout.px(4),
                            cellPos.y + cellSize.y - layout.px(14))
        let checkSize = vec2(layout.px(8), layout.px(3))
        sk.drawRect(checkPos, checkSize, rgbx(180, 255, 180, 200))

      # Cursor highlight.
      if ai == game.levelSelectRow and li == game.levelSelectCol:
        let bw = layout.px(2)
        # Top edge.
        sk.drawRect(cellPos, vec2(cellSize.x, bw), rgbx(255, 255, 255, 220))
        # Bottom edge.
        sk.drawRect(vec2(cellPos.x, cellPos.y + cellSize.y - bw),
                     vec2(cellSize.x, bw), rgbx(255, 255, 255, 220))
        # Left edge.
        sk.drawRect(cellPos, vec2(bw, cellSize.y), rgbx(255, 255, 255, 220))
        # Right edge.
        sk.drawRect(vec2(cellPos.x + cellSize.x - bw, cellPos.y),
                     vec2(bw, cellSize.y), rgbx(255, 255, 255, 220))

        # Rejection flash overlay.
        if game.levelSelectRejectTimer > 0:
          let flashAlpha = uint8(game.levelSelectRejectTimer / 0.25 * 180)
          sk.drawRect(cellPos, cellSize, rgbx(255, 60, 60, flashAlpha))

proc renderWonScreen(ui: UiRenderer, sk: Silky, window: Window,
                     layout: UiLayout, game: var Game) =
  ## End-game celebration screen after completing level 30.
  let
    t = game.wonTimer
    panelW = 520.0'f32
    panelH = 380.0'f32
    panelX = DEFAULT_WIDTH.float32 * 0.5 - panelW * 0.5
    panelY = DEFAULT_HEIGHT.float32 * 0.5 - panelH * 0.5
    pos = layout.p(panelX, panelY)
    size = layout.sz(panelW, panelH)
    baseY = pos.y + layout.px(16)

  sk.drawPanel(pos, size, rgbx(10, 12, 18, 230), rgbx(132, 110, 54, 240))

  # Character swatches with animated bounce and color glows.
  let swatchSize = layout.px(28)
  let swatchGap = layout.px(12)
  let totalSwatchW = 6.0 * swatchSize + 5.0 * swatchGap
  let swatchStartX = layout.centerX - totalSwatchW * 0.5
  let swatchY = baseY + layout.px(10)

  for i in 0 ..< 6:
    let color = CHAR_COLORS[i]
    let bounce = sin(t * 2.5 + float(i) * 0.8) * layout.px(4)
    let sx = swatchStartX + float32(i) * (swatchSize + swatchGap)
    let sy = swatchY + bounce.float32

    # Glow halo behind character swatch.
    let glowPad = layout.px(6)
    let glowA = uint8(clamp(80.0 + sin(t * 1.8 + float(i) * 1.2) * 40.0, 40.0, 120.0))
    sk.drawRect(vec2(sx - glowPad, sy - glowPad),
                vec2(swatchSize + glowPad * 2, swatchSize + glowPad * 2),
                rgbx(color.r, color.g, color.b, glowA))

    # Character swatch.
    sk.drawRect(vec2(sx, sy), vec2(swatchSize, swatchSize),
                rgbx(color.r, color.g, color.b, 255))

  # "TOGETHER" title with 6-color glow halos.
  let titleText = "TOGETHER"
  let titleY = baseY + layout.px(58)
  let titleSize = sk.uiTextSize(layout, "Display", titleText)
  let titleX = layout.centerX - titleSize.x * 0.5

  for i in 0 ..< 6:
    let haloColor = CHAR_COLORS[i]
    let haloA = uint8(clamp(20.0 + sin(t * 1.5 + float(i) * 1.05) * 12.0, 8.0, 32.0))
    let offset = float32(i - 3) * layout.px(3)
    sk.drawRect(vec2(titleX + offset - layout.px(4), titleY - layout.px(4)),
                vec2(titleSize.x + layout.px(8), titleSize.y + layout.px(8)),
                rgbx(haloColor.r, haloColor.g, haloColor.b, haloA))

  drawCenteredText(sk, layout, "Display", titleText, layout.centerX, titleY,
                   rgbx(248, 232, 178, 255))

  # Stats summary — fades in at 2s.
  let statsAlpha = clamp((t - 2.0) * 2.0, 0.0, 1.0)
  if statsAlpha > 0.0:
    let sa = uint8(statsAlpha * 255)
    let statsY = baseY + layout.px(110)
    let minutes = int(game.wonTotalTime) div 60
    let seconds = int(game.wonTotalTime) mod 60
    let statsText = &"Levels: {game.wonLevelsCompleted}    Deaths: {game.totalDeaths}    Time: {minutes}m {seconds}s"
    drawCenteredText(sk, layout, "Body", statsText, layout.centerX, statsY,
                     rgbx(200, 210, 228, sa))

  # "Thank you for playing" — fades in at 5s or on first key press.
  if game.wonThankYouShown:
    let ta = if game.wonTimer >= 5.0:
      uint8(clamp((game.wonTimer - 5.0) * 2.0, 0.0, 1.0) * 255)
    else:
      uint8(255)
    let thankY = baseY + layout.px(150)
    drawCenteredText(sk, layout, "Body", "Thank you for playing.", layout.centerX,
                     thankY, rgbx(200, 210, 228, ta))

  # Continue button — only after thank-you is shown.
  if game.wonThankYouShown:
    if ui.actionButton(sk, window, layout, panelX + 40, panelY + panelH - 80,
                       panelW - 80, "Continue", "Return to main menu.",
                       "won_continue", rgbx(232, 184, 88, 255)):
      game.state = menu

proc renderStoryBeat(sk: Silky, layout: UiLayout, game: Game) =
  ## Render the story-beat screen: black background, centered narration, prompt.
  sk.drawRect(vec2(0, 0), vec2(layout.frameSize.x.float32, layout.frameSize.y.float32),
              rgbx(0, 0, 0, 255))
  if game.storyBeatRevealed > 0:
    let displayText = game.storyBeatText[0..<min(game.storyBeatRevealed, game.storyBeatText.len)]
    let textY = layout.frameSize.y.float32 * 0.33
    let maxW = DEFAULT_WIDTH.float32 * layout.scale * 0.7
    let textX = layout.centerX - maxW * 0.5
    discard sk.drawUiText(layout, "Body", displayText, vec2(textX, textY),
                          rgbx(228, 233, 241, 255), maxW, wordWrap = true)
  if game.storyBeatRevealed >= game.storyBeatText.len:
    let promptAlpha = uint8(clamp((game.storyBeatTimer - 0.5) * 2.0 * 255.0, 0.0, 255.0))
    drawCenteredText(sk, layout, "Small", "Press Space to continue",
                     layout.centerX, layout.frameSize.y.float32 * 0.75,
                     rgbx(150, 160, 180, promptAlpha))

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
    if game.currentLevel == FinalLevel and game.finalePhase >= 2:
      # Dark overlay for finale narration.
      sk.drawRect(vec2(0, 0), vec2(frameSize.x.float32, frameSize.y.float32),
                  rgbx(0, 0, 0, 180))
      if game.finaleNarrationRevealed > 0:
        let displayText = FinaleNarrationText[0..<min(game.finaleNarrationRevealed, FinaleNarrationText.len)]
        let textY = layout.frameSize.y.float32 * 0.33
        let maxW = DEFAULT_WIDTH.float32 * layout.scale * 0.7
        let textX = layout.centerX - maxW * 0.5
        discard sk.drawUiText(layout, "Body", displayText, vec2(textX, textY),
                              rgbx(228, 233, 241, 255), maxW, wordWrap = true)
    else:
      ui.renderWinModal(sk, window, layout, game)
  of credits:
    sk.drawRect(vec2(0, 0), vec2(frameSize.x.float32, frameSize.y.float32),
                rgbx(0, 0, 0, 34))
    ui.renderCredits(sk, window, layout, game)
  of actTitle:
    discard
  of storyBeat:
    sk.renderStoryBeat(layout, game)
  of settings:
    ui.renderSettings(sk, window, layout, game)
  of levelSelect:
    sk.drawRect(vec2(0, 0), vec2(frameSize.x.float32, frameSize.y.float32),
                rgbx(0, 0, 0, 24))
    ui.renderLevelSelect(sk, window, layout, game)
  of won:
    sk.drawRect(vec2(0, 0), vec2(frameSize.x.float32, frameSize.y.float32),
                rgbx(0, 0, 0, 34))
    ui.renderWonScreen(sk, window, layout, game)

  # Render pause exit animation overlay even after state leaves paused.
  if pauseExiting and not nowPaused and pauseOverlayAlpha > 0.001:
    let overlayA = uint8(pauseOverlayAlpha * 255)
    sk.drawRect(vec2(0, 0), vec2(frameSize.x.float32, frameSize.y.float32),
                rgbx(0, 0, 0, overlayA))
    ui.renderPauseModal(sk, window, layout, game)

  sk.renderBuildStamp(layout)
  sk.endUi()
