## Save/load system for Together — persists user preferences and star progress

import
  std/[os, tables],
  jsony,
  "../constants"

type
  SaveData* = object
    fullscreen*: bool
    levelStars*: Table[int, array[3, bool]]

proc defaultSave*(): SaveData =
  SaveData(fullscreen: false, levelStars: initTable[int, array[3, bool]]())

proc writeSave*(data: SaveData) =
  writeFile(SAVE_FILE, data.toJson())

proc loadSave*(): SaveData =
  result = defaultSave()
  if fileExists(SAVE_FILE):
    try:
      result = readFile(SAVE_FILE).fromJson(SaveData)
    except CatchableError:
      discard

proc saveFullscreen*(fullscreen: bool) =
  var data = loadSave()
  data.fullscreen = fullscreen
  writeSave(data)
