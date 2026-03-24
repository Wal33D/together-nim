## Core constants for Together

# Physics
const GRAVITY* = 800.0
const FLOAT_GRAVITY* = 320.0       # Luca: 40% gravity
const GRACEFUL_GRAVITY* = 600.0    # Ivy: 75% gravity
const JUMP_VELOCITY* = -380.0
const MAX_FALL_SPEED* = 600.0
const TERMINAL_VELOCITY* = MAX_FALL_SPEED
const GRACEFUL_TERMINAL* = 400.0
const GroundAccelTime* = 0.08   # Seconds to reach max speed from stop.
const GroundDecelTime* = 0.05   # Seconds to decelerate to stop.
const AirControlFactor* = 0.6   # Fraction of ground acceleration available in air.
const MOVE_SPEED* = 165.0
const TIME_SCALE* = 0.83           # Contemplative feel

# Window
const DEFAULT_WIDTH* = 800
const DEFAULT_HEIGHT* = 500
const DEFAULT_WINDOW_WIDTH* = 1120
const DEFAULT_WINDOW_HEIGHT* = 700

# Window presets for settings screen
const WindowPresets*: array[4, tuple[w, h: int]] = [
  (800, 500), (1120, 700), (1440, 900), (1920, 1200)
]

# Save file
const SAVE_FILE* = "together_save.json"

# Timing
const FIXED_TIMESTEP* = 1.0 / 60.0

# Coyote & jump buffer
const COYOTE_TIME* = 0.14          # 140ms grace period
const FELIX_COYOTE_TIME* = 0.25    # 250ms for Felix
const JUMP_BUFFER_TIME* = 0.14
const JUMP_CUT_FACTOR* = 0.55

# Character colors (matching original)
type Color* = tuple[r, g, b: uint8]

const PIP_COLOR*:   Color = (r: 255'u8, g: 107'u8, b: 157'u8)  # #FF6B9D
const LUCA_COLOR*:  Color = (r: 255'u8, g: 217'u8, b:  61'u8)  # #FFD93D
const BRUNO_COLOR*: Color = (r: 107'u8, g:  68'u8, b:  35'u8)  # #6B4423
const CARA_COLOR*:  Color = (r: 255'u8, g: 159'u8, b: 243'u8)  # #FF9FF3
const FELIX_COLOR*: Color = (r: 212'u8, g: 165'u8, b: 116'u8)  # #D4A574
const IVY_COLOR*:   Color = (r: 168'u8, g: 216'u8, b: 234'u8)  # #A8D8EA

const BG_COLOR*: Color = (r: 26'u8, g: 26'u8, b: 46'u8)

# Ordered palette for consistent color lookup by index
const CHAR_COLORS*: array[6, Color] = [
  PIP_COLOR, LUCA_COLOR, BRUNO_COLOR, CARA_COLOR, FELIX_COLOR, IVY_COLOR
]

# Default character dimensions (used for AABB when per-character size is unavailable)
const CHAR_WIDTH*  = 24
const CHAR_HEIGHT* = 24

# Combo interaction system
const ComboPairs*: array[3, tuple[a, b: int]] = [
  (0, 2),  # Pip + Bruno
  (3, 1),  # Cara + Luca
  (4, 5),  # Felix + Ivy
]
const ComboCooldownTime* = 0.5
const ComboJumpMultiplier* = 1.4
const ComboProximity* = 40.0
const SuperBounceMultiplier* = 1.5
const WallFloatRelaySpeedCap* = 60.0      # px/s — slowed wall-slide cap during relay
const WallFloatRelayMaxHorizDist* = 60.0  # px — horizontal alignment window

# Tonal palettes for per-act ambient music
type
  TonalPalette* = object
    baseFreqs*: array[3, float]
    name*: string

# Frequency ratios relative to palette root for per-character oscillators.
# Act 1 root is C4 (261.6 Hz); ratio × root gives each character's note.
const CharFreqRatios*: array[6, float] = [
  2.0,    # Pip: C5 (523.3 Hz) — bright, curious
  1.26,   # Luca: E4 (329.6 Hz) — dreamy
  0.5,    # Bruno: C3 (130.8 Hz) — grounding
  1.888,  # Cara: B4 (493.9 Hz) — nimble
  1.123,  # Felix: D4 (293.7 Hz) — patient
  1.682,  # Ivy: A4 (440.0 Hz) — graceful
]

const ActPalettes*: array[5, TonalPalette] = [
  TonalPalette(baseFreqs: [261.6, 329.6, 392.0], name: "C major"),      # Act 1
  TonalPalette(baseFreqs: [349.2, 440.0, 523.3], name: "F major"),      # Act 2
  TonalPalette(baseFreqs: [293.7, 349.2, 440.0], name: "D minor"),      # Act 3
  TonalPalette(baseFreqs: [220.0, 261.6, 329.6], name: "A minor"),      # Act 4
  TonalPalette(baseFreqs: [261.6, 392.0, 0.0],   name: "C open fifth"), # Act 5
]

# Per-act oscillator configuration for emotional arc audio progression.
type
  ActOscParams* = object
    ampMultiplier*: float         ## Scales all character oscillator targetAmps.
    onDuration*: float            ## Seconds oscillator stays on (lonely state).
    offDuration*: float           ## Seconds oscillator stays off (lonely state).
    dissonanceIdx*: int           ## Character index to detune (-1 = none).
    dissonanceSemitones*: float   ## Semitones to shift (0.0 = none).

const ActOscillatorParams*: array[1..5, ActOscParams] = [
  # Act 1 — Awakening: sparse, lonely
  ActOscParams(ampMultiplier: 0.50, onDuration: 1.5, offDuration: 6.0,
               dissonanceIdx: -1, dissonanceSemitones: 0.0),
  # Act 2 — Belonging: notes find each other
  ActOscParams(ampMultiplier: 0.70, onDuration: 2.0, offDuration: 3.0,
               dissonanceIdx: -1, dissonanceSemitones: 0.0),
  # Act 3 — Challenge: rhythmic confidence
  ActOscParams(ampMultiplier: 0.90, onDuration: 3.0, offDuration: 2.0,
               dissonanceIdx: -1, dissonanceSemitones: 0.0),
  # Act 4 — Separation: tension, one voice detuned by a tritone (6 semitones)
  ActOscParams(ampMultiplier: 1.00, onDuration: 2.0, offDuration: 3.0,
               dissonanceIdx: 2, dissonanceSemitones: 6.0),
  # Act 5 — Transcendence: consonant resolution, full warmth
  ActOscParams(ampMultiplier: 1.00, onDuration: 3.0, offDuration: 1.0,
               dissonanceIdx: -1, dissonanceSemitones: 0.0),
]
