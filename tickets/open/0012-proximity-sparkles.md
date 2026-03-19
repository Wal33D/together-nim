# Add proximity sparkle particles between nearby characters

**Area:** effects
**Depends:** 0011

Extend `src/systems/particles.nim`:
- `emitProximitySparkle(emitter, x, y, color)` proc — spawn 1–3 small bright particles rising upward (used for sparkle effect)
- `updateProximitySparkles(emitter, characters, dt)` proc — for each pair of characters within 80px of each other, periodically call `emitProximitySparkle` at the midpoint between them; throttle to at most one burst per 0.4 seconds per pair to avoid flooding

## Acceptance criteria
- Sparkles appear between two characters standing close together
- Sparkles do not appear when characters are far apart
- Rate limiting prevents particle count explosion
- Unit test: two characters at distance 60 trigger sparkle emission; two at distance 200 do not
- `make test` passes
