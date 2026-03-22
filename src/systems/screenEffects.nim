## Screen-wide visual effects: shake, flash, and vignette.

import
  ../constants,
  camera

type
  ScreenEffects* = object
    flashTimer*: float
    flashDuration*: float
    flashColor*: Color
    vignetteOn*: bool

proc initScreenEffects*(): ScreenEffects =
  ## Create a new ScreenEffects with vignette enabled by default.
  ScreenEffects(
    flashTimer: 0.0,
    flashDuration: 0.0,
    flashColor: (r: 255'u8, g: 255'u8, b: 255'u8),
    vignetteOn: true,
  )

proc triggerShake*(effects: var ScreenEffects, cam: var Camera,
                   amplitude, duration: float) =
  ## Start a screen shake. Delegates to the camera shake system.
  cam.triggerShake(amplitude, duration)

proc triggerFlash*(effects: var ScreenEffects, color: Color, duration: float) =
  ## Start a full-screen color flash that fades out over the given duration.
  effects.flashColor = color
  effects.flashDuration = duration
  effects.flashTimer = duration

proc flashActive*(effects: ScreenEffects): bool =
  ## Return whether a flash overlay is currently showing.
  effects.flashTimer > 0.0

proc flashAlpha*(effects: ScreenEffects): float =
  ## Return the current flash opacity (1.0 at trigger, fading to 0.0).
  if effects.flashDuration <= 0.0:
    return 0.0
  max(0.0, effects.flashTimer / effects.flashDuration)

proc vignetteActive*(effects: ScreenEffects): bool =
  ## Return whether the vignette edge darkening is active.
  effects.vignetteOn

proc updateScreenEffects*(effects: var ScreenEffects, dt: float) =
  ## Advance timers and decay effects each frame.
  if effects.flashTimer > 0.0:
    effects.flashTimer = max(0.0, effects.flashTimer - dt)
