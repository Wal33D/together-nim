# Implement keyboard input handling

**Area:** input
**Depends:** 0004, 0002

Implement `src/systems/input.nim`:
- `handleInput(game, event)` proc processes SDL key events
- Left/Right arrow or A/D for horizontal movement
- Space for jump
- Keys 1-6 to switch active character
- Escape for pause toggle
- Enter to start game from menu
- Track key held state (not just key down) for continuous movement

## Acceptance criteria
- Character moves left/right with arrow keys
- Space triggers jump
- Number keys switch active character
- `make test` passes

**Worktree:** /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0007-input-system

## Prediction
- predicted_difficulty: easy
- predicted_duration_minutes: 13
- reasoning: Single-file implementation mapping SDL key events to game actions with straightforward logic; key-held state tracking adds minor complexity but no cross-module integration risk.

## Agent Run
- Model: claude-sonnet-4-6\n- Backend: claude-code\n- Exit Code: 0\n- Attempt: 1\n- Attempt Count: 1\n- Timeout: none\n- Log File: /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0007-input-system/.scriptorium/logs/0007/attempt-01.jsonl\n- Last Message File: /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0007-input-system/.scriptorium/logs/0007/attempt-01.last_message.txt\n
### Agent Last Message
```text
The implementation is complete and committed. The `submit_pr` MCP tool doesn't appear to be available in this session's tool set. The work is done:

**Summary of changes:**
- `src/game.nim`: Added `vx`, `vy` to `Character` and `leftHeld`, `rightHeld` to `Game`
- `src/systems/input.nim`: New file with `processKey` (testable, scancode-based) and `handleInput` (SDL Event wrapper) — handles left/right/A/D movement, space for jump, 1–6 to switch characters, enter to start, escape to pause/unpause
- `tests/test_input.nim`: 20 tests covering all input behaviors — all pass

All 36 tests pass (`make test`). Commit: `45b67d3`.
```

### Agent Stdout Tail
```text
leftHeld`, `rightHeld` to `Game`\n- `src/systems/input.nim`: New file with `processKey` (testable, scancode-based) and `handleInput` (SDL Event wrapper) — handles left/right/A/D movement, space for jump, 1–6 to switch characters, enter to start, escape to pause/unpause\n- `tests/test_input.nim`: 20 tests covering all input behaviors — all pass\n\nAll 36 tests pass (`make test`). Commit: `45b67d3`.","stop_reason":"end_turn","session_id":"b1ad3b02-29f0-40cf-b847-4fcc807760a2","total_cost_usd":0.5576212500000001,"usage":{"input_tokens":24,"cache_creation_input_tokens":44673,"cache_read_input_tokens":540135,"output_tokens":15199,"server_tool_use":{"web_search_requests":0,"web_fetch_requests":0},"service_tier":"standard","cache_creation":{"ephemeral_1h_input_tokens":44673,"ephemeral_5m_input_tokens":0},"inference_geo":"","iterations":[],"speed":"standard"},"modelUsage":{"claude-sonnet-4-6":{"inputTokens":24,"outputTokens":15199,"cacheReadInputTokens":540135,"cacheCreationInputTokens":44673,"webSearchRequests":0,"costUSD":0.5576212500000001,"contextWindow":200000,"maxOutputTokens":32000}},"permission_denials":[],"fast_mode_state":"off","uuid":"edf3e12e-71c6-4e52-bd0a-cadf12db5e1d"}
```
