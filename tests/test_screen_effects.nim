import
  unittest,
  systems/screenEffects,
  systems/camera,
  constants

suite "screenEffects":
  test "initScreenEffects starts with no flash and vignette on":
    let fx = initScreenEffects()
    check not fx.flashActive()
    check fx.flashAlpha() == 0.0
    check fx.vignetteActive()

  test "triggerFlash activates the flash overlay":
    var fx = initScreenEffects()
    let white: Color = (r: 255'u8, g: 255'u8, b: 255'u8)
    fx.triggerFlash(white, 0.5)
    check fx.flashActive()
    check fx.flashAlpha() == 1.0
    check fx.flashColor == white

  test "flash alpha decays over time":
    var fx = initScreenEffects()
    let white: Color = (r: 255'u8, g: 255'u8, b: 255'u8)
    fx.triggerFlash(white, 1.0)
    fx.updateScreenEffects(0.5)
    check abs(fx.flashAlpha() - 0.5) < 0.01

  test "flash deactivates after duration expires":
    var fx = initScreenEffects()
    let white: Color = (r: 255'u8, g: 255'u8, b: 255'u8)
    fx.triggerFlash(white, 0.5)
    fx.updateScreenEffects(0.6)
    check not fx.flashActive()
    check fx.flashAlpha() == 0.0

  test "flash uses the specified color":
    var fx = initScreenEffects()
    let red: Color = (r: 255'u8, g: 0'u8, b: 0'u8)
    fx.triggerFlash(red, 0.3)
    check fx.flashColor == red

  test "flash alpha at midpoint":
    var fx = initScreenEffects()
    let white: Color = (r: 255'u8, g: 255'u8, b: 255'u8)
    fx.triggerFlash(white, 0.4)
    fx.updateScreenEffects(0.2)
    check abs(fx.flashAlpha() - 0.5) < 0.01

  test "triggerShake delegates to camera":
    var fx = initScreenEffects()
    var cam = newCamera()
    fx.triggerShake(cam, 4.0, 0.3)
    check cam.shakeTimer == 0.3
    check cam.shakeIntensity == 4.0

  test "triggerShake produces offsets after camera update":
    var fx = initScreenEffects()
    var cam = newCamera()
    fx.triggerShake(cam, 4.0, 0.3)
    cam.updateShake(0.016)
    check cam.shakeTimer > 0.0
    check cam.shakeOffsetX != 0.0 or cam.shakeOffsetY != 0.0

  test "vignette is active by default":
    let fx = initScreenEffects()
    check fx.vignetteActive()

  test "vignette can be toggled off":
    var fx = initScreenEffects()
    fx.vignetteOn = false
    check not fx.vignetteActive()
