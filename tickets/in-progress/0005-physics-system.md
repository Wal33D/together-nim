# Implement physics and collision detection

**Area:** physics
**Depends:** 0001, 0002, 0003

Implement `src/systems/physics.nim`:
- `updatePhysics(characters, level, dt)` proc
- Apply gravity to all characters (vy += GRAVITY * dt)
- AABB collision detection: `intersects(a, b: Rect): bool`
- Platform collision resolution: stop falling when landing on platform, block horizontal movement
- Ground detection: set character.grounded when on platform
- Hazard collision: detect contact with spikes, return death flag
- Exit collision: detect character standing in their exit zone
- Basic jump: if grounded, set vy = JUMP_VELOCITY
- Character-specific physics stubs (double jump, float, etc. — full implementation in next ticket)

## Acceptance criteria
- Character falls with gravity and lands on platforms
- AABB collision works correctly
- Hazard contact detected
- Exit overlap detected
- Unit tests for collision detection and gravity
- `make test` passes

**Worktree:** /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0005-physics-system

## Prediction
- predicted_difficulty: hard
- predicted_duration_minutes: 32
- reasoning: Single new file but dense physics logic — AABB resolution, per-character stubs, gravity, and 4 distinct collision types — plus unit tests required; likely 2 attempts due to edge cases in platform resolution and grounded detection.

## Agent Run
- Model: claude-sonnet-4-6\n- Backend: claude-code\n- Exit Code: 0\n- Attempt: 1\n- Attempt Count: 1\n- Timeout: none\n- Log File: /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0005-physics-system/.scriptorium/logs/0005/attempt-01.jsonl\n- Last Message File: /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0005-physics-system/.scriptorium/logs/0005/attempt-01.last_message.txt\n
### Agent Last Message
```text
The `submit_pr` MCP tool isn't available in this session (same pattern as previous tickets). The work is complete and committed.

**Summary of changes:**

- `src/systems/physics.nim`: New file implementing:
  - `Rect` type and `intersects(a, b: Rect): bool` — AABB collision detection
  - `PhysicsResult` with `deadCharacters` and `exitedCharacters` seqs
  - `resolveCollision` — minimum-overlap axis resolution (lands on top, head-bumps on bottom, horizontal push-out)
  - `updatePhysics(characters, level, dt)` — gravity + terminal velocity clamping, platform/door collision resolution, grounded detection, hazard death detection, exit overlap detection
  - `applyJump(c)` — sets `vy = JUMP_VELOCITY` when grounded
  - Character ability stubs (`applyDoubleJumpStub`, `applyFloatStub`, `applyHeavyStub`, `applyWallJumpStub`, `applyCoyoteTimeStub`, `applyGracefulFallStub`)

- `tests/test_physics.nim`: 20 unit tests across 6 suites covering all acceptance criteria

All 60 tests pass (`make test`). Commit: `3a957cb`.
```

### Agent Stdout Tail
```text
detection, exit overlap detection\n  - `applyJump(c)` — sets `vy = JUMP_VELOCITY` when grounded\n  - Character ability stubs (`applyDoubleJumpStub`, `applyFloatStub`, `applyHeavyStub`, `applyWallJumpStub`, `applyCoyoteTimeStub`, `applyGracefulFallStub`)\n\n- `tests/test_physics.nim`: 20 unit tests across 6 suites covering all acceptance criteria\n\nAll 60 tests pass (`make test`). Commit: `3a957cb`.","stop_reason":"end_turn","session_id":"56ab2662-27ef-42f6-abfe-7883ed2babcf","total_cost_usd":0.6810324000000001,"usage":{"input_tokens":35,"cache_creation_input_tokens":42596,"cache_read_input_tokens":1062258,"output_tokens":13501,"server_tool_use":{"web_search_requests":0,"web_fetch_requests":0},"service_tier":"standard","cache_creation":{"ephemeral_1h_input_tokens":42596,"ephemeral_5m_input_tokens":0},"inference_geo":"","iterations":[],"speed":"standard"},"modelUsage":{"claude-sonnet-4-6":{"inputTokens":35,"outputTokens":13501,"cacheReadInputTokens":1062258,"cacheCreationInputTokens":42596,"webSearchRequests":0,"costUSD":0.6810324000000001,"contextWindow":200000,"maxOutputTokens":32000}},"permission_denials":[],"fast_mode_state":"off","uuid":"8cc64bea-8b8f-45f7-ba94-4ae07eb1f1b6"}
```

## Agent Run
- Model: claude-sonnet-4-6\n- Backend: claude-code\n- Exit Code: 0\n- Attempt: 2\n- Attempt Count: 1\n- Timeout: none\n- Log File: /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0005-physics-system/.scriptorium/logs/0005/attempt-02.jsonl\n- Last Message File: /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0005-physics-system/.scriptorium/logs/0005/attempt-02.last_message.txt\n
### Agent Last Message
```text
The merge queue entry has been created and committed to the plan branch. The physics system implementation (ticket 0005) is complete:

- `src/systems/physics.nim` implemented with:
  - `updatePhysics(characters, level, dt)` 
  - Gravity application
  - AABB `intersects(a, b: Rect): bool`
  - Platform collision resolution with grounded detection
  - Hazard collision detection
  - Exit zone detection
  - Basic jump mechanics
  - Character-specific physics stubs

- Full unit tests in `tests/test_physics.nim` — all passing
- Merge queue entry created at `queue/merge/pending/0001-0005.md` on the plan branch for the orchestrator to pick up
```

### Agent Stdout Tail
```text
n\n  - AABB `intersects(a, b: Rect): bool`\n  - Platform collision resolution with grounded detection\n  - Hazard collision detection\n  - Exit zone detection\n  - Basic jump mechanics\n  - Character-specific physics stubs\n\n- Full unit tests in `tests/test_physics.nim` — all passing\n- Merge queue entry created at `queue/merge/pending/0001-0005.md` on the plan branch for the orchestrator to pick up","stop_reason":"end_turn","session_id":"4160dd73-a11c-4965-8d3d-68e63cf8903d","total_cost_usd":0.8757181499999998,"usage":{"input_tokens":64,"cache_creation_input_tokens":31572,"cache_read_input_tokens":1666586,"output_tokens":9657,"server_tool_use":{"web_search_requests":0,"web_fetch_requests":0},"service_tier":"standard","cache_creation":{"ephemeral_1h_input_tokens":31572,"ephemeral_5m_input_tokens":0},"inference_geo":"","iterations":[],"speed":"standard"},"modelUsage":{"claude-sonnet-4-6":{"inputTokens":78,"outputTokens":11256,"cacheReadInputTokens":1777668,"cacheCreationInputTokens":46225,"webSearchRequests":0,"costUSD":0.8757181499999998,"contextWindow":200000,"maxOutputTokens":32000}},"permission_denials":[],"fast_mode_state":"off","uuid":"bf4f70d1-3d37-4e6d-9e6e-a731c98aa0b3"}
```
