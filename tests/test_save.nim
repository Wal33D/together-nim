import unittest
import os
import "../src/systems/save"

suite "save system":
  setup:
    if fileExists(saveFilePath):
      removeFile(saveFilePath)

  teardown:
    if fileExists(saveFilePath):
      removeFile(saveFilePath)

  test "defaultSave returns expected defaults":
    let s = defaultSave()
    check s.fullscreen == false
    check s.vsync == true
    check s.windowPreset == 1
    check s.masterVolume == 1.0
    check s.totalDeaths == 0
    check s.totalPlayTime == 0.0

  test "loadSave returns defaults when no file exists":
    let s = loadSave()
    check s.fullscreen == false
    check s.vsync == true
    check s.windowPreset == 1
    check s.masterVolume == 1.0
    check s.totalDeaths == 0
    check s.totalPlayTime == 0.0

  test "writeSave and loadSave round-trip all fields":
    var s = SaveData(fullscreen: true, vsync: false, windowPreset: 3,
                     totalDeaths: 7, totalPlayTime: 123.4)
    writeSave(s)
    let loaded = loadSave()
    check loaded.fullscreen == true
    check loaded.vsync == false
    check loaded.windowPreset == 3
    check loaded.totalDeaths == 7
    check loaded.totalPlayTime == 123.4

  test "writeSave and loadSave round-trip fullscreen false":
    var s = defaultSave()
    s.fullscreen = false
    writeSave(s)
    let loaded = loadSave()
    check loaded.fullscreen == false

  test "saveFullscreen persists fullscreen preference":
    saveFullscreen(true)
    let loaded = loadSave()
    check loaded.fullscreen == true

  test "saveVsync persists vsync preference":
    saveVsync(false)
    let loaded = loadSave()
    check loaded.vsync == false

  test "saveWindowPreset persists window preset":
    saveWindowPreset(2)
    let loaded = loadSave()
    check loaded.windowPreset == 2

  test "saveMasterVolume persists volume preference":
    saveMasterVolume(0.5)
    let loaded = loadSave()
    check loaded.masterVolume == 0.5

  test "saveMasterVolume clamps above 1.0":
    saveMasterVolume(1.5)
    let loaded = loadSave()
    check loaded.masterVolume == 1.0

  test "saveMasterVolume clamps below 0.0":
    saveMasterVolume(0.25)
    saveMasterVolume(-0.3)
    let loaded = loadSave()
    # 0.0 is a valid muted state.
    check loaded.masterVolume == 0.0

  test "migration from old save without windowPreset":
    # Old save files only had fullscreen; jsony deserializes missing int as 0.
    createDir(parentDir(saveFilePath))
    writeFile(saveFilePath, """{"fullscreen":false}""")
    let loaded = loadSave()
    check loaded.windowPreset == 1
    check loaded.vsync == true
    check loaded.masterVolume == 1.0

  test "migration from old save without masterVolume":
    # Old saves lack masterVolume; jsony deserializes missing float as 0.0.
    # We cannot distinguish missing from intentional mute, so 0.0 is kept.
    createDir(parentDir(saveFilePath))
    writeFile(saveFilePath, """{"fullscreen":false,"windowPreset":2,"vsync":true}""")
    let loaded = loadSave()
    check loaded.masterVolume == 0.0

  test "migration preserves preset 0 when fullscreen is true":
    # If fullscreen is true, windowPreset 0 could be intentional.
    createDir(parentDir(saveFilePath))
    writeFile(saveFilePath, """{"fullscreen":true,"windowPreset":0}""")
    let loaded = loadSave()
    check loaded.windowPreset == 0

  test "loadSave handles corrupted file gracefully":
    createDir(parentDir(saveFilePath))
    writeFile(saveFilePath, "not valid json{{{")
    let s = loadSave()
    check s.fullscreen == false
    check s.vsync == true
    check s.windowPreset == 1
    check s.masterVolume == 1.0
    check s.totalDeaths == 0
    check s.totalPlayTime == 0.0

  test "defaultSave has highestCompletedLevel of -1":
    let s = defaultSave()
    check s.highestCompletedLevel == -1

  test "saveHighestLevel persists level":
    saveHighestLevel(5)
    let loaded = loadSave()
    check loaded.highestCompletedLevel == 5

  test "saveHighestLevel only increases":
    saveHighestLevel(10)
    saveHighestLevel(3)
    let loaded = loadSave()
    check loaded.highestCompletedLevel == 10

  test "migration from old save without highestCompletedLevel":
    createDir(parentDir(saveFilePath))
    writeFile(saveFilePath, """{"fullscreen":false,"vsync":true,"windowPreset":1,"masterVolume":1.0}""")
    let loaded = loadSave()
    check loaded.highestCompletedLevel == 0

  test "saveLevelProgress persists deaths and play time":
    saveLevelProgress(2, 5, 120.5)
    let loaded = loadSave()
    check loaded.highestCompletedLevel == 2
    check loaded.totalDeaths == 5
    check loaded.totalPlayTime == 120.5

  test "saveLevelProgress updates highest level only when higher":
    saveLevelProgress(5, 10, 300.0)
    saveLevelProgress(3, 12, 400.0)
    let loaded = loadSave()
    check loaded.highestCompletedLevel == 5
    check loaded.totalDeaths == 12
    check loaded.totalPlayTime == 400.0

  test "writeSave creates directory if missing":
    let dir = parentDir(saveFilePath)
    if dirExists(dir):
      removeDir(dir)
    var s = defaultSave()
    s.totalDeaths = 3
    writeSave(s)
    let loaded = loadSave()
    check loaded.totalDeaths == 3
