## Save/load system for Together — persists user preferences

import json
import os
import "../constants"

type
  SaveData* = object
    fullscreen*: bool

proc defaultSave*(): SaveData =
  SaveData(fullscreen: false)

proc writeSave*(data: SaveData) =
  let j = %* {"fullscreen": data.fullscreen}
  writeFile(SAVE_FILE, $j)

proc loadSave*(): SaveData =
  result = defaultSave()
  if fileExists(SAVE_FILE):
    try:
      let j = parseJson(readFile(SAVE_FILE))
      if j.hasKey("fullscreen"):
        result.fullscreen = j["fullscreen"].getBool()
    except CatchableError:
      discard
