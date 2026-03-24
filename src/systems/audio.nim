## Audio system — procedural sine wave sound effects using macOS AudioQueue
##
## Compile with -d:withAudio to enable CoreAudio output (used by together.nim).
## Without that flag all procs are harmless no-ops, safe for unit tests.

import
  ../constants,
  ../entities/character

type
  SoundKind* = enum
    soundJump, soundLand, soundDeath, soundLevelComplete,
    soundCharSwitch, soundExitReached,
    soundMenuHover, soundMenuSelect, soundMenuBack, soundTransitionSwoosh,
    soundReunion, soundSeparation,
    soundJumpPip, soundJumpLuca, soundJumpBruno,
    soundJumpCara, soundJumpFelix, soundJumpIvy,
    soundJumpPipDouble,
    soundSuperBounce

  MusicStep* = object
    freqStart*, freqEnd*: float
    durationMs*: int
    amplitude*: float

const
  CharJumpSounds*: array[6, SoundKind] = [
    soundJumpPip, soundJumpLuca, soundJumpBruno,
    soundJumpCara, soundJumpFelix, soundJumpIvy
  ]

  MenuHoverFreqs* = [261.6, 329.6, 392.0, 440.0, 523.3]  # C4 E4 G4 A4 C5

proc musicBedPattern*(): seq[MusicStep] =
  ## A short, looping ambient bed with a slow pulse and a higher companion line.
  ##
  ## The runtime mixes this into a continuous loop; tests can inspect the pattern
  ## without needing audio.
  @[
    MusicStep(freqStart: 110.0, freqEnd: 110.0, durationMs: 1200, amplitude: 0.065),
    MusicStep(freqStart: 164.8, freqEnd: 220.0, durationMs: 600, amplitude: 0.035),
    MusicStep(freqStart: 146.8, freqEnd: 146.8, durationMs: 1200, amplitude: 0.060),
    MusicStep(freqStart: 196.0, freqEnd: 246.9, durationMs: 600, amplitude: 0.035),
    MusicStep(freqStart: 123.5, freqEnd: 123.5, durationMs: 1200, amplitude: 0.060),
    MusicStep(freqStart: 174.6, freqEnd: 196.0, durationMs: 600, amplitude: 0.035),
    MusicStep(freqStart: 130.8, freqEnd: 130.8, durationMs: 1200, amplitude: 0.065),
    MusicStep(freqStart: 185.0, freqEnd: 220.0, durationMs: 600, amplitude: 0.035),
  ]

