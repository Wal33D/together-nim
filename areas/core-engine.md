# Core Engine

**Scope:** Game loop, SDL2 initialization/shutdown, window management, main entry point.

**Files:** `src/together.nim`, `src/game.nim`, `src/constants.nim`

**Description:**
The core engine manages the SDL2 lifecycle, game loop (fixed timestep update + render), and the game state machine (menu, playing, paused, credits). This is the foundation everything else builds on.
