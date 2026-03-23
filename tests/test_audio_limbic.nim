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

  test "CharOscActConfigs has 5 entries":
    check CharOscActConfigs.len == 5

  test "Act 1 config values":
    check CharOscActConfigs[0].ampMultiplier == 0.5
    check CharOscActConfigs[0].onDuration == 1.5

  test "Act 5 config resolved values":
    check CharOscActConfigs[4].ampMultiplier == 1.0
    check CharOscActConfigs[4].intervalShift == 0.0

  test "Act 4 dissonance shift":
    check CharOscActConfigs[3].intervalShift == 1.0

  test "setCharacterDistance stub does not raise":
    setCharacterDistance(0, 300.0)
    setCharacterDistance(5, 0.0)

  test "setCharOscActConfig stub does not raise":
    setCharOscActConfig(CharOscActConfigs[2])
