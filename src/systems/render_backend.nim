## Boxy-backed rendering adapter used by the game renderer.

import boxy
import chroma
import bumpy
import vmath
import "../constants"

type
  BlendMode* = enum
    BlendMode_None, BlendMode_Blend, BlendMode_Add

  RendererPtr* = ref object
    boxy*: Boxy
    currentColor: chroma.Color
    frameWidth*: int
    frameHeight*: int
    canvasScale: float32
    canvasOrigin: Vec2
    blendMode*: BlendMode
    layerActive: bool
    canvasTransformActive: bool

proc toChromaColor(r, g, b: uint8, a: uint8 = 255'u8): chroma.Color =
  chroma.color(
    r.float32 / 255.0,
    g.float32 / 255.0,
    b.float32 / 255.0,
    a.float32 / 255.0
  )

proc newRenderer*(): RendererPtr =
  RendererPtr(
    boxy: newBoxy(),
    currentColor: toChromaColor(255, 255, 255),
    frameWidth: DEFAULT_WIDTH,
    frameHeight: DEFAULT_HEIGHT,
    canvasScale: 1.0,
    canvasOrigin: vec2(0, 0),
    blendMode: BlendMode_None,
    layerActive: false,
    canvasTransformActive: false,
  )

proc closeBlendLayer(renderer: RendererPtr) =
  if not renderer.layerActive:
    return

  let blend = case renderer.blendMode
    of BlendMode_Add: boxy.ScreenBlend
    else: boxy.NormalBlend

  renderer.boxy.popLayer(blendMode = blend)
  renderer.layerActive = false

proc beginFrame*(renderer: RendererPtr, drawableWidth, drawableHeight: int) =
  renderer.frameWidth = drawableWidth
  renderer.frameHeight = drawableHeight
  renderer.canvasScale = min(
    drawableWidth.float32 / DEFAULT_WIDTH.float32,
    drawableHeight.float32 / DEFAULT_HEIGHT.float32
  )
  renderer.canvasOrigin = vec2(
    (drawableWidth.float32 - DEFAULT_WIDTH.float32 * renderer.canvasScale) * 0.5,
    (drawableHeight.float32 - DEFAULT_HEIGHT.float32 * renderer.canvasScale) * 0.5
  )
  renderer.blendMode = BlendMode_None
  renderer.layerActive = false
  renderer.canvasTransformActive = false
  # Silky and other raw OpenGL callers mutate VAO/buffer/shader state.
  # Re-bind Boxy's state before starting a new frame.
  renderer.boxy.exitRawOpenGLMode()
  renderer.boxy.beginFrame(
    ivec2(drawableWidth.int32, drawableHeight.int32),
    ortho(
      0.0'f32, drawableWidth.float32,
      drawableHeight.float32, 0.0'f32,
      -1000.0'f32, 1000.0'f32
    )
  )
  renderer.boxy.saveTransform()
  renderer.boxy.translate(renderer.canvasOrigin)
  renderer.boxy.scale(vec2(renderer.canvasScale, renderer.canvasScale))
  renderer.canvasTransformActive = true

proc endFrame*(renderer: RendererPtr) =
  renderer.closeBlendLayer()
  if renderer.canvasTransformActive:
    renderer.boxy.restoreTransform()
    renderer.canvasTransformActive = false
  renderer.boxy.endFrame()

proc beginOverlay*(renderer: RendererPtr) =
  renderer.closeBlendLayer()
  renderer.boxy.enterRawOpenGLMode()

proc endOverlay*(renderer: RendererPtr) =
  renderer.boxy.exitRawOpenGLMode()

proc setDrawColor*(renderer: RendererPtr, r, g, b, a: uint8) =
  renderer.currentColor = toChromaColor(r, g, b, a)

proc setDrawBlendMode*(renderer: RendererPtr, mode: BlendMode) =
  if renderer.blendMode == mode:
    return

  renderer.closeBlendLayer()
  renderer.blendMode = mode

  if mode == BlendMode_Add:
    renderer.boxy.pushLayer()
    renderer.layerActive = true

proc clear*(renderer: RendererPtr) =
  if renderer.canvasTransformActive:
    renderer.boxy.restoreTransform()
  renderer.boxy.drawRect(
    bumpy.rect(0.0, 0.0, renderer.frameWidth.float32, renderer.frameHeight.float32),
    renderer.currentColor
  )
  if renderer.canvasTransformActive:
    renderer.boxy.saveTransform()
    renderer.boxy.translate(renderer.canvasOrigin)
    renderer.boxy.scale(vec2(renderer.canvasScale, renderer.canvasScale))

proc drawFilledRect*(renderer: RendererPtr, x, y, w, h: float) =
  if w <= 0.0 or h <= 0.0:
    return
  renderer.boxy.drawRect(
    bumpy.rect(x, y, w, h),
    renderer.currentColor
  )

proc drawFilledRect*(renderer: RendererPtr, x, y, w, h: cint) =
  renderer.drawFilledRect(x.float32, y.float32, w.float32, h.float32)

proc drawOutlineRect*(renderer: RendererPtr, x, y, w, h: float) =
  if w <= 0.0 or h <= 0.0:
    return
  renderer.drawFilledRect(x, y, w, 1.0)
  renderer.drawFilledRect(x, y + h - 1.0, w, 1.0)
  renderer.drawFilledRect(x, y, 1.0, h)
  renderer.drawFilledRect(x + w - 1.0, y, 1.0, h)

proc drawOutlineRect*(renderer: RendererPtr, x, y, w, h: cint) =
  renderer.drawOutlineRect(x.float32, y.float32, w.float32, h.float32)
