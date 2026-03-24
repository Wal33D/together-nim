# Together

*"Pip woke up. This was unusual, because Pip had never been asleep."*

A quiet puzzle-platformer about colored rectangles who discover consciousness, friendship, and what it means to belong. Six characters, each with a unique gift. None of them can reach the exit alone.

Inspired by [Thomas Was Alone](https://store.steampowered.com/app/220780/Thomas_Was_Alone/). Built in **Nim** with Windy, Boxy, Silky, and SDL2. Developed with [Scriptorium](https://github.com/monofuel/scriptorium).

![Gameplay — Pip in Level 1: Awakening](assets/screenshots/gameplay.png?raw=true)

## The Cast

| | Name | Gift | Personality |
|---|------|------|-------------|
| 🩷 | **Pip** | Double jump | Curious and brave. Always leaps before she looks. |
| 💛 | **Luca** | Float | Dreamy and gentle. Softens every fall. |
| 🟤 | **Bruno** | Heavy pressure | Quiet and steady. Holds the ground for everyone else. |
| 💜 | **Cara** | Wall jump | Playful and fearless. Finds paths where none exist. |
| 🟠 | **Felix** | Coyote time | Patient. Never rushes. Lands when he's ready. |
| 💙 | **Ivy** | Graceful fall | Composed and kind. Makes the descent feel like flying. |

Each character's limitation is another character's strength. That's the whole point.

## Features

- **30 levels across 5 acts** — Awakening, Belonging, Challenge, Separation, Transcendence
- **6 playable characters** with distinct physics, abilities, and personalities
- **Narration system** — character thoughts, first-meeting moments, emotional story beats
- **Procedural ambient music** — sine wave synthesis that shifts with proximity and act progression, per-character oscillators
- **Squash & stretch animation** — landing squash, jump stretch, wall-slide compress, movement lean
- **Atmospheric rendering** — parallax backdrops, gradient skies, ambient particles, proximity glow
- **Level select** with act grouping, star ratings, and locked level indicators
- **Star challenges** — time targets, no-death runs, and secret collectibles
- **Win celebration** — confetti particles, character lineup, sparkle effects
- **Save system** — progress, stars, settings, and window preferences persist
- **Gamepad support** via IOKit HID
- **Settings** — window size presets, fullscreen, VSync, master volume

## Controls

| Action | Key |
|--------|-----|
| Move | Arrow keys / A, D |
| Jump | Space |
| Switch character | 1-6 |
| Pause | Escape |
| Fullscreen | F11 |
| Restart level | R |
| Level select | Tab (from menu) |

## Build & Run

Requires [Nim](https://nim-lang.org/) >= 2.0 and [SDL2](https://www.libsdl.org/).

```bash
brew install sdl2
nimble install -y
nim c -d:release -o:together src/together.nim
./together
```

Run tests with `make test`.

## Architecture

```
src/
├── together.nim          # Entry point, Windy window, game loop
├── game.nim              # State machine, update logic, level management
├── constants.nim         # Physics, colors, dimensions, audio palettes
├── entities/
│   ├── character.nim     # Character type with physics and emotional state
│   └── level.nim         # Level type with platforms, hazards, exits
└── systems/
    ├── physics.nim       # Gravity, AABB collision, per-character physics
    ├── camera.nim        # Smooth-follow camera with hold beats
    ├── renderer.nim      # Boxy world rendering, backgrounds, characters
    ├── ui.nim            # Silky UI: menus, HUD, pause, narration
    ├── audio.nim         # Procedural sine synthesis, ambient music
    ├── particles.nim     # Landing dust, proximity sparkles, confetti
    ├── animation.nim     # Squash/stretch, idle sway, emotional glow
    ├── levels.nim        # All 30+ level definitions
    ├── save.nim          # JSON save/load
    ├── gamepad.nim       # IOKit HID gamepad input
    ├── atmosphere.nim    # Parallax backdrop layers
    ├── backdrop.nim      # Per-act scene rendering
    └── screenEffects.nim # Screen shake, flash, transitions
```

## Built with Scriptorium

This game is developed using [Scriptorium](https://github.com/monofuel/scriptorium), a git-native AI agent orchestration system by [Monofuel](https://github.com/monofuel). Scriptorium reads a spec, generates tickets, assigns parallel coding agents, reviews their work, and merges passing changes to master automatically.

Over **139 tickets** have been completed autonomously so far. The `scriptorium/plan` branch contains the full planning state.

Thanks to Monofuel for creating Scriptorium and for [Sygnosphere](https://github.com/monofuel/sygnosphere), which served as a reference for running Boxy world rendering and Silky UI overlays together in the same Windy/OpenGL frame loop.

## License

MIT
