import
  std/math

const
  PoolCapacity* = 64

type
  Tween* = object
    startVal*, endVal*: float
    duration*, elapsed*: float
    easing*: proc(t: float): float
    onUpdate*: proc(val: float)
    onComplete*: proc()
    active*: bool

  TweenPool* = object
    tweens: array[PoolCapacity, Tween]
    count: int

proc linear*(t: float): float =
  ## Return t unchanged.
  t

proc easeInOutCubic*(t: float): float =
  ## Cubic ease in-out.
  if t < 0.5:
    4.0 * t * t * t
  else:
    1.0 - pow(-2.0 * t + 2.0, 3.0) / 2.0

proc easeOutCubic*(t: float): float =
  ## Cubic ease out.
  1.0 - pow(1.0 - t, 3.0)

proc easeIn*(t: float): float =
  ## Cubic ease in.
  t * t * t

proc easeOutElastic*(t: float): float =
  ## Elastic ease out with overshoot/spring feel.
  if t == 0.0:
    return 0.0
  if t == 1.0:
    return 1.0
  let c4 = (2.0 * PI) / 3.0
  pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * c4) + 1.0

proc easeOutBounce*(t: float): float =
  ## Bounce ease out.
  const
    n1 = 7.5625
    d1 = 2.75
  if t < 1.0 / d1:
    n1 * t * t
  elif t < 2.0 / d1:
    let t2 = t - 1.5 / d1
    n1 * t2 * t2 + 0.75
  elif t < 2.5 / d1:
    let t2 = t - 2.25 / d1
    n1 * t2 * t2 + 0.9375
  else:
    let t2 = t - 2.625 / d1
    n1 * t2 * t2 + 0.984375

proc initTweenPool*(): TweenPool =
  ## Create an empty tween pool.
  TweenPool(count: 0)

proc startTween*(pool: var TweenPool, startVal, endVal, duration: float,
    easing: proc(t: float): float, onUpdate: proc(val: float),
    onComplete: proc() = nil, delay: float = 0.0): int =
  ## Start a new tween. Returns tween index, or -1 if pool is full.
  # Reuse a completed/cancelled slot first.
  for i in 0..<pool.count:
    if not pool.tweens[i].active:
      pool.tweens[i] = Tween(
        startVal: startVal, endVal: endVal, duration: duration,
        elapsed: -delay, easing: easing, onUpdate: onUpdate,
        onComplete: onComplete, active: true)
      return i
  # No inactive slots — expand if room remains.
  if pool.count >= PoolCapacity:
    return -1
  let idx = pool.count
  pool.tweens[idx] = Tween(
    startVal: startVal, endVal: endVal, duration: duration,
    elapsed: -delay, easing: easing, onUpdate: onUpdate,
    onComplete: onComplete, active: true)
  pool.count += 1
  idx

proc updateTweens*(pool: var TweenPool, dt: float) =
  ## Advance all active tweens, fire callbacks, deactivate completed ones.
  for i in 0..<pool.count:
    if not pool.tweens[i].active:
      continue
    pool.tweens[i].elapsed += dt
    let t = clamp(pool.tweens[i].elapsed / pool.tweens[i].duration, 0.0, 1.0)
    let easedT = pool.tweens[i].easing(t)
    let val = pool.tweens[i].startVal +
        (pool.tweens[i].endVal - pool.tweens[i].startVal) * easedT
    if pool.tweens[i].onUpdate != nil:
      pool.tweens[i].onUpdate(val)
    if t >= 1.0:
      pool.tweens[i].active = false
      if pool.tweens[i].onComplete != nil:
        pool.tweens[i].onComplete()

proc cancelTween*(pool: var TweenPool, id: int) =
  ## Deactivate a tween by index.
  if id >= 0 and id < pool.count:
    pool.tweens[id].active = false

proc isActive*(pool: TweenPool, id: int): bool =
  ## Check if a tween slot is active.
  id >= 0 and id < pool.count and pool.tweens[id].active
