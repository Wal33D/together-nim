# Together

*"Pip woke up. This was unusual, because Pip had never been asleep."*

A quiet puzzle-platformer about colored rectangles who discover consciousness, friendship, and what it means to belong. Six characters, each with a unique gift. None of them can reach the exit alone.

Inspired by [Thomas Was Alone](https://store.steampowered.com/app/220780/Thomas_Was_Alone/). Built in **Nim** with Windy, Boxy, Silky, and SDL2. Developed with [Scriptorium](https://github.com/monofuel/scriptorium).

![Gameplay — Pip in Level 1: Awakening](assets/screenshots/gameplay.png?raw=true)

## The Cast

| | Name | Gift | Personality |
|---|------|------|-------------|
| :pink_square: | **Pip** | Double jump | Curious and brave. Always leaps before she looks. |
| :yellow_square: | **Luca** | Float | Dreamy and gentle. Softens every fall. |
| :brown_square: | **Bruno** | Heavy pressure | Quiet and steady. Holds the ground for everyone else. |
| :purple_square: | **Cara** | Wall jump | Playful and fearless. Finds paths where none exist. |
| :orange_square: | **Felix** | Coyote time | Patient. Never rushes. Lands when he's ready. |
| :blue_square: | **Ivy** | Graceful fall | Composed and kind. Makes the descent feel like flying. |

Each character's limitation is another character's strength. That's the whole point.

## What's Here

- 30 levels across 5 acts, each with its own emotional arc
- 6 playable characters with distinct physics and abilities
- Per-character narration moments and story beats
- Procedural ambient music that shifts with proximity and act progression
- Atmospheric backdrops, particles, and glow effects
- Star challenges, save persistence, and settings
- Gamepad support

## Controls

| Action | Key |
|--------|-----|
| Move | Arrow keys / A, D |
| Jump | Space |
| Switch character | 1-6 |
| Pause | Escape |
| Fullscreen | F11 |
| Restart level | R |

## Build & Run

Requires [Nim](https://nim-lang.org/) >= 2.0 and [SDL2](https://www.libsdl.org/).

```bash
brew install sdl2
nimble install -y
nim c -d:release -o:together src/together.nim
./together
```

Run tests with `make test`.

## Built with Scriptorium

This game is developed using [Scriptorium](https://github.com/monofuel/scriptorium), a git-native AI agent orchestration system by [Monofuel](https://github.com/monofuel). Scriptorium reads a spec, generates tickets, assigns parallel coding agents, reviews their work, and merges passing changes to master automatically.

The `scriptorium/plan` branch contains the full planning state. Over 70 tickets have been completed autonomously so far.

Thanks to Monofuel for creating Scriptorium and for [Sygnosphere](https://github.com/monofuel/sygnosphere), which served as a reference for running Boxy world rendering and Silky UI overlays together in the same Windy/OpenGL frame loop.

## License

MIT
