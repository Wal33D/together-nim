## Gamepad/controller support for Together
## Manages IOKit HID game controller lifecycle and maps controller input to game actions.

import
  windy,
  ../game,
  ../constants,
  ./audio,
  ./save

{.passL: "-framework IOKit -framework CoreFoundation".}

# --- Button and axis identity constants ---

const
  ButtonA* = 0'u8
  ButtonB* = 1'u8
  ButtonStart* = 6'u8
  ButtonLB* = 9'u8
  ButtonRB* = 10'u8
  ButtonDpadLeft* = 13'u8
  ButtonDpadRight* = 14'u8
  ButtonDpadUp* = 15'u8
  ButtonDpadDown* = 16'u8
  AxisLeftX* = 0'u8
  AxisDeadzone* = 8000'i16  ## Stick deadzone threshold.

# --- Module state ---

var
  controllerConnected*: bool = false
  dpadLeftHeld: bool = false
  dpadRightHeld: bool = false
  dpadUpHeld: bool = false
  dpadDownHeld: bool = false
  stickLeftHeld: bool = false
  stickRightHeld: bool = false
  prevButtonA: bool = false
  prevButtonB: bool = false
  prevButtonStart: bool = false
  prevButtonLB: bool = false
  prevButtonRB: bool = false
  prevDpadLeft: bool = false
  prevDpadRight: bool = false
  prevDpadUp: bool = false
  prevDpadDown: bool = false
  prevStickLeft: bool = false
  prevStickRight: bool = false

  ## HID state updated by IOKit callbacks.
  hidButtonA: bool = false
  hidButtonB: bool = false
  hidButtonStart: bool = false
  hidButtonLB: bool = false
  hidButtonRB: bool = false
  hidDpadLeft: bool = false
  hidDpadRight: bool = false
  hidDpadUp: bool = false
  hidDpadDown: bool = false
  hidLeftX: int16 = 0

  ## Per-frame one-shot press flags (set on rising edge, cleared each frame).
  padUpPressed*: bool = false
  padDownPressed*: bool = false
  padLeftPressed*: bool = false
  padRightPressed*: bool = false

proc clearPadPressed*() =
  ## Clear all per-frame one-shot pad flags. Call once per frame before polling.
  padUpPressed = false
  padDownPressed = false
  padLeftPressed = false
  padRightPressed = false

proc resetControllerState() =
  dpadLeftHeld = false
  dpadRightHeld = false
  dpadUpHeld = false
  dpadDownHeld = false
  stickLeftHeld = false
  stickRightHeld = false
  prevButtonA = false
  prevButtonB = false
  prevButtonStart = false
  prevButtonLB = false
  prevButtonRB = false
  prevDpadLeft = false
  prevDpadRight = false
  prevDpadUp = false
  prevDpadDown = false
  prevStickLeft = false
  prevStickRight = false
  hidButtonA = false
  hidButtonB = false
  hidButtonStart = false
  hidButtonLB = false
  hidButtonRB = false
  hidDpadLeft = false
  hidDpadRight = false
  hidDpadUp = false
  hidDpadDown = false
  hidLeftX = 0
  padUpPressed = false
  padDownPressed = false
  padLeftPressed = false
  padRightPressed = false

proc syncDirectionalHeldState(game: var Game) =
  game.leftHeld = dpadLeftHeld or stickLeftHeld
  game.rightHeld = dpadRightHeld or stickRightHeld

proc resetPadState*() =
  ## Reset internal pad held state. Useful for tests.
  resetControllerState()

# --- Game logic (pure Nim, no platform dependency) ---

const
  SettingsCount = 5  ## Number of settings rows (0..4).
  VolumeStep = 0.1  ## Volume increment per d-pad press.

proc adjustVolumePad(delta: float) =
  ## Nudge master volume, clamp, persist, and play feedback.
  let vol = clamp(getMasterVolume() + delta, 0.0, 1.0)
  setMasterVolume(vol)
  saveMasterVolume(vol)
  playSound(soundMenuHover)

proc cycleSettingsCursorPad(game: var Game, delta: int) =
  ## Move settings cursor with wrapping. Mirrors cycleSettingsCursor in ui.nim.
  let prev = game.settingsCursor
  game.settingsCursor = (game.settingsCursor + delta + SettingsCount * 4) mod SettingsCount
  if game.settingsCursor != prev:
    playSound(soundMenuHover)

