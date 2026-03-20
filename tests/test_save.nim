import unittest
import os
import "../src/systems/save"
import "../src/constants"

suite "save system":
  setup:
    # Clean up any existing save file before each test
    if fileExists(SAVE_FILE):
      removeFile(SAVE_FILE)

  teardown:
    if fileExists(SAVE_FILE):
      removeFile(SAVE_FILE)

  test "defaultSave returns fullscreen false":
    let s = defaultSave()
    check s.fullscreen == false

  test "loadSave returns defaults when no file exists":
    let s = loadSave()
    check s.fullscreen == false

  test "writeSave and loadSave round-trip fullscreen true":
    var s = SaveData(fullscreen: true)
    writeSave(s)
    let loaded = loadSave()
    check loaded.fullscreen == true

  test "writeSave and loadSave round-trip fullscreen false":
    var s = SaveData(fullscreen: false)
    writeSave(s)
    let loaded = loadSave()
    check loaded.fullscreen == false

  test "saveFullscreen persists fullscreen preference":
    saveFullscreen(true)
    let loaded = loadSave()
    check loaded.fullscreen == true

  test "loadSave handles corrupted file gracefully":
    writeFile(SAVE_FILE, "not valid json{{{")
    let s = loadSave()
    check s.fullscreen == false
