# Implement character entity type and abilities

**Area:** entities
**Depends:** 0001

Implement `src/entities/character.nim`:
- Character object type with: id, x, y, width, height, color, vx, vy, grounded, facingRight
- CharacterAbility variant type for the 6 abilities (doubleJump, float, heavy, wallJump, coyoteTime, gracefulFall)
- Factory proc `newCharacter(id: string): Character` that creates characters with correct dimensions/colors/abilities
- All 6 characters: Pip (30x30 pink), Luca (25x40 yellow), Bruno (50x50 brown), Cara (20x45 light pink), Felix (35x35 tan), Ivy (28x42 teal)

## Acceptance criteria
- Character type compiles with all fields
- `newCharacter("pip")` returns correct pink 30x30 character with double jump
- Unit test validates all 6 characters
- `make test` passes

**Worktree:** /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0002-character-entity

## Prediction
- predicted_difficulty: easy
- predicted_duration_minutes: 12
- reasoning: Single-file implementation with well-specified data (6 characters, known dimensions/colors/abilities) and no cross-module dependencies beyond constants, one attempt expected.

## Agent Run
- Model: claude-sonnet-4-6\n- Backend: claude-code\n- Exit Code: 0\n- Attempt: 1\n- Attempt Count: 1\n- Timeout: none\n- Log File: /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0002-character-entity/.scriptorium/logs/0002/attempt-01.jsonl\n- Last Message File: /var/folders/ys/98yrt60d6dz7l3ml2s6p45480000gn/T/scriptorium/together-nim-31dcad70cc70b542/worktrees/tickets/0002-character-entity/.scriptorium/logs/0002/attempt-01.last_message.txt\n
### Agent Last Message
```text
The work is complete. Here's a summary of what was implemented:

**`src/entities/character.nim`** - Character entity module with:
- `CharacterAbility` enum: `doubleJump`, `floatAbility`, `heavy`, `wallJump`, `coyoteTime`, `gracefulFall`
- `Character` object: id, x, y, width, height, color, vx, vy, grounded, facingRight, ability
- `newCharacter(id)` factory proc for all 6 characters with correct dimensions, colors, and abilities

**`tests/test_character.nim`** - 7 unit tests covering all 6 characters and default field values

All tests pass (`make test` exits 0), changes committed, and the PR submitted to the merge queue.
```

### Agent Stdout Tail
```text
lFall`\n- `Character` object: id, x, y, width, height, color, vx, vy, grounded, facingRight, ability\n- `newCharacter(id)` factory proc for all 6 characters with correct dimensions, colors, and abilities\n\n**`tests/test_character.nim`** - 7 unit tests covering all 6 characters and default field values\n\nAll tests pass (`make test` exits 0), changes committed, and the PR submitted to the merge queue.","stop_reason":"end_turn","session_id":"e793cae7-a477-4142-bd01-83f0b87f5f24","total_cost_usd":0.6326458500000001,"usage":{"input_tokens":46,"cache_creation_input_tokens":29575,"cache_read_input_tokens":1219022,"output_tokens":10393,"server_tool_use":{"web_search_requests":0,"web_fetch_requests":0},"service_tier":"standard","cache_creation":{"ephemeral_1h_input_tokens":29575,"ephemeral_5m_input_tokens":0},"inference_geo":"","iterations":[],"speed":"standard"},"modelUsage":{"claude-sonnet-4-6":{"inputTokens":46,"outputTokens":10393,"cacheReadInputTokens":1219022,"cacheCreationInputTokens":29575,"webSearchRequests":0,"costUSD":0.6326458500000001,"contextWindow":200000,"maxOutputTokens":32000}},"permission_denials":[],"fast_mode_state":"off","uuid":"b3cf7782-9c3a-494d-b8d4-d50c0a804bd1"}
```
