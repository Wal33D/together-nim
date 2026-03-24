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
                 soundCharSwitch, soundExitReached,
                 soundMenuHover, soundMenuSelect, soundMenuBack,
                 soundTransitionSwoosh, soundReunion, soundSeparation,
                 soundJumpPip, soundJumpLuca, soundJumpBruno,
                 soundJumpCara, soundJumpFelix, soundJumpIvy,
                 soundJumpPipDouble]
    check kinds.len == 19

  test "CharJumpSounds maps character indices to jump sounds":
    check CharJumpSounds[0] == soundJumpPip
    check CharJumpSounds[1] == soundJumpLuca
    check CharJumpSounds[2] == soundJumpBruno
    check CharJumpSounds[3] == soundJumpCara
    check CharJumpSounds[4] == soundJumpFelix
    check CharJumpSounds[5] == soundJumpIvy

  test "playSound is safe without audio initialised":
    # Audio is not open (CoreAudio not initialised in unit tests).
    # playSound must return without crashing.
    playSound(soundJump)
    playSound(soundLand)
    playSound(soundDeath)
    playSound(soundLevelComplete)
    playSound(soundCharSwitch)
    playSound(soundExitReached)
    for sk in CharJumpSounds:
      playSound(sk)
    playSound(soundJumpPipDouble)

  test "setMasterVolume and getMasterVolume stubs work":
    setMasterVolume(0.5)
    check getMasterVolume() == 1.0  # Stub always returns 1.0.
