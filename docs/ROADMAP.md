# Together Roadmap

Current baseline: `v0.3.0`

This roadmap is intentionally concrete. Each version should end in a playable checkpoint, not just a pile of refactors.

## Phase 1: UI Reset

### v0.4.0 - Cohesive Front Door

Goal: replace the current "stack of panels" title and pause screens with a calmer, more intentional interface language.

- [ ] Replace the title screen structure in `src/systems/ui.nim`
- [ ] Make the title screen do one job: title, emotional hook, primary start action, quiet character selector
- [ ] Remove the separate CTA card and merge it into a single hero composition
- [ ] Demote controls/help text into a small footer instead of central UI
- [ ] Rebuild the pause screen as a true interruption state instead of generic app UI
- [ ] Make `Resume` visually dominant and demote `Restart` and `Menu`
- [ ] Remove redundant HUD elements from pause and other modal states
- [ ] Add keyboard/gamepad selection state for menu and pause so hover is not the only "active" state
- [ ] Capture fresh screenshots after the redesign and update README images if they are materially better

### v0.5.0 - HUD That Serves Play

Goal: make the in-game HUD minimal, readable, and emotionally aligned with the game.

- [ ] Merge level/location context into the active-character HUD instead of keeping separate floating islands
- [ ] Redesign narration as a subtitle-like ribbon instead of a heavy top card
- [ ] Reduce the active-character card footprint and make it feel diegetic rather than dashboard-like
- [ ] Keep the bottom character strip only when it is actually useful
- [ ] Add clear selected/active-state visuals for keyboard and controller swapping
- [ ] Tune typography hierarchy and spacing bands instead of continuing ad hoc coordinate edits
- [ ] Add tests or snapshot-like checks for UI layout helpers where practical

## Phase 2: Feel And Readability

### v0.6.0 - Camera, Juice, And Feedback

Goal: make the game feel crisp in motion, not just functional.

- [ ] Add a proper primary-action emphasis pass: jump, landing, death, switch, exit, and level-complete feedback
- [ ] Wire particles more intentionally into movement, impact, and success states
- [ ] Add subtle camera look-ahead and landing response without making the game noisy
- [ ] Add short pause/unpause transition treatment so state changes feel authored
- [ ] Add small state-reactive audio variations around danger, completion, and pauses
- [ ] Playtest all 12 levels and tune jump windows, platform timings, and readability issues

### v0.7.0 - World Art Direction

Goal: make the visual world feel atmospheric and beautiful without becoming busy.

- [ ] Redesign background/backdrop language around mood, depth, and composition instead of decorative shapes
- [ ] Add more intentional palette progression across the campaign
- [ ] Unify Boxy world composition and Silky UI so they feel like the same game
- [ ] Replace placeholder-feeling geometry accents with cleaner environmental silhouettes
- [ ] Improve level-to-level visual identity without hurting gameplay readability
- [ ] Add at least one stronger scenic treatment for late-campaign rooms

## Phase 3: Systems And Structure

### v0.8.0 - Runtime Polish And Player Trust

Goal: make the build feel like a real game build, not just a good prototype.

- [ ] Finish fullscreen/windowed behavior across macOS flows and reduce rough edges around resizing
- [ ] Add persistent settings for audio and video preferences
- [ ] Add a lightweight save/progress checkpoint for campaign continuation
- [ ] Add a settings or options screen that matches the new UI language
- [ ] Clean up dependency/version assumptions in build docs and runtime startup behavior
- [ ] Audit gamepad behavior and make menu navigation/controller prompts first-class
- [ ] Remove stale or experimental UI code paths after the redesign settles

### v0.9.0 - Vertical Slice Release Candidate

Goal: turn the project into a polished vertical slice that is easy to show, share, and evaluate.

- [ ] Final pass on title screen, HUD, pause, win, and credits for consistency
- [ ] Final content tuning pass across all campaign levels
- [ ] Finish README so it reflects the actual current game rather than historical iteration notes
- [ ] Add updated screenshots and a short "what changed since v0.3.0" section
- [ ] Add a short playtest checklist and known-issues list for future external testers
- [ ] Run full test suite and release build verification
- [ ] Tag the `v0.9.0` checkpoint and treat it as the first serious public-facing slice

## Cross-Cutting Rules

These apply to every version above.

- [ ] Every version ends with a runnable build and a short note about what changed
- [ ] Every version should improve one primary player-facing area, not five half-finished ones
- [ ] Do not keep layering panels and helper text onto broken screen structures
- [ ] Prefer a smaller number of stronger decisions over more decorative UI
- [ ] Keep learning from Treeform repos, but use them to simplify architecture rather than accumulate gadgets
