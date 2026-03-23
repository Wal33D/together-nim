import unittest
import "../src/systems/audio"

suite "audio system":
  test "music bed pattern is looping and subtle":
    let pattern = musicBedPattern()
    check pattern.len == 8
    check pattern[0].freqStart == 110.0
    check pattern[0].freqEnd == 110.0
    check pattern[0].durationMs == 1200
    check pattern[1].freqStart < pattern[1].freqEnd
    check pattern[0].amplitude < 0.1
    check pattern[1].amplitude < 0.1
    check pattern[0].durationMs > pattern[1].durationMs

  test "SoundKind enum has all required values":
    let kinds = [soundJump, soundLand, soundDeath, soundLevelComplete,
                 soundCharSwitch, soundExitReached]
    check kinds.len == 6

  test "playSound is safe without audio initialised":
    # Audio is not open (CoreAudio not initialised in unit tests).
    # playSound must return without crashing.
    playSound(soundJump)
    playSound(soundLand)
    playSound(soundDeath)
    playSound(soundLevelComplete)
    playSound(soundCharSwitch)
    playSound(soundExitReached)
