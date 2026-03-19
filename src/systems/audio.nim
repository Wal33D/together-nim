## Audio system — procedural sine wave sound effects using SDL2 raw audio callbacks
##
## Compile with -d:withAudio to enable SDL2 audio (used by together.nim).
## Without that flag all procs are harmless no-ops, safe for unit tests.

type
  SoundKind* = enum
    soundJump, soundLand, soundDeath, soundLevelComplete,
    soundCharSwitch, soundExitReached

when defined(withAudio):
  import sdl2
  import sdl2/audio
  import math

  const
    SAMPLE_RATE    = 44100
    BUFFER_SAMPLES = 512
    MAX_INSTANCES  = 16
    FADE_SAMPLES   = (SAMPLE_RATE * 5) div 1000  # 5ms fade to avoid pops

  type
    NoteEnvelope = enum
      envFlat, envDecay

    SoundNote = object
      freqStart: float
      freqEnd: float
      durationSamples: int
      amplitude: float
      envelope: NoteEnvelope

    SoundInstance = object
      active: bool
      notes: array[8, SoundNote]
      noteCount: int
      noteIndex: int
      phase: float
      sampleInNote: int
      totalSamples: int
      samplesPlayed: int

  var
    gInstances: array[MAX_INSTANCES, SoundInstance]
    gAudioOpen = false

  proc audioCallback(userdata: pointer; stream: ptr uint8; len: cint) {.cdecl.} =
    let numSamples = int(len) div 2
    let buf = cast[ptr UncheckedArray[int16]](stream)

    for i in 0..<numSamples:
      buf[i] = 0

    for inst in gInstances.mitems:
      if not inst.active: continue
      for i in 0..<numSamples:
        if not inst.active: break
        let note = inst.notes[inst.noteIndex]

        # Frequency sweep within note
        let noteProgress =
          if note.durationSamples > 0: float(inst.sampleInNote) / float(note.durationSamples)
          else: 0.0
        let freq = note.freqStart + (note.freqEnd - note.freqStart) * noteProgress

        # Amplitude with optional decay envelope
        var amp = note.amplitude
        if note.envelope == envDecay:
          amp *= exp(-6.0 * noteProgress)

        # Global fade-in/out to prevent pops
        if inst.samplesPlayed < FADE_SAMPLES:
          amp *= float(inst.samplesPlayed) / float(FADE_SAMPLES)
        let remaining = inst.totalSamples - inst.samplesPlayed
        if remaining < FADE_SAMPLES:
          amp *= float(remaining) / float(FADE_SAMPLES)

        # Generate and mix sample (saturating add)
        let sample = int32(sin(inst.phase * 2.0 * PI) * amp * 28000.0)
        buf[i] = int16(max(-32767, min(32767, int32(buf[i]) + sample)))

        # Advance oscillator
        inst.phase += freq / float(SAMPLE_RATE)
        if inst.phase >= 1.0: inst.phase -= 1.0
        inc inst.sampleInNote
        inc inst.samplesPlayed

        if inst.sampleInNote >= note.durationSamples:
          inst.sampleInNote = 0
          inc inst.noteIndex
          if inst.noteIndex >= inst.noteCount:
            inst.active = false

  proc initAudio*() =
    var spec: AudioSpec
    spec.freq      = SAMPLE_RATE.cint
    spec.format    = AUDIO_S16
    spec.channels  = 1'u8
    spec.samples   = BUFFER_SAMPLES.uint16
    spec.callback  = audioCallback
    spec.userdata  = nil
    if openAudio(addr spec, nil) < 0:
      echo "Audio init failed: ", sdl2.getError()
      return
    gAudioOpen = true
    pauseAudio(0)

  proc shutdownAudio*() =
    if gAudioOpen:
      closeAudio()
      gAudioOpen = false

  proc playSound*(kind: SoundKind) =
    if not gAudioOpen: return

    var inst: SoundInstance
    inst.phase         = 0.0
    inst.noteIndex     = 0
    inst.sampleInNote  = 0
    inst.samplesPlayed = 0
    inst.noteCount     = 0

    template addNote(f1, f2: float, ms: int, amp: float,
                     env: NoteEnvelope = envFlat) =
      let ni = inst.noteCount
      inst.notes[ni] = SoundNote(
        freqStart: f1, freqEnd: f2,
        durationSamples: (ms * SAMPLE_RATE) div 1000,
        amplitude: amp, envelope: env)
      inc inst.noteCount

    case kind
    of soundJump:
      # Rising tone: 300 → 500 Hz, 80ms
      addNote(300, 500, 80, 0.35)
    of soundLand:
      # Low thud with quick decay: 100 Hz, 50ms
      addNote(100, 100, 50, 0.5, envDecay)
    of soundDeath:
      # Descending tone: 400 → 100 Hz, 200ms
      addNote(400, 100, 200, 0.35)
    of soundLevelComplete:
      # Ascending arpeggio: 300, 400, 500, 600 Hz, 100ms each
      addNote(300, 300, 100, 0.35)
      addNote(400, 400, 100, 0.35)
      addNote(500, 500, 100, 0.35)
      addNote(600, 600, 100, 0.35)
    of soundCharSwitch:
      # Quick click: 800 Hz, 30ms
      addNote(800, 800, 30, 0.3)
    of soundExitReached:
      # Gentle chime: 600 Hz, 150ms
      addNote(600, 600, 150, 0.3)

    inst.totalSamples = 0
    for i in 0..<inst.noteCount:
      inst.totalSamples += inst.notes[i].durationSamples
    inst.active = true

    # Lock audio thread while modifying shared state
    lockAudio()
    block findSlot:
      for slot in gInstances.mitems:
        if not slot.active:
          slot = inst
          break findSlot
      gInstances[0] = inst  # steal oldest slot when full
    unlockAudio()

else:
  # Stub implementations when audio is disabled (unit tests)
  proc initAudio*() = discard
  proc shutdownAudio*() = discard
  proc playSound*(kind: SoundKind) = discard