proc handleControllerButton*(game: var Game, button: uint8, isDown: bool) =
  ## Map controller buttons to game actions.
  case button
  of ButtonA:
    if isDown:
      if game.state == settings:
        if game.settingsCursor == 4:
          game.state = game.previousState
          playSound(soundMenuBack)
        elif game.settingsCursor >= 0 and game.settingsCursor <= 2:
          game.pendingSettingsApply = true
      elif game.state == playing:
        game.pressJump()
      else:
        case game.state
        of menu:
          game.handleKey(KeyEnter)
        of levelWin:
          game.handleKey(KeyEnter)
        of credits:
          game.handleKey(KeyEnter)
        of won:
          game.handleKey(KeyEnter)
        of storyBeat:
          game.handleKey(KeySpace)
        else:
          discard
    elif game.state == playing:
      game.releaseJump()

  of ButtonB:
    if isDown:
      if game.state == settings:
        game.state = game.previousState
        playSound(soundMenuBack)
      else:
        game.handleKey(KeyR)

  of ButtonStart:
    if isDown:
      if game.state == settings:
        game.state = game.previousState
        playSound(soundMenuBack)
      else:
        game.handleKey(KeyEscape)

  of ButtonLB:
    if isDown and game.state == playing and game.cycleActiveCharacter(-1):
      playSound(soundCharSwitch)

  of ButtonRB:
    if isDown and game.state == playing and game.cycleActiveCharacter(1):
      playSound(soundCharSwitch)

  of ButtonDpadLeft:
    if isDown and game.state == settings:
      case game.settingsCursor
      of 0:
        game.settingsWindowPreset = (game.settingsWindowPreset - 1 + WindowPresets.len) mod WindowPresets.len
        game.pendingSettingsApply = true
      of 1, 2:
        game.pendingSettingsApply = true
      of 3:
        adjustVolumePad(-VolumeStep)
      else: discard
    else:
      dpadLeftHeld = isDown
      syncDirectionalHeldState(game)

  of ButtonDpadRight:
    if isDown and game.state == settings:
      case game.settingsCursor
      of 0:
        game.settingsWindowPreset = (game.settingsWindowPreset + 1) mod WindowPresets.len
        game.pendingSettingsApply = true
      of 1, 2:
        game.pendingSettingsApply = true
      of 3:
        adjustVolumePad(VolumeStep)
      else: discard
    else:
      dpadRightHeld = isDown
      syncDirectionalHeldState(game)

  of ButtonDpadUp:
    if isDown and game.state == settings:
      game.cycleSettingsCursorPad(-1)
    else:
      dpadUpHeld = isDown

  of ButtonDpadDown:
    if isDown and game.state == settings:
      game.cycleSettingsCursorPad(1)
    else:
      dpadDownHeld = isDown

  else: discard

proc handleControllerAxis*(game: var Game, axis: uint8, value: int16) =
  ## Map left stick X axis to left/right movement.
  if axis == AxisLeftX:
    let newLeft = value < -AxisDeadzone
    let newRight = value > AxisDeadzone
    stickLeftHeld = newLeft
    stickRightHeld = newRight
    syncDirectionalHeldState(game)

proc applyControllerSnapshot*(
    game: var Game,
    aPressed, bPressed, startPressed, lbPressed, rbPressed,
    dpadLeftPressed, dpadRightPressed,
    dpadUpPressed, dpadDownPressed: bool,
    leftX: int16
  ) =
  ## Apply a controller snapshot using edge-triggered updates.
  ##
  ## This is shared by the live polling path and unit tests so we can keep the
  ## transition logic deterministic without requiring hardware.
  if aPressed != prevButtonA:
    handleControllerButton(game, ButtonA, aPressed)
    prevButtonA = aPressed

  if bPressed != prevButtonB:
    if bPressed:
      handleControllerButton(game, ButtonB, true)
    prevButtonB = bPressed

  if startPressed != prevButtonStart:
    if startPressed:
      handleControllerButton(game, ButtonStart, true)
    prevButtonStart = startPressed

  if lbPressed != prevButtonLB:
    if lbPressed:
      handleControllerButton(game, ButtonLB, true)
    prevButtonLB = lbPressed

  if rbPressed != prevButtonRB:
    if rbPressed:
      handleControllerButton(game, ButtonRB, true)
    prevButtonRB = rbPressed

  if dpadLeftPressed != prevDpadLeft:
    handleControllerButton(game, ButtonDpadLeft, dpadLeftPressed)
    if dpadLeftPressed: padLeftPressed = true
    prevDpadLeft = dpadLeftPressed

  if dpadRightPressed != prevDpadRight:
    handleControllerButton(game, ButtonDpadRight, dpadRightPressed)
    if dpadRightPressed: padRightPressed = true
    prevDpadRight = dpadRightPressed

  if dpadUpPressed != prevDpadUp:
    handleControllerButton(game, ButtonDpadUp, dpadUpPressed)
    if dpadUpPressed: padUpPressed = true
    prevDpadUp = dpadUpPressed

  if dpadDownPressed != prevDpadDown:
    handleControllerButton(game, ButtonDpadDown, dpadDownPressed)
    if dpadDownPressed: padDownPressed = true
    prevDpadDown = dpadDownPressed

  let newStickLeft = leftX < -AxisDeadzone
  let newStickRight = leftX > AxisDeadzone
  if newStickLeft != prevStickLeft or newStickRight != prevStickRight:
    handleControllerAxis(game, AxisLeftX, leftX)
    prevStickLeft = newStickLeft
    prevStickRight = newStickRight

