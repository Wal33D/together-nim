import unittest
import "../src/systems/animation"

suite "easing functions":
  test "linear returns t unchanged":
    check linear(0.0) == 0.0
    check linear(0.5) == 0.5
    check linear(1.0) == 1.0

  test "easeOutCubic boundaries":
    check easeOutCubic(0.0) == 0.0
    check easeOutCubic(1.0) == 1.0
    check easeOutCubic(0.5) > 0.5

  test "easeIn boundaries":
    check easeIn(0.0) == 0.0
    check easeIn(1.0) == 1.0
    check easeIn(0.5) < 0.5

  test "easeInOutCubic boundaries":
    check easeInOutCubic(0.0) == 0.0
    check easeInOutCubic(1.0) == 1.0
    check abs(easeInOutCubic(0.5) - 0.5) < 0.001

  test "easeOutElastic boundaries":
    check easeOutElastic(0.0) == 0.0
    check easeOutElastic(1.0) == 1.0

  test "easeOutBounce boundaries":
    check easeOutBounce(0.0) == 0.0
    check abs(easeOutBounce(1.0) - 1.0) < 0.001

suite "tween lifecycle":
  test "tween from 0 to 1 over 1s with easeOutCubic":
    var lastVal = -1.0
    var completed = false
    var pool = initTweenPool()
    let idx = startTween(pool, 0.0, 1.0, 1.0, easeOutCubic,
        proc(v: float) = lastVal = v,
        proc() = completed = true)
    check idx >= 0
    check pool.isActive(idx)

    # Half-step: value should match easeOutCubic(0.5).
    updateTweens(pool, 0.5)
    let expected = easeOutCubic(0.5)
    check abs(lastVal - expected) < 0.001
    check not completed
    check pool.isActive(idx)

    # Complete the tween.
    updateTweens(pool, 0.5)
    check abs(lastVal - 1.0) < 0.001
    check completed
    check not pool.isActive(idx)

  test "cancelTween deactivates mid-flight":
    var pool = initTweenPool()
    let idx = startTween(pool, 0.0, 100.0, 2.0, linear,
        proc(v: float) = discard, nil)
    check pool.isActive(idx)
    cancelTween(pool, idx)
    check not pool.isActive(idx)

  test "pool full returns -1":
    var pool = initTweenPool()
    for i in 0..<64:
      let idx = startTween(pool, 0.0, 1.0, 10.0, linear,
          proc(v: float) = discard, nil)
      check idx == i
    let overflow = startTween(pool, 0.0, 1.0, 1.0, linear,
        proc(v: float) = discard, nil)
    check overflow == -1

  test "completed slots are reused":
    var pool = initTweenPool()
    let idx1 = startTween(pool, 0.0, 1.0, 0.1, linear,
        proc(v: float) = discard, nil)
    updateTweens(pool, 0.1)
    check not pool.isActive(idx1)
    let idx2 = startTween(pool, 0.0, 1.0, 0.1, linear,
        proc(v: float) = discard, nil)
    check idx2 == idx1

  test "onComplete enables chaining":
    var pool = initTweenPool()
    var chainedStarted = false
    discard startTween(pool, 0.0, 1.0, 0.5, linear,
        proc(v: float) = discard,
        proc() =
          chainedStarted = true
          discard startTween(pool, 1.0, 2.0, 0.5, linear,
              proc(v: float) = discard, nil))
    updateTweens(pool, 0.5)
    check chainedStarted
