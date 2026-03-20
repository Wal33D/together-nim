# Together (Nim)

*"Pip woke up. This was unusual, because Pip had never been asleep."*

A narrative puzzle-platformer about colored rectangles discovering consciousness, friendship, and what it means to belong. Rebuilt from the ground up in **Nim** with **SDL2**.

Inspired by *Thomas Was Alone*. Originally built in TypeScript at [candycomp.com](https://candycomp.com), now reimagined as a native desktop game orchestrated by [Scriptorium](https://github.com/Wal33D/scriptorium).

The current campaign spans 12 levels and brings Felix and Ivy into the playable arc.

## The Family

| Character | Color | Gift |
|-----------|-------|------|
| **Pip** | Pink | Double jump — reaches new heights |
| **Luca** | Yellow | Float — drifts gently through the world |
| **Bruno** | Brown | Heavy — presses buttons, holds things together |
| **Cara** | Light Pink | Wall jump — climbs where others can't |
| **Felix** | Tan | Long coyote time — patient, never rushed |
| **Ivy** | Teal | Graceful fall — lands in peace |

## Controls

| Action | Key |
|--------|-----|
| Move | Arrow keys or A/D |
| Jump | Space |
| Switch character | 1-6 |
| Pause | Escape |
| Restart level | R |
| Start / Continue | Enter |

## Build & Run

Requires [Nim](https://nim-lang.org/) >= 2.0.0 and [SDL2](https://www.libsdl.org/).

```bash
# Install SDL2 (macOS)
brew install sdl2

# Install Nim SDL2 bindings
nimble install sdl2

# Build
nim c -o:together -d:release src/together.nim

# Run (macOS — SDL2 needs library path)
DYLD_LIBRARY_PATH=/opt/homebrew/lib ./together

# Run tests
make test
```

## Built with Scriptorium

This game is being developed using [Scriptorium](https://github.com/Wal33D/scriptorium), a git-native agent orchestration system. Scriptorium's Architect breaks the game into areas and tickets, coding agents implement features in parallel worktrees, a review agent checks their work, and passing changes merge to master automatically.

The `scriptorium/plan` branch contains the full planning state — spec, areas, tickets, and their lifecycle.

## License

MIT