# --- IOKit HID FFI declarations ---

type
  IOHIDManagerRef = pointer
  IOHIDDeviceRef = pointer
  IOHIDValueRef = pointer
  IOHIDElementRef = pointer
  CFRunLoopRef = pointer
  CFStringRef = pointer
  CFAllocatorRef = pointer
  CFArrayRef = pointer
  CFNumberRef = pointer
  CFDictionaryRef = pointer
  IOReturn = int32
  IOOptionBits = uint32
  CFIndex = int
  CFDictionaryKeyCallBacks {.importc, header: "<CoreFoundation/CoreFoundation.h>".} = object
  CFDictionaryValueCallBacks {.importc, header: "<CoreFoundation/CoreFoundation.h>".} = object
  CFArrayCallBacks {.importc, header: "<CoreFoundation/CoreFoundation.h>".} = object

var
  kCFTypeDictionaryKeyCallBacks {.importc,
      header: "<CoreFoundation/CoreFoundation.h>".}: CFDictionaryKeyCallBacks
  kCFTypeDictionaryValueCallBacks {.importc,
      header: "<CoreFoundation/CoreFoundation.h>".}: CFDictionaryValueCallBacks
  kCFTypeArrayCallBacks {.importc,
      header: "<CoreFoundation/CoreFoundation.h>".}: CFArrayCallBacks
  kCFRunLoopDefaultMode {.importc,
      header: "<CoreFoundation/CoreFoundation.h>".}: CFStringRef
const
  KCFNumberSInt32Type = 3'i32
  KHIDPageGenericDesktop = 0x01'u32
  KHIDPageButton = 0x09'u32
  KHIDUsageGDJoystick = 0x04'u32
  KHIDUsageGDGamePad = 0x05'u32
  KHIDUsageGDX = 0x30'u32
  KHIDUsageGDHatswitch = 0x39'u32

proc CFRunLoopGetMain(): CFRunLoopRef
  {.importc, header: "<CoreFoundation/CoreFoundation.h>".}

proc CFRunLoopRunInMode(mode: CFStringRef, seconds: float64,
    returnAfterSourceHandled: uint8): int32
  {.importc, header: "<CoreFoundation/CoreFoundation.h>".}

proc CFNumberCreate(allocator: CFAllocatorRef, theType: int32,
    valuePtr: pointer): CFNumberRef
  {.importc, header: "<CoreFoundation/CoreFoundation.h>".}

proc CFDictionaryCreate(allocator: CFAllocatorRef, keys: pointer,
    values: pointer, numValues: CFIndex, keyCallBacks: pointer,
    valueCallBacks: pointer): CFDictionaryRef
  {.importc, header: "<CoreFoundation/CoreFoundation.h>".}

proc CFArrayCreate(allocator: CFAllocatorRef, values: pointer,
    numValues: CFIndex, callBacks: pointer): CFArrayRef
  {.importc, header: "<CoreFoundation/CoreFoundation.h>".}

proc CFRelease(cf: pointer)
  {.importc, header: "<CoreFoundation/CoreFoundation.h>".}

proc CFStringCreateWithCString(alloc: CFAllocatorRef, cStr: cstring,
    encoding: uint32): CFStringRef
  {.importc, header: "<CoreFoundation/CoreFoundation.h>".}

const KCFStringEncodingUTF8 = 0x08000100'u32

proc IOHIDManagerCreate(allocator: CFAllocatorRef,
    options: IOOptionBits): IOHIDManagerRef
  {.importc, header: "<IOKit/hid/IOHIDManager.h>".}

