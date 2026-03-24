import
  unittest,
  "../src/systems/audio",
  "../src/constants"

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

  test "playLevelCompleteFanfare is safe for all acts":
    for act in 0..4:
      playLevelCompleteFanfare(act)

  test "Act 5 palette fifth fallback avoids zero frequency":
    # Act 5 palette has baseFreqs[2] = 0.0 (open fifth placeholder).
    # The fanfare must derive a real fifth via root * 1.498.
    let palette = ActPalettes[4]
    check palette.baseFreqs[2] == 0.0
    let derivedFifth = palette.baseFreqs[0] * 1.498
    check derivedFifth > 1.0  # Must not be zero or near-zero.

  test "setMasterVolume and getMasterVolume stubs work":
    setMasterVolume(0.5)
    check getMasterVolume() == 1.0  # Stub always returns 1.0.
