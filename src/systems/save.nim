## Save/load system for Together — persists user preferences, star progress,
## and cumulative play statistics.

import
  std/[os, tables],
  jsony,
  "../constants"

let
  saveDir = getHomeDir() / SaveDirName
  saveFilePath* = saveDir / SaveFileName

type
  SaveData* = object
    fullscreen*: bool
    vsync*: bool
    windowPreset*: int
    masterVolume*: float
    levelStars*: Table[int, array[3, bool]]
    highestCompletedLevel*: int
    totalDeaths*: int
    totalPlayTime*: float

proc defaultSave*(): SaveData =
  SaveData(fullscreen: false, vsync: true, windowPreset: 1,
           masterVolume: 1.0,
           levelStars: initTable[int, array[3, bool]](),
           highestCompletedLevel: -1,
           totalDeaths: 0,
           totalPlayTime: 0.0)

proc writeSave*(data: SaveData) =
  ## Persist save data, creating the save directory if needed.
  createDir(saveDir)
  writeFile(saveFilePath, data.toJson())

proc loadSave*(): SaveData =
  result = defaultSave()
  if fileExists(saveFilePath):
    try:
      result = readFile(saveFilePath).fromJson(SaveData)
      # Migration: old saves lack windowPreset and vsync fields.
      # jsony deserializes missing int as 0 and missing bool as false.
      # If windowPreset == 0 and fullscreen == false, treat as a migrated
      # old save and apply sane defaults for the new fields.
      if result.windowPreset == 0 and not result.fullscreen:
        result.windowPreset = 1
        result.vsync = true
        result.masterVolume = 1.0
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

proc saveMasterVolume*(vol: float) =
  ## Persist the master volume setting.
  var data = loadSave()
  data.masterVolume = clamp(vol, 0.0, 1.0)
  writeSave(data)

proc saveHighestLevel*(level: int) =
  ## Persist the highest completed level index.
  var data = loadSave()
  if level > data.highestCompletedLevel:
    data.highestCompletedLevel = level
    writeSave(data)

proc saveLevelProgress*(level: int, deaths: int, playTime: float) =
  ## Persist cumulative deaths and play time when a level is completed.
  var data = loadSave()
  if level > data.highestCompletedLevel:
    data.highestCompletedLevel = level
  data.totalDeaths = deaths
  data.totalPlayTime = playTime
  writeSave(data)

proc hasSaveProgress*(): bool =
  ## Return true when the player has completed at least one level.
  let data = loadSave()
  data.levelStars.len > 0

proc levelCompleted*(levelIdx: int): bool =
  ## Return true when the player has any star for this 0-based level index.
  let data = loadSave()
  if data.levelStars.hasKey(levelIdx):
    for star in data.levelStars[levelIdx]:
      if star: return true
  false

proc savedContinueLevel*(): int =
  ## Return the level index to resume from (one past the furthest completed).
  let data = loadSave()
  result = 0
  for level in data.levelStars.keys:
    if level >= result:
      result = level + 1

proc levelAvailable*(levelIdx: int): bool =
  ## Return true when the level is completed or is the next playable level.
  levelCompleted(levelIdx) or levelIdx == savedContinueLevel()
