import unittest
import "../src/build_info"

suite "build info":
  test "version matches current nimble metadata":
    check GameVersion == "0.2.0"
