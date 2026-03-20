## Build metadata derived from the nimble package file.

import std/strutils

proc extractVersion(contents: string): string {.compileTime.} =
  for line in contents.splitLines():
    let trimmed = line.strip()
    if trimmed.startsWith("version"):
      let parts = trimmed.split('"')
      if parts.len >= 2 and parts[1].len > 0:
        return parts[1]
  return "0.0.0-dev"

const GameVersion* = extractVersion(staticRead("../together.nimble"))
