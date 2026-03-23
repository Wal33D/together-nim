import
  unittest,
  ../src/[constants],
  ../src/systems/audio

suite "limbic resonance constants and stubs":
  test "CharFreqRatios has 6 positive entries":
    check CharFreqRatios.len == 6
    for ratio in CharFreqRatios:
      check ratio > 0.0

  test "ActPalettes has 5 entries with positive base freq":
    check ActPalettes.len == 5
    for palette in ActPalettes:
      check palette.baseFreqs[0] > 0.0

  test "ActOscillatorParams has 5 entries":
    check ActOscillatorParams.len == 5

  test "Act 1 config values":
    check ActOscillatorParams[1].ampMultiplier == 0.5
    check ActOscillatorParams[1].onDuration == 1.5
    check ActOscillatorParams[1].dissonanceIdx == -1

  test "Act 4 dissonance targets character 2 by a tritone":
    check ActOscillatorParams[4].dissonanceIdx == 2
    check ActOscillatorParams[4].dissonanceSemitones == 6.0

  test "Act 5 config resolved values":
    check ActOscillatorParams[5].ampMultiplier == 1.0
    check ActOscillatorParams[5].dissonanceIdx == -1
    check ActOscillatorParams[5].dissonanceSemitones == 0.0

  test "setCharacterDistance stub does not raise":
    setCharacterDistance(0, 300.0)
    setCharacterDistance(5, 0.0)

  test "setActOscConfig stub does not raise":
    setActOscConfig(ActOscillatorParams[3])

  test "soundReunion and soundSeparation exist":
    playSound(soundReunion)
    playSound(soundSeparation)

  test "proximity threshold crossing triggers no crash":
    # Far away, then close — should trigger reunion logic.
    setCharacterDistance(0, 200.0)
    setCharacterDistance(0, 50.0)
    # Close, then far — should trigger separation logic.
    setCharacterDistance(0, 50.0)
    setCharacterDistance(0, 200.0)