when defined(withAudio):
  import std/math

  {.passL: "-framework AudioToolbox".}

  # -- AudioToolbox FFI bindings ------------------------------------------------

  type
    OpaqueAudioQueue {.importc: "struct OpaqueAudioQueue",
        header: "<AudioToolbox/AudioToolbox.h>", incompleteStruct.} = object
    AudioQueueRef = ptr OpaqueAudioQueue

    AudioQueueBufferObj {.importc: "AudioQueueBuffer",
        header: "<AudioToolbox/AudioToolbox.h>".} = object
      mAudioDataBytesCapacity: uint32
      mAudioData: pointer
      mAudioDataByteSize: uint32

    AudioQueueBufferRef = ptr AudioQueueBufferObj

    AudioStreamBasicDescription {.importc,
        header: "<AudioToolbox/AudioToolbox.h>".} = object
      mSampleRate: float64
      mFormatID: uint32
      mFormatFlags: uint32
      mBytesPerPacket: uint32
      mFramesPerPacket: uint32
      mBytesPerFrame: uint32
      mChannelsPerFrame: uint32
      mBitsPerChannel: uint32
      mReserved: uint32

    AudioQueueOutputCallback = proc(inUserData: pointer, inAQ: AudioQueueRef,
        inBuffer: AudioQueueBufferRef) {.cdecl.}

  const
    kAudioFormatLinearPCM = 0x6C70636D'u32
    kLinearPCMFormatFlagIsSignedInteger = 0x4'u32
    kLinearPCMFormatFlagIsPacked = 0x8'u32

  proc AudioQueueNewOutput(inFormat: ptr AudioStreamBasicDescription,
      inCallbackProc: AudioQueueOutputCallback, inUserData: pointer,
      inCallbackRunLoop, inCallbackRunLoopMode: pointer,
      inFlags: uint32, outAQ: ptr AudioQueueRef): int32 {.importc,
      header: "<AudioToolbox/AudioToolbox.h>".}

  proc AudioQueueAllocateBuffer(inAQ: AudioQueueRef,
      inBufferByteSize: uint32,
      outBuffer: ptr AudioQueueBufferRef): int32 {.importc,
      header: "<AudioToolbox/AudioToolbox.h>".}

  proc AudioQueueEnqueueBuffer(inAQ: AudioQueueRef,
      inBuffer: AudioQueueBufferRef, inNumPacketDescs: uint32,
      inPacketDescs: pointer): int32 {.importc,
      header: "<AudioToolbox/AudioToolbox.h>".}

  proc AudioQueueStart(inAQ: AudioQueueRef,
      inStartTime: pointer): int32 {.importc,
      header: "<AudioToolbox/AudioToolbox.h>".}

  proc AudioQueueStop(inAQ: AudioQueueRef,
      inImmediate: uint8): int32 {.importc,
      header: "<AudioToolbox/AudioToolbox.h>".}

  proc AudioQueueDispose(inAQ: AudioQueueRef,
      inImmediate: uint8): int32 {.importc,
      header: "<AudioToolbox/AudioToolbox.h>".}

  # -- POSIX mutex for audio thread synchronisation -----------------------------

  type
    PthreadMutex {.importc: "pthread_mutex_t",
        header: "<pthread.h>".} = object

  proc pthread_mutex_init(m: ptr PthreadMutex,
      attr: pointer): cint {.importc, header: "<pthread.h>".}
  proc pthread_mutex_lock(m: ptr PthreadMutex
      ): cint {.importc, header: "<pthread.h>".}
  proc pthread_mutex_unlock(m: ptr PthreadMutex
      ): cint {.importc, header: "<pthread.h>".}
  proc pthread_mutex_destroy(m: ptr PthreadMutex
      ): cint {.importc, header: "<pthread.h>".}

  # -- Constants ----------------------------------------------------------------

  const
    SAMPLE_RATE    = 44100
    BUFFER_SAMPLES = 512
    MAX_INSTANCES  = 16
    FADE_SAMPLES   = (SAMPLE_RATE * 5) div 1000  # 5ms fade to avoid pops
    NumBuffers     = 3
    BufferByteSize = BUFFER_SAMPLES * 2  # 16-bit mono

  type
    NoteEnvelope = enum
      envFlat, envDecay, envRampUp, envRampDown

    NoteWaveform = enum
      wfSine, wfNoise

    SoundNote = object
      freqStart: float
      freqEnd: float
      durationSamples: int
      amplitude: float
      envelope: NoteEnvelope
      waveform: NoteWaveform

    SoundInstance = object
      active: bool
      notes: array[8, SoundNote]
      noteCount: int
      noteIndex: int
      phase: float
      sampleInNote: int
      totalSamples: int
      samplesPlayed: int
      filterState: float
      noiseState: uint32

    MusicTrack = object
      active: bool
      pattern: seq[MusicStep]
      stepIndex: int
      sampleInStep: int
      phase: float
      samplesPlayed: int
      totalSamples: int
      pitchScale: float
      ampScale: float

    CharOscillator = object
      phase: float
      targetAmp: float
      currentAmp: float
      vibratoPhase: float
      intermittentPhase: float
      wasNear: bool

  const
    CrossfadeDuration = 2.5
    DefaultPaletteRoot = ActPalettes[0].baseFreqs[0]
    VibratoRate = 5.0
    VibratoDepth = 2.0
    ProximityThreshold = 120.0

  var
    gInstances: array[MAX_INSTANCES, SoundInstance]
    gMusicTracks: array[2, MusicTrack]
    gCharOscillators: array[6, CharOscillator]
    gCharOscActConfig: ActOscParams = ActOscillatorParams[1]
    gAudioOpen = false
    gQueue: AudioQueueRef
    gAudioMutex: PthreadMutex
    gCurrentPalette: TonalPalette = ActPalettes[0]
    gTargetPalette: TonalPalette = ActPalettes[0]
    gPaletteCrossfadeT: float = 1.0
    gCrossfading: bool = false
    gMasterVolume: float = 1.0

  proc durationSamples(step: MusicStep): int =
    max(1, (step.durationMs * SAMPLE_RATE) div 1000)

  proc resetMusicTrack(track: var MusicTrack, pitchScale, ampScale: float, stepOffset: int) =
    track.active = true
    track.pattern = musicBedPattern()
    track.stepIndex = if track.pattern.len > 0: stepOffset mod track.pattern.len else: 0
    track.sampleInStep = 0
    track.phase = 0.0
    track.samplesPlayed = 0
    track.pitchScale = pitchScale
    track.ampScale = ampScale
    track.totalSamples = 0
    for step in track.pattern:
      track.totalSamples += durationSamples(step)

  proc initMusicBed() =
    # Two layers: a lower pulse and a slightly brighter companion line.
    resetMusicTrack(gMusicTracks[0], 1.0, 1.0, 0)
    resetMusicTrack(gMusicTracks[1], 2.0, 0.75, 4)

  proc mixSineSample(baseSample: int32, phase: float, freq, amp: float): int32 =
    let s = int32(sin(phase * 2.0 * PI) * amp * 28000.0)
    max(-32767, min(32767, baseSample + s))

  proc mixMusicTracks(buf: ptr UncheckedArray[int16], numSamples: int): float =
    ## Mix music tracks and return the current palette scale factor.
    var paletteScale: float
    if gCrossfading:
      gPaletteCrossfadeT += float(numSamples) / (CrossfadeDuration * float(SAMPLE_RATE))
      if gPaletteCrossfadeT >= 1.0:
        gPaletteCrossfadeT = 1.0
        gCurrentPalette = gTargetPalette
        gCrossfading = false
      let blendedRoot = gCurrentPalette.baseFreqs[0] +
        (gTargetPalette.baseFreqs[0] - gCurrentPalette.baseFreqs[0]) * gPaletteCrossfadeT
      paletteScale = blendedRoot / DefaultPaletteRoot
    else:
      paletteScale = gCurrentPalette.baseFreqs[0] / DefaultPaletteRoot

    for track in gMusicTracks.mitems:
      if not track.active or track.pattern.len == 0:
        continue
      for i in 0..<numSamples:
        if not track.active:
          break

        let step = track.pattern[track.stepIndex]
        let stepDuration = durationSamples(step)
        let noteProgress =
          if stepDuration > 0: float(track.sampleInStep) / float(stepDuration)
          else: 0.0
        let freq = (step.freqStart + (step.freqEnd - step.freqStart) * noteProgress) * track.pitchScale * paletteScale
        var amp = step.amplitude * track.ampScale

        # Gentle fade at loop boundaries to avoid clicks.
        if track.samplesPlayed < FADE_SAMPLES:
          amp *= float(track.samplesPlayed) / float(FADE_SAMPLES)
        let remaining = track.totalSamples - track.samplesPlayed
        if remaining < FADE_SAMPLES:
          amp *= float(remaining) / float(FADE_SAMPLES)

        let mixed = mixSineSample(int32(buf[i]), track.phase, freq, amp)
        buf[i] = int16(mixed)

        track.phase += freq / float(SAMPLE_RATE)
        if track.phase >= 1.0:
          track.phase -= 1.0
        inc track.sampleInStep
        inc track.samplesPlayed

        if track.sampleInStep >= stepDuration:
          track.sampleInStep = 0
          inc track.stepIndex
          if track.stepIndex >= track.pattern.len:
            track.stepIndex = 0
            track.samplesPlayed = 0
          if track.stepIndex < track.pattern.len:
            track.phase *= 0.9
    return paletteScale

  proc mixCharOscillators(buf: ptr UncheckedArray[int16], numSamples: int, paletteScale: float) =
    ## Mix per-character sine oscillators into the buffer.
    let bufSeconds = float(numSamples) / float(SAMPLE_RATE)
    let lerpFactor = min(1.0, 2.0 * bufSeconds)
    let intermittentCycleSec = gCharOscActConfig.onDuration + gCharOscActConfig.offDuration
    for idx in 0..<6:
      var osc = addr gCharOscillators[idx]
      osc.currentAmp += (osc.targetAmp - osc.currentAmp) * lerpFactor
      if osc.currentAmp < 0.0001:
        # Advance phases even when silent to avoid discontinuity on re-entry.
        if intermittentCycleSec > 0.0:
          osc.intermittentPhase += bufSeconds / intermittentCycleSec
          if osc.intermittentPhase >= 1.0:
            osc.intermittentPhase -= 1.0
        continue
      var baseFreq = DefaultPaletteRoot * CharFreqRatios[idx] * paletteScale
      # Apply dissonance shift to the designated character (e.g. Act 4 tritone).
      if gCharOscActConfig.dissonanceIdx == idx and gCharOscActConfig.dissonanceSemitones != 0.0:
        baseFreq *= pow(2.0, gCharOscActConfig.dissonanceSemitones / 12.0)
      for i in 0..<numSamples:
        let freq = baseFreq + VibratoDepth * sin(osc.vibratoPhase * 2.0 * PI)
        let s = int32(sin(osc.phase * 2.0 * PI) * osc.currentAmp * 28000.0)
        buf[i] = int16(max(-32767, min(32767, int32(buf[i]) + s)))
        osc.phase += freq / float(SAMPLE_RATE)
        if osc.phase >= 1.0:
          osc.phase -= 1.0
        osc.vibratoPhase += VibratoRate / float(SAMPLE_RATE)
        if osc.vibratoPhase >= 1.0:
          osc.vibratoPhase -= 1.0
      if intermittentCycleSec > 0.0:
        osc.intermittentPhase += bufSeconds / intermittentCycleSec
        if osc.intermittentPhase >= 1.0:
          osc.intermittentPhase -= 1.0

  proc setCharacterActive*(charIdx: int, active: bool) =
    ## Immediately mute a character oscillator when inactive (dying/respawning).
    if not gAudioOpen: return
    if charIdx < 0 or charIdx > 5: return
    discard pthread_mutex_lock(addr gAudioMutex)
    if not active:
      gCharOscillators[charIdx].targetAmp = 0.0
    discard pthread_mutex_unlock(addr gAudioMutex)

  proc setCharacterDistance*(charIdx: int, distToNearest: float) =
    ## Set the target amplitude for a character oscillator based on proximity.
    ## Plays reunion chime or separation sigh on threshold crossings.
    if not gAudioOpen: return
    if charIdx < 0 or charIdx > 5: return
    discard pthread_mutex_lock(addr gAudioMutex)
    let isNear = distToNearest <= ProximityThreshold
    let wasNear = gCharOscillators[charIdx].wasNear
    var triggerReunion = false
    var triggerSeparation = false
    if isNear and not wasNear:
      triggerReunion = true
    elif not isNear and wasNear:
      triggerSeparation = true
    gCharOscillators[charIdx].wasNear = isNear
    let ampMul = gCharOscActConfig.ampMultiplier
    let cycleSec = gCharOscActConfig.onDuration + gCharOscActConfig.offDuration
    if distToNearest > 200.0:
      # Intermittent faint tone when far away.
      let onFraction = if cycleSec > 0.0: gCharOscActConfig.onDuration / cycleSec else: 0.5
      let inOnWindow = gCharOscillators[charIdx].intermittentPhase < onFraction
      if inOnWindow:
        gCharOscillators[charIdx].targetAmp = 0.03 * ampMul
      else:
        gCharOscillators[charIdx].targetAmp = 0.0
    else:
      # Scale 0.03..0.10 as distance goes from 200 to 0.
      gCharOscillators[charIdx].targetAmp =
        (0.03 + 0.07 * (1.0 - distToNearest / 200.0)) * ampMul
    discard pthread_mutex_unlock(addr gAudioMutex)
    # Fire threshold-crossing sounds outside the lock to avoid nesting.
    if triggerReunion:
      playSound(soundReunion)
    elif triggerSeparation:
      playSound(soundSeparation)

  proc aqCallback(inUserData: pointer, inAQ: AudioQueueRef,
      inBuffer: AudioQueueBufferRef) {.cdecl.} =
    ## AudioQueue output callback — fills the buffer and re-enqueues it.
    let numSamples = int(inBuffer.mAudioDataBytesCapacity) div 2
    let buf = cast[ptr UncheckedArray[int16]](inBuffer.mAudioData)

    for i in 0..<numSamples:
      buf[i] = 0

    discard pthread_mutex_lock(addr gAudioMutex)

    let paletteScale = mixMusicTracks(buf, numSamples)
    mixCharOscillators(buf, numSamples, paletteScale)

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

        # Amplitude with envelope
        var amp = note.amplitude
        case note.envelope
        of envFlat: discard
        of envDecay: amp *= exp(-6.0 * noteProgress)
        of envRampUp: amp *= noteProgress
        of envRampDown: amp *= (1.0 - noteProgress)

        # Global fade-in/out to prevent pops
        if inst.samplesPlayed < FADE_SAMPLES:
          amp *= float(inst.samplesPlayed) / float(FADE_SAMPLES)
        let remaining = inst.totalSamples - inst.samplesPlayed
        if remaining < FADE_SAMPLES:
          amp *= float(remaining) / float(FADE_SAMPLES)

        # Generate sample based on waveform
        var rawSample: float
        case note.waveform
        of wfSine:
          rawSample = sin(inst.phase * 2.0 * PI)
          inst.phase += freq / float(SAMPLE_RATE)
          if inst.phase >= 1.0: inst.phase -= 1.0
        of wfNoise:
          inst.noiseState = inst.noiseState xor (inst.noiseState shl 13)
          inst.noiseState = inst.noiseState xor (inst.noiseState shr 17)
          inst.noiseState = inst.noiseState xor (inst.noiseState shl 5)
          let noiseVal = float(cast[int32](inst.noiseState)) / float(high(int32))
          let coeff = min(1.0, 2.0 * PI * freq / float(SAMPLE_RATE))
          inst.filterState = inst.filterState * (1.0 - coeff) + noiseVal * coeff
          rawSample = inst.filterState

        # Mix sample (saturating add)
        let sample = int32(rawSample * amp * 28000.0)
        buf[i] = int16(max(-32767, min(32767, int32(buf[i]) + sample)))
        inc inst.sampleInNote
        inc inst.samplesPlayed

        if inst.sampleInNote >= note.durationSamples:
          inst.sampleInNote = 0
          inc inst.noteIndex
          if inst.noteIndex >= inst.noteCount:
            inst.active = false

    # Apply master volume to the final mix.
    if gMasterVolume < 1.0:
      for i in 0..<numSamples:
        buf[i] = int16(float(buf[i]) * gMasterVolume)

    discard pthread_mutex_unlock(addr gAudioMutex)

    inBuffer.mAudioDataByteSize = inBuffer.mAudioDataBytesCapacity
    discard AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil)

  proc initAudio*() =
    discard pthread_mutex_init(addr gAudioMutex, nil)
    initMusicBed()

    var fmt: AudioStreamBasicDescription
    fmt.mSampleRate = float64(SAMPLE_RATE)
    fmt.mFormatID = kAudioFormatLinearPCM
    fmt.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger or
        kLinearPCMFormatFlagIsPacked
    fmt.mBytesPerPacket = 2
    fmt.mFramesPerPacket = 1
    fmt.mBytesPerFrame = 2
    fmt.mChannelsPerFrame = 1
    fmt.mBitsPerChannel = 16
    fmt.mReserved = 0

    var status = AudioQueueNewOutput(addr fmt, aqCallback, nil, nil, nil, 0,
        addr gQueue)
    if status != 0:
      echo "Audio init failed: OSStatus " & $status
      return

    # Allocate and prime triple buffers.
    for i in 0..<NumBuffers:
      var buffer: AudioQueueBufferRef
      status = AudioQueueAllocateBuffer(gQueue, BufferByteSize.uint32,
          addr buffer)
      if status != 0:
        echo "Audio buffer alloc failed: OSStatus " & $status
        return
      aqCallback(nil, gQueue, buffer)

    status = AudioQueueStart(gQueue, nil)
    if status != 0:
      echo "Audio start failed: OSStatus " & $status
      return

    gAudioOpen = true

  proc shutdownAudio*() =
    if gAudioOpen:
      discard AudioQueueStop(gQueue, 1)
      discard AudioQueueDispose(gQueue, 1)
      discard pthread_mutex_destroy(addr gAudioMutex)
      gAudioOpen = false

  proc playSound*(kind: SoundKind) =
    if not gAudioOpen: return

    var inst: SoundInstance
    inst.phase         = 0.0
    inst.noteIndex     = 0
    inst.sampleInNote  = 0
    inst.samplesPlayed = 0
    inst.noteCount     = 0
    inst.filterState   = 0.0
    inst.noiseState    = 0xDEADBEEF'u32

    template addNote(f1, f2: float, ms: int, amp: float,
                     env: NoteEnvelope = envFlat,
                     wf: NoteWaveform = wfSine) =
      let ni = inst.noteCount
      inst.notes[ni] = SoundNote(
        freqStart: f1, freqEnd: f2,
        durationSamples: (ms * SAMPLE_RATE) div 1000,
        amplitude: amp, envelope: env, waveform: wf)
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
    of soundMenuHover:
      # Subtle tick: 200 Hz sine, 15ms, fast exponential decay
      addNote(200, 200, 15, 0.25, envDecay)
    of soundMenuSelect:
      # Ascending confirmation: 400→600 Hz sweep, 40ms, linear ramp up
      addNote(400, 600, 40, 0.3, envRampUp)
    of soundMenuBack:
      # Descending cancel: 300→200 Hz sweep, 40ms, linear ramp down
      addNote(300, 200, 40, 0.3, envRampDown)
    of soundTransitionSwoosh:
      # Filtered noise swoosh: lowpass sweep 800→200 Hz, 200ms, decay envelope
      addNote(800, 200, 200, 0.35, envDecay, wfNoise)
    of soundReunion:
      # Warm ascending chime: two gentle tones that bloom together.
      addNote(392, 523.3, 120, 0.25, envRampUp)
      addNote(523.3, 659.3, 150, 0.20, envDecay)
    of soundSeparation:
      # Soft descending sigh: a falling tone that fades away.
      addNote(440, 330, 180, 0.20, envDecay)
      addNote(330, 220, 140, 0.12, envRampDown)
    of soundJumpPip:
      # High bouncy chirp: 600→800 Hz, 60ms, quick decay.
      addNote(600, 800, 60, 0.35, envDecay)
    of soundJumpPipDouble:
      # Same chirp pitched up 20%: 720→960 Hz, 60ms, quick decay.
      addNote(720, 960, 60, 0.35, envDecay)
    of soundJumpLuca:
      # Airy rising sweep: 250→500 Hz, 100ms, ramp up.
      addNote(250, 500, 100, 0.30, envRampUp)
    of soundJumpBruno:
      # Deep thud: 150 Hz base, 40ms, slight downward sweep.
      addNote(200, 140, 40, 0.45, envDecay)
    of soundJumpCara:
      # Sharp quick whistle: 900→1200 Hz, 50ms, decay.
      addNote(900, 1200, 50, 0.30, envDecay)
    of soundJumpFelix:
      # Mellow tone: 300 Hz, 35ms, flat envelope.
      addNote(300, 300, 35, 0.30, envFlat)
    of soundJumpIvy:
      # Gentle bell: 440 Hz fundamental with 880 Hz octave harmonic, 45ms, soft decay.
      addNote(440, 440, 45, 0.25, envDecay)
      addNote(880, 880, 45, 0.12, envDecay)
    of soundSuperBounce:
      # Layered spring+thud: low thud then rising spring tone.
      addNote(100, 100, 30, 0.08, envDecay)
      addNote(300, 700, 50, 0.06, envDecay)

    inst.totalSamples = 0
    for i in 0..<inst.noteCount:
      inst.totalSamples += inst.notes[i].durationSamples
    inst.active = true

    # Lock audio thread while modifying shared state
    discard pthread_mutex_lock(addr gAudioMutex)
    block findSlot:
      for slot in gInstances.mitems:
        if not slot.active:
          slot = inst
          break findSlot
      gInstances[0] = inst  # steal oldest slot when full
    discard pthread_mutex_unlock(addr gAudioMutex)

  proc playLandingSound*(fallVelocity: float, ability: CharacterAbility) =
    ## Play a landing thud scaled by fall velocity and character weight.
    if not gAudioOpen: return
    let speed = abs(fallVelocity)
    if speed < 100.0: return
    let intensity = clamp((speed - 100.0) / 400.0, 0.0, 1.0)
    var baseFreq = 180.0 + 60.0 * intensity
    let durationMs = int(30.0 + 20.0 * intensity)
    var amplitude = 0.3 + 0.5 * intensity
    case ability
    of heavy:
      amplitude *= 1.3
      baseFreq -= 30.0
    of doubleJump:
      amplitude *= 0.7
    else: discard

    var inst: SoundInstance
    inst.phase         = 0.0
    inst.noteIndex     = 0
    inst.sampleInNote  = 0
    inst.samplesPlayed = 0
    inst.noteCount     = 0
    inst.filterState   = 0.0
    inst.noiseState    = 0xDEADBEEF'u32

    let ni = inst.noteCount
    inst.notes[ni] = SoundNote(
      freqStart: baseFreq, freqEnd: baseFreq,
      durationSamples: (durationMs * SAMPLE_RATE) div 1000,
      amplitude: amplitude, envelope: envDecay, waveform: wfSine)
    inc inst.noteCount

    inst.totalSamples = inst.notes[0].durationSamples
    inst.active = true

    discard pthread_mutex_lock(addr gAudioMutex)
    block findSlot:
      for slot in gInstances.mitems:
        if not slot.active:
          slot = inst
          break findSlot
      gInstances[0] = inst
    discard pthread_mutex_unlock(addr gAudioMutex)

  proc playMenuHoverNote*(buttonIndex: int) =
    ## Play a musical note for the given menu button index (3-stage envelope).
    if not gAudioOpen: return
    let idx = clamp(buttonIndex, 0, MenuHoverFreqs.high)
    let freq = MenuHoverFreqs[idx]

    var inst: SoundInstance
    inst.phase         = 0.0
    inst.noteIndex     = 0
    inst.sampleInNote  = 0
    inst.samplesPlayed = 0
    inst.noteCount     = 0
    inst.filterState   = 0.0
    inst.noiseState    = 0xDEADBEEF'u32

    template addNote(f1, f2: float, ms: int, amp: float,
                     env: NoteEnvelope = envFlat,
                     wf: NoteWaveform = wfSine) =
      let ni = inst.noteCount
      inst.notes[ni] = SoundNote(
        freqStart: f1, freqEnd: f2,
        durationSamples: (ms * SAMPLE_RATE) div 1000,
        amplitude: amp, envelope: env, waveform: wf)
      inc inst.noteCount

    # 5ms attack ramp-up, 80ms flat sustain, 40ms exponential decay.
    addNote(freq, freq, 5, 0.15, envRampUp)
    addNote(freq, freq, 80, 0.15, envFlat)
    addNote(freq, freq, 40, 0.15, envDecay)

    inst.totalSamples = 0
    for i in 0..<inst.noteCount:
      inst.totalSamples += inst.notes[i].durationSamples
    inst.active = true

    discard pthread_mutex_lock(addr gAudioMutex)
    block findSlot:
      for slot in gInstances.mitems:
        if not slot.active:
          slot = inst
          break findSlot
      gInstances[0] = inst
    discard pthread_mutex_unlock(addr gAudioMutex)

  proc setActOscConfig*(config: ActOscParams) =
    ## Store per-act oscillator configuration, applied in next buffer fill.
    if not gAudioOpen: return
    discard pthread_mutex_lock(addr gAudioMutex)
    gCharOscActConfig = config
    discard pthread_mutex_unlock(addr gAudioMutex)

  proc setActPalette*(palette: TonalPalette) =
    ## Start a crossfade to the given tonal palette if it differs from the current one.
    if not gAudioOpen: return
    discard pthread_mutex_lock(addr gAudioMutex)
    if palette.name != gCurrentPalette.name:
      gTargetPalette = palette
      gPaletteCrossfadeT = 0.0
      gCrossfading = true
    discard pthread_mutex_unlock(addr gAudioMutex)

  proc setMasterVolume*(vol: float) =
    ## Set master volume, clamped to 0.0..1.0.
    discard pthread_mutex_lock(addr gAudioMutex)
    gMasterVolume = clamp(vol, 0.0, 1.0)
    discard pthread_mutex_unlock(addr gAudioMutex)

  proc getMasterVolume*(): float =
    ## Return the current master volume.
    result = gMasterVolume

else:
  # Stub implementations when audio is disabled (unit tests)
  proc initAudio*() = discard
  proc shutdownAudio*() = discard
  proc playSound*(kind: SoundKind) = discard
  proc playLandingSound*(fallVelocity: float, ability: CharacterAbility) = discard
  proc playMenuHoverNote*(buttonIndex: int) = discard
  proc setActPalette*(palette: TonalPalette) = discard
  proc setActOscConfig*(config: ActOscParams) = discard
  proc setCharacterActive*(charIdx: int, active: bool) = discard
  proc setCharacterDistance*(charIdx: int, distToNearest: float) = discard
  proc setMasterVolume*(vol: float) = discard
  proc getMasterVolume*(): float = 1.0
