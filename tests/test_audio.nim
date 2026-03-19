import unittest
import "../src/systems/audio"

suite "audio system":
  test "SoundKind enum has all required values":
    let kinds = [soundJump, soundLand, soundDeath, soundLevelComplete,
                 soundCharSwitch, soundExitReached]
    check kinds.len == 6

  test "playSound is safe without audio initialised":
    # Audio is not open (SDL not initialised in unit tests).
    # playSound must return without crashing.
    playSound(soundJump)
    playSound(soundLand)
    playSound(soundDeath)
    playSound(soundLevelComplete)
    playSound(soundCharSwitch)
    playSound(soundExitReached)
