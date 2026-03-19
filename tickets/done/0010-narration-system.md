# Implement typewriter narration system

**Area:** narration
**Depends:** 0008

Implement `src/systems/narration.nim`:
- Narration type with: text, revealedChars, charTimer, isComplete, isActive
- `startNarration(text: string)` — begin typewriter reveal
- `updateNarration(narration, dt)` — reveal one char every 40ms
- `renderNarration(renderer, narration)` — draw text at top of screen with dark background overlay
- Trigger narration from level data when level loads
- Skip on any key press (reveal all text instantly)

## Acceptance criteria
- Text reveals character by character
- Pressing a key skips to full text
- Narration appears on level start
- Dark overlay behind text for readability
- `make test` passes
