import unittest
import os
import "../src/systems/save"
import "../src/constants"

suite "save system":
  setup:
    if fileExists(SAVE_FILE):
      removeFile(SAVE_FILE)

  teardown:
    if fileExists(SAVE_FILE):
      removeFile(SAVE_FILE)

  test "defaultSave returns expected defaults":
    let s = defaultSave()
    check s.fullscreen == false
    check s.vsync == true
    check s.windowPreset == 1
    check s.masterVolume == 1.0

  test "loadSave returns defaults when no file exists":
    let s = loadSave()
    check s.fullscreen == false
    check s.vsync == true
    check s.windowPreset == 1
    check s.masterVolume == 1.0

  test "writeSave and loadSave round-trip all fields":
    var s = SaveData(fullscreen: true, vsync: false, windowPreset: 3)
    writeSave(s)
    let loaded = loadSave()
    check loaded.fullscreen == true
    check loaded.vsync == false
    check loaded.windowPreset == 3

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
    writeFile(SAVE_FILE, """{"fullscreen":false}""")
    let loaded = loadSave()
    check loaded.windowPreset == 1
    check loaded.vsync == true
    check loaded.masterVolume == 1.0

  test "migration from old save without masterVolume":
    # Old saves lack masterVolume; jsony deserializes missing float as 0.0.
    # We cannot distinguish missing from intentional mute, so 0.0 is kept.
    writeFile(SAVE_FILE, """{"fullscreen":false,"windowPreset":2,"vsync":true}""")
    let loaded = loadSave()
    check loaded.masterVolume == 0.0

  test "migration preserves preset 0 when fullscreen is true":
    # If fullscreen is true, windowPreset 0 could be intentional.
    writeFile(SAVE_FILE, """{"fullscreen":true,"windowPreset":0}""")
    let loaded = loadSave()
    check loaded.windowPreset == 0

  test "loadSave handles corrupted file gracefully":
    writeFile(SAVE_FILE, "not valid json{{{")
    let s = loadSave()
    check s.fullscreen == false
    check s.vsync == true
    check s.windowPreset == 1
    check s.masterVolume == 1.0
