# Define core constants and shared types

**Area:** entities

Implement `src/constants.nim` with all game constants:
- Physics: GRAVITY (980.0), JUMP_VELOCITY (-450.0), MAX_FALL_SPEED (800.0), TERMINAL_VELOCITY
- Window: DEFAULT_WIDTH (1280), DEFAULT_HEIGHT (720)
- Character dimensions and colors for all 6 characters
- Timing: FIXED_TIMESTEP (1/60)

Implement basic shared types that other modules will import.

## Acceptance criteria
- `src/constants.nim` compiles and exports all constants
- Unit test in `tests/test_constants.nim` validates key values
- `make test` passes

**Worktree:** /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0001-constants-and-types

## Prediction
- predicted_difficulty: easy
- predicted_duration_minutes: 12
- reasoning: Single-file constants definition with known values, plus a simple test file — no logic complexity or integration risk, one attempt expected.

## Agent Run
- Model: claude-sonnet-4-6\n- Backend: claude-code\n- Exit Code: 0\n- Attempt: 1\n- Attempt Count: 1\n- Timeout: none\n- Log File: /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0001-constants-and-types/.scriptorium/logs/0001/attempt-01.jsonl\n- Last Message File: /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0001-constants-and-types/.scriptorium/logs/0001/attempt-01.last_message.txt\n
### Agent Last Message
```text
The `submit_pr` MCP tool doesn't appear to be available in this environment. The work is complete:

- Created `src/constants.nim` with all required constants (physics, window, timing, character colors/dimensions)
- Created `tests/test_constants.nim` with tests for all key values
- `make test` passes (6 tests across both test files)
- Changes committed as `d743918`

The ticket `0001-constants-and-types` is implemented and committed on branch `scriptorium/ticket-0001`.
```

### Agent Stdout Tail
```text
ble in this environment. The work is complete:\n\n- Created `src/constants.nim` with all required constants (physics, window, timing, character colors/dimensions)\n- Created `tests/test_constants.nim` with tests for all key values\n- `make test` passes (6 tests across both test files)\n- Changes committed as `d743918`\n\nThe ticket `0001-constants-and-types` is implemented and committed on branch `scriptorium/ticket-0001`.","stop_reason":"end_turn","session_id":"8710c70e-7e20-42f9-8ecd-56165a77b269","total_cost_usd":0.1709385,"usage":{"input_tokens":14,"cache_creation_input_tokens":17440,"cache_read_input_tokens":216255,"output_tokens":2708,"server_tool_use":{"web_search_requests":0,"web_fetch_requests":0},"service_tier":"standard","cache_creation":{"ephemeral_1h_input_tokens":17440,"ephemeral_5m_input_tokens":0},"inference_geo":"","iterations":[],"speed":"standard"},"modelUsage":{"claude-sonnet-4-6":{"inputTokens":14,"outputTokens":2708,"cacheReadInputTokens":216255,"cacheCreationInputTokens":17440,"webSearchRequests":0,"costUSD":0.1709385,"contextWindow":200000,"maxOutputTokens":32000}},"permission_denials":[],"fast_mode_state":"off","uuid":"bb676a4b-46a5-42b5-9df5-6db2219e46f9"}
```

## Agent Run
- Model: claude-sonnet-4-6\n- Backend: claude-code\n- Exit Code: 0\n- Attempt: 2\n- Attempt Count: 1\n- Timeout: none\n- Log File: /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0001-constants-and-types/.scriptorium/logs/0001/attempt-02.jsonl\n- Last Message File: /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0001-constants-and-types/.scriptorium/logs/0001/attempt-02.last_message.txt\n
### Agent Last Message
```text
`submit_pr` succeeded — the merge request has been enqueued. The ticket is complete:

- `src/constants.nim` exports all physics, window, timing, and character constants
- `tests/test_constants.nim` validates key values
- `make test` passes all suites
```

### Agent Stdout Tail
```text
d":"58f2b239-6779-43a3-9abb-7c9fbb86bf6b"}
{"type":"result","subtype":"success","is_error":false,"duration_ms":172129,"duration_api_ms":169121,"num_turns":41,"result":"`submit_pr` succeeded — the merge request has been enqueued. The ticket is complete:\n\n- `src/constants.nim` exports all physics, window, timing, and character constants\n- `tests/test_constants.nim` validates key values\n- `make test` passes all suites","stop_reason":"end_turn","session_id":"aa19ff10-d7c1-4972-a9f2-55c869f4f396","total_cost_usd":0.45003885,"usage":{"input_tokens":43,"cache_creation_input_tokens":21843,"cache_read_input_tokens":900862,"output_tokens":6516,"server_tool_use":{"web_search_requests":0,"web_fetch_requests":0},"service_tier":"standard","cache_creation":{"ephemeral_1h_input_tokens":21843,"ephemeral_5m_input_tokens":0},"inference_geo":"","iterations":[],"speed":"standard"},"modelUsage":{"claude-sonnet-4-6":{"inputTokens":43,"outputTokens":6516,"cacheReadInputTokens":900862,"cacheCreationInputTokens":21843,"webSearchRequests":0,"costUSD":0.45003885,"contextWindow":200000,"maxOutputTokens":32000}},"permission_denials":[],"fast_mode_state":"off","uuid":"d6fc90c7-4592-4887-945d-3f7c4af1581c"}
```
