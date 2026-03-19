# Add levels 6-10 introducing Bruno and Cara

**Area:** entities

Add 5 new levels to `src/systems/levels.nim` and update allLevels array to include them.

Level 6 "The Weight of Things" (Pip + Luca + Bruno):
- Bruno introduction. First level with a button and door.
- Bruno stands on a heavy button to open a door for Pip and Luca
- Narration: "Bruno was brown. Bruno was big. Bruno was heavy. He couldn't jump very high."
- Three exits, one per character

Level 7 "What Bruno Holds" (Pip + Luca + Bruno):
- Bruno must hold a button while others pass through a door
- The door is between the start area and the exit area
- Bruno's exit is near the button (he doesn't need to go through the door)
- Narration: "'I slow everyone down,' Bruno said. 'No,' Pip replied. 'You hold everything together.'"

Level 8 "Walls" (Pip + Bruno + Cara):
- Cara introduction. First level with wall-jump surfaces.
- Cara is the only one who can reach a high button via wall jumping
- Narration: "Cara was small. Cara was light pink. Cara could climb where others could not."

Level 9 "Apart" (Pip + Luca + Bruno + Cara):
- All 4 characters. More complex puzzle with multiple buttons and doors.
- Characters need to split up to reach their exits
- Narration: "Four shapes. Four colors. They were beginning to understand."

Level 10 "Trust" (Pip + Luca + Bruno + Cara):
- One character must press a button on faith, opening a door for others they can't see
- Builds trust theme
- Narration: "Trust was not a feeling. Trust was a choice."

Each level must have valid platforms, exits for every character, appropriate hazards, and buttons/doors where specified. Use the 800x500 coordinate space. Make sure `make test` passes.

## Acceptance criteria
- 5 new playable levels added
- allLevels array updated (now 10 levels)
- Bruno's heavy ability works with requiresHeavy buttons
- Levels are solvable
- `make test` passes
