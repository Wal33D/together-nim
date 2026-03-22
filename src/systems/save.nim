## Save/load system for Together — persists user preferences and star progress

import
  std/[os, tables],
  jsony,
  "../constants"

type
  SaveData* = object
    fullscreen*: bool
    vsync*: bool
    windowPreset*: int
    levelStars*: Table[int, array[3, bool]]

proc defaultSave*(): SaveData =
  SaveData(fullscreen: false, vsync: true, windowPreset: 1,
           levelStars: initTable[int, array[3, bool]]())

proc writeSave*(data: SaveData) =
  writeFile(SAVE_FILE, data.toJson())

proc loadSave*(): SaveData =
  result = defaultSave()
  if fileExists(SAVE_FILE):
    try:
      result = readFile(SAVE_FILE).fromJson(SaveData)
      # Migration: old saves lack windowPreset and vsync fields.
      # jsony deserializes missing int as 0 and missing bool as false.
      # If windowPreset == 0 and fullscreen == false, treat as a migrated
      # old save and apply sane defaults for the new fields.
      if result.windowPreset == 0 and not result.fullscreen:
        result.windowPreset = 1
        result.vsync = true
    except CatchableError:
      discard

proc saveFullscreen*(fullscreen: bool) =
  var data = loadSave()
  data.fullscreen = fullscreen
  writeSave(data)

proc saveVsync*(vsync: bool) =
  var data = loadSave()
  data.vsync = vsync
  writeSave(data)

proc saveWindowPreset*(preset: int) =
  var data = loadSave()
  data.windowPreset = preset
  writeSave(data)

proc hasSaveProgress*(): bool =
  ## Return true when the player has completed at least one level.
  let data = loadSave()
  data.levelStars.len > 0

proc savedContinueLevel*(): int =
  ## Return the level index to resume from (one past the furthest completed).
  let data = loadSave()
  result = 0
  for level in data.levelStars.keys:
    if level >= result:
      result = level + 1
