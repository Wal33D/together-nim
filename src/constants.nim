## Core constants for Together

# Physics
const GRAVITY* = 800.0
const FLOAT_GRAVITY* = 320.0       # Luca: 40% gravity
const GRACEFUL_GRAVITY* = 600.0    # Ivy: 75% gravity
const JUMP_VELOCITY* = -380.0
const MAX_FALL_SPEED* = 600.0
const TERMINAL_VELOCITY* = MAX_FALL_SPEED
const GRACEFUL_TERMINAL* = 400.0
const FRICTION* = 0.85
const AIR_RESISTANCE* = 0.95
const MOVE_SPEED* = 165.0
const TIME_SCALE* = 0.83           # Contemplative feel

# Window
const DEFAULT_WIDTH* = 800
const DEFAULT_HEIGHT* = 500
const DEFAULT_WINDOW_WIDTH* = 1120
const DEFAULT_WINDOW_HEIGHT* = 700
const SCANCODE_F11* = 68.cint

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
