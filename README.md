# Together (Nim) `v0.2.0`

*"Pip woke up. This was unusual, because Pip had never been asleep."*

A narrative puzzle-platformer about colored rectangles discovering consciousness, friendship, and what it means to belong. Rebuilt from the ground up in **Nim** with **SDL2** for platform/input/audio and a **Boxy-backed rendering spike** for the visual layer.

Inspired by *Thomas Was Alone*. Originally built in TypeScript at [candycomp.com](https://candycomp.com), now reimagined as a native desktop game orchestrated by [Scriptorium](https://github.com/Wal33D/scriptorium).

Current state: a 12-level campaign with Felix and Ivy in the playable arc, ambient procedural music, improved jump feel, and layered atmospheric backdrops instead of literal scene props.

## Current Build

- Version: `0.2.0`
- Runtime stack: SDL2 for windowing, input, audio, and controllers, with a Boxy-backed render path
- Campaign: 12 playable levels
- Recent improvements: jump buffering and coyote time polish, procedural ambient music, atmospheric backdrops, gameplay particles, fullscreen toggle with saved preference

## Screenshots

![Title screen](assets/screenshots/menu.png)

![Gameplay](assets/screenshots/gameplay.png)

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
| Fullscreen | F11 |
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

Thanks to Monofuel on GitHub for creating Orchestrator / Scriptorium and for the underlying workflow that powers this project.

## License

MIT