proc IOHIDManagerSetDeviceMatchingMultiple(manager: IOHIDManagerRef,
    multiple: CFArrayRef)
  {.importc, header: "<IOKit/hid/IOHIDManager.h>".}

proc IOHIDManagerRegisterDeviceMatchingCallback(manager: IOHIDManagerRef,
    callback: pointer, context: pointer)
  {.importc, header: "<IOKit/hid/IOHIDManager.h>".}

proc IOHIDManagerRegisterDeviceRemovalCallback(manager: IOHIDManagerRef,
    callback: pointer, context: pointer)
  {.importc, header: "<IOKit/hid/IOHIDManager.h>".}

proc IOHIDManagerRegisterInputValueCallback(manager: IOHIDManagerRef,
    callback: pointer, context: pointer)
  {.importc, header: "<IOKit/hid/IOHIDManager.h>".}

proc IOHIDManagerScheduleWithRunLoop(manager: IOHIDManagerRef,
    runLoop: CFRunLoopRef, mode: CFStringRef)
  {.importc, header: "<IOKit/hid/IOHIDManager.h>".}

proc IOHIDManagerOpen(manager: IOHIDManagerRef,
    options: IOOptionBits): IOReturn
  {.importc, header: "<IOKit/hid/IOHIDManager.h>".}

proc IOHIDManagerClose(manager: IOHIDManagerRef,
    options: IOOptionBits): IOReturn
  {.importc, header: "<IOKit/hid/IOHIDManager.h>".}

proc IOHIDManagerUnscheduleFromRunLoop(manager: IOHIDManagerRef,
    runLoop: CFRunLoopRef, mode: CFStringRef)
  {.importc, header: "<IOKit/hid/IOHIDManager.h>".}

proc IOHIDValueGetIntegerValue(value: IOHIDValueRef): CFIndex
  {.importc, header: "<IOKit/hid/IOHIDValue.h>".}

proc IOHIDValueGetElement(value: IOHIDValueRef): IOHIDElementRef
  {.importc, header: "<IOKit/hid/IOHIDValue.h>".}

proc IOHIDElementGetUsage(element: IOHIDElementRef): uint32
  {.importc, header: "<IOKit/hid/IOHIDElement.h>".}

proc IOHIDElementGetUsagePage(element: IOHIDElementRef): uint32
  {.importc, header: "<IOKit/hid/IOHIDElement.h>".}

proc IOHIDElementGetLogicalMin(element: IOHIDElementRef): CFIndex
  {.importc, header: "<IOKit/hid/IOHIDElement.h>".}

proc IOHIDElementGetLogicalMax(element: IOHIDElementRef): CFIndex
  {.importc, header: "<IOKit/hid/IOHIDElement.h>".}

proc IOHIDElementGetDevice(element: IOHIDElementRef): IOHIDDeviceRef
  {.importc, header: "<IOKit/hid/IOHIDElement.h>".}

# --- IOKit HID Manager state and callbacks ---

var
  hidManager: IOHIDManagerRef = nil
  hidDevice: IOHIDDeviceRef = nil

proc normalizeAxis(value: int, logMin: int, logMax: int): int16 =
  ## Normalize a HID axis value from [logMin, logMax] to -32768..32767.
  let span = logMax - logMin
  if span <= 0: return 0'i16
  let scaled = ((value - logMin).float * 65535.0 / span.float) - 32768.0
  return clamp(scaled.int, -32768, 32767).int16

proc deviceMatchCallback(context: pointer, res: IOReturn, sender: pointer,
    device: IOHIDDeviceRef) {.cdecl.} =
  ## Called when a matching HID gamepad or joystick is connected.
  if not controllerConnected:
    hidDevice = device
    controllerConnected = true
    resetControllerState()

proc deviceRemovalCallback(context: pointer, res: IOReturn, sender: pointer,
    device: IOHIDDeviceRef) {.cdecl.} =
  ## Called when a HID device is disconnected.
  if device == hidDevice:
    hidDevice = nil
    controllerConnected = false
    resetControllerState()

