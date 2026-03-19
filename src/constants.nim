## Core constants for Together

# Physics
const GRAVITY* = 980.0
const JUMP_VELOCITY* = -450.0
const MAX_FALL_SPEED* = 800.0
const TERMINAL_VELOCITY* = MAX_FALL_SPEED

# Window
const DEFAULT_WIDTH* = 1280
const DEFAULT_HEIGHT* = 720

# Timing
const FIXED_TIMESTEP* = 1.0 / 60.0

# Character dimensions
const CHAR_WIDTH* = 32
const CHAR_HEIGHT* = 48

# Character colors (R, G, B) for 6 characters
type Color* = tuple[r, g, b: uint8]

const CHAR_COLORS*: array[6, Color] = [
  (r: 220'u8, g:  60'u8, b:  60'u8),  # 0: Red
  (r:  60'u8, g: 120'u8, b: 220'u8),  # 1: Blue
  (r:  60'u8, g: 200'u8, b:  80'u8),  # 2: Green
  (r: 220'u8, g: 180'u8, b:  40'u8),  # 3: Yellow
  (r: 180'u8, g:  60'u8, b: 220'u8),  # 4: Purple
  (r: 220'u8, g: 140'u8, b:  40'u8),  # 5: Orange
]
