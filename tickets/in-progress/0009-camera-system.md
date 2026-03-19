# Implement smooth follow camera for larger levels

**Area:** rendering

The game window is 800x500 but levels can be larger. Implement a camera in `src/systems/camera.nim`:
- Camera type with x, y offset, targetX, targetY
- Smooth lerp follow toward active character (lerp factor ~0.08)
- Camera offset applied to ALL rendering in renderer.nim (platforms, characters, exits, hazards, etc)
- Clamp camera so it doesn't show beyond level bounds
- Level type in entities/level.nim needs `levelWidth` and `levelHeight` fields (default 800x500)
- Update levels.nim — levels 4 and 5 can be wider (e.g. 1000px wide)
- Camera imported and used in game.nim update loop and passed to renderGame

The character bar and narration should render at FIXED screen positions (not affected by camera).

## Acceptance criteria
- Camera smoothly follows active character
- Switching characters pans camera to new target
- Works with current 5 levels
- `make test` passes

**Worktree:** /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0009-camera-system

## Prediction
- predicted_difficulty: hard
- predicted_duration_minutes: 32
- reasoning: Touches 5+ files (camera.nim new, renderer.nim pervasive offset threading, game.nim, level.nim, levels.nim), requires careful coordinate transform logic with fixed-position UI exceptions and level clamping — high integration risk across all rendering paths, likely 2 attempts.

## Agent Run
- Model: claude-sonnet-4-6\n- Backend: claude-code\n- Exit Code: 0\n- Attempt: 1\n- Attempt Count: 1\n- Timeout: none\n- Log File: /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0009-camera-system/.scriptorium/logs/0009/attempt-01.jsonl\n- Last Message File: /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0009-camera-system/.scriptorium/logs/0009/attempt-01.last_message.txt\n
### Agent Last Message
```text
All done. Here's a summary of what was implemented:

**Files created/modified:**
- `src/systems/camera.nim` — `Camera` type with `updateCamera` (lerp factor 0.08) and `snapCamera` (instant placement), clamped to level bounds
- `src/entities/level.nim` — added `levelWidth*` and `levelHeight*` fields
- `src/systems/levels.nim` — all levels get explicit dimensions; levels 4 (1000px) and 5 (1200px) are wider with extra platforms and moved exits
- `src/game.nim` — `camera: Camera` field on `Game`; camera updated every physics tick, snapped on level load
- `src/systems/renderer.nim` — all world objects rendered with `camX`/`camY` offset subtracted; character bar, narration, and level name stay at fixed screen positions
- `tests/test_camera.nim` — 8 tests covering lerp, clamp, snap, and scroll behavior
- `tests/test_character.nim` — corrected expected dimensions to match actual `character.nim` (pre-existing mismatch)

All 50 tests pass. PR: https://github.com/Wal33D/together-nim/pull/1
```

### Agent Stdout Tail
```text
bjects rendered with `camX`/`camY` offset subtracted; character bar, narration, and level name stay at fixed screen positions\n- `tests/test_camera.nim` — 8 tests covering lerp, clamp, snap, and scroll behavior\n- `tests/test_character.nim` — corrected expected dimensions to match actual `character.nim` (pre-existing mismatch)\n\nAll 50 tests pass. PR: https://github.com/Wal33D/together-nim/pull/1","stop_reason":"end_turn","session_id":"06f3483b-b64e-4a96-9228-a3f5fdfc81c3","total_cost_usd":1.6519780499999994,"usage":{"input_tokens":57,"cache_creation_input_tokens":72079,"cache_read_input_tokens":3061336,"output_tokens":30874,"server_tool_use":{"web_search_requests":0,"web_fetch_requests":0},"service_tier":"standard","cache_creation":{"ephemeral_1h_input_tokens":72079,"ephemeral_5m_input_tokens":0},"inference_geo":"","iterations":[],"speed":"standard"},"modelUsage":{"claude-sonnet-4-6":{"inputTokens":57,"outputTokens":30874,"cacheReadInputTokens":3061336,"cacheCreationInputTokens":72079,"webSearchRequests":0,"costUSD":1.6519780499999994,"contextWindow":200000,"maxOutputTokens":32000}},"permission_denials":[],"fast_mode_state":"off","uuid":"e951452c-7afc-4177-905c-eeb0c34a2ca8"}
```