proc inputValueCallback(context: pointer, res: IOReturn, sender: pointer,
    value: IOHIDValueRef) {.cdecl.} =
  ## Called when a HID input value changes on any matched device.
  let element = IOHIDValueGetElement(value)
  if IOHIDElementGetDevice(element) != hidDevice:
    return
  let usagePage = IOHIDElementGetUsagePage(element)
  let usage = IOHIDElementGetUsage(element)
  let intVal = IOHIDValueGetIntegerValue(value)

  if usagePage == KHIDPageButton:
    let pressed = intVal != 0
    case usage
    of 1: hidButtonA = pressed
    of 2: hidButtonB = pressed
    of 5: hidButtonLB = pressed
    of 6: hidButtonRB = pressed
    of 9: hidButtonStart = pressed
    else: discard

  elif usagePage == KHIDPageGenericDesktop:
    case usage
    of KHIDUsageGDX:
      let logMin = IOHIDElementGetLogicalMin(element)
      let logMax = IOHIDElementGetLogicalMax(element)
      hidLeftX = normalizeAxis(intVal, logMin, logMax)
    of KHIDUsageGDHatswitch:
      hidDpadLeft = intVal >= 5 and intVal <= 7
      hidDpadRight = intVal >= 1 and intVal <= 3
      hidDpadUp = intVal == 7 or intVal == 0 or intVal == 1
      hidDpadDown = intVal >= 3 and intVal <= 5
    else: discard

proc createMatchingDict(usagePage: uint32, usage: uint32): CFDictionaryRef =
  ## Build a CoreFoundation dictionary for IOKit HID device matching.
  var pageVal = usagePage.int32
  var usageVal = usage.int32
  let pageNum = CFNumberCreate(nil, KCFNumberSInt32Type, addr pageVal)
  let usageNum = CFNumberCreate(nil, KCFNumberSInt32Type, addr usageVal)
  let usagePageKey = CFStringCreateWithCString(nil, "DeviceUsagePage", KCFStringEncodingUTF8)
  let usageKey = CFStringCreateWithCString(nil, "DeviceUsage", KCFStringEncodingUTF8)
  var keys: array[2, pointer] = [
    cast[pointer](usagePageKey),
    cast[pointer](usageKey)]
  var vals: array[2, pointer] = [
    cast[pointer](pageNum),
    cast[pointer](usageNum)]
  result = CFDictionaryCreate(nil, addr keys[0], addr vals[0], 2,
    addr kCFTypeDictionaryKeyCallBacks, addr kCFTypeDictionaryValueCallBacks)
  CFRelease(pageNum)
  CFRelease(usageNum)
  CFRelease(usagePageKey)
  CFRelease(usageKey)

proc openFirstController*() =
  ## Create an IOKit HID Manager and register for gamepad/joystick devices.
  if hidManager != nil: return
  hidManager = IOHIDManagerCreate(nil, 0)
  if hidManager == nil: return

  let gamepadDict = createMatchingDict(KHIDPageGenericDesktop, KHIDUsageGDGamePad)
  let joystickDict = createMatchingDict(KHIDPageGenericDesktop, KHIDUsageGDJoystick)
  var dicts: array[2, pointer] = [
    cast[pointer](gamepadDict),
    cast[pointer](joystickDict)]
  let matchArray = CFArrayCreate(nil, addr dicts[0], 2,
    addr kCFTypeArrayCallBacks)

  IOHIDManagerSetDeviceMatchingMultiple(hidManager, matchArray)
  IOHIDManagerRegisterDeviceMatchingCallback(hidManager,
    cast[pointer](deviceMatchCallback), nil)
  IOHIDManagerRegisterDeviceRemovalCallback(hidManager,
    cast[pointer](deviceRemovalCallback), nil)
  IOHIDManagerRegisterInputValueCallback(hidManager,
    cast[pointer](inputValueCallback), nil)
  IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetMain(),
    kCFRunLoopDefaultMode)
  discard IOHIDManagerOpen(hidManager, 0)

  CFRelease(matchArray)
  CFRelease(gamepadDict)
  CFRelease(joystickDict)

proc closeController*() =
  ## Close and release the IOKit HID Manager.
  if hidManager != nil:
    IOHIDManagerUnscheduleFromRunLoop(hidManager, CFRunLoopGetMain(),
      kCFRunLoopDefaultMode)
    discard IOHIDManagerClose(hidManager, 0)
    CFRelease(hidManager)
    hidManager = nil
  hidDevice = nil
  controllerConnected = false
  resetControllerState()

proc pollControllerInput*(game: var Game) =
  ## Process pending HID events and apply current controller state to the game.
  clearPadPressed()
  if hidManager == nil: return
  discard CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.0, 0)
  if not controllerConnected: return

  applyControllerSnapshot(
    game,
    hidButtonA, hidButtonB, hidButtonStart, hidButtonLB, hidButtonRB,
    hidDpadLeft, hidDpadRight, hidDpadUp, hidDpadDown, hidLeftX
  )
