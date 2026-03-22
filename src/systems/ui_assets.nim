## Runtime Silky atlas bootstrap for Together.

import std/os
import silky

type
  UiAtlasPaths* = object
    pngPath*: string
    jsonPath*: string

const
  UiAtlasVersion = "3"
  UiAtlasDirName = "together-ui"

proc findFirstExisting(paths: openArray[string]): string =
  for path in paths:
    if fileExists(path):
      return path

  raise newException(IOError, "Could not find a usable system font for Silky UI")

proc findDisplayFontPath(): string =
  findFirstExisting([
    "/tmp/treeform-silky/examples/gameplayer/data/IBMPlexMono-Bold.ttf",
    "/tmp/treeform-silky/examples/menu/data/IBMPlexSans-Regular.ttf",
    "/tmp/treeform-silky/examples/panels/data/IBMPlexSans-Regular.ttf",
    "/tmp/treeform-silky/tests/data/IBMPlexSans-Regular.ttf",
    "/System/Library/Fonts/NewYork.ttf",
    "/System/Library/Fonts/Supplemental/Georgia Bold.ttf",
    "/System/Library/Fonts/Supplemental/Georgia.ttf",
    "/System/Library/Fonts/Supplemental/Times New Roman Bold.ttf"
  ])

proc findBodyFontPath(): string =
  findFirstExisting([
    "/tmp/treeform-silky/examples/menu/data/IBMPlexSans-Regular.ttf",
    "/tmp/treeform-silky/examples/panels/data/IBMPlexSans-Regular.ttf",
    "/tmp/treeform-silky/tests/data/IBMPlexSans-Regular.ttf",
    "/System/Library/Fonts/Geneva.ttf",
    "/System/Library/Fonts/Supplemental/Verdana.ttf",
    "/System/Library/Fonts/Supplemental/Trebuchet MS.ttf",
    "/System/Library/Fonts/SFNS.ttf"
  ])

proc ensureUiAtlas*(): UiAtlasPaths =
  let atlasDir = getTempDir() / UiAtlasDirName
  result = UiAtlasPaths(
    pngPath: atlasDir / "atlas.png",
    jsonPath: atlasDir / "atlas.json",
  )

  let versionPath = atlasDir / "version"
  if fileExists(result.pngPath) and fileExists(result.jsonPath) and
     fileExists(versionPath) and readFile(versionPath) == UiAtlasVersion:
    return

  createDir(atlasDir)

  let builder = newAtlasBuilder(2048, 2)
  builder.addFont(findDisplayFontPath(), "Display", 46.0)
  builder.addFont(findDisplayFontPath(), "DisplayHd", 92.0)
  builder.addFont(findBodyFontPath(), "Body", 22.0)
  builder.addFont(findBodyFontPath(), "BodyHd", 44.0)
  builder.addFont(findBodyFontPath(), "Small", 16.0)
  builder.addFont(findBodyFontPath(), "SmallHd", 32.0)
  builder.write(result.pngPath, result.jsonPath)
  writeFile(versionPath, UiAtlasVersion)
