# Repository Guidelines

## Project Structure & Module Organization
- `project.godot`: Godot project entry/config (autoloads, input map, main scene).
- `stages/`: top-level playable scenes (for example `stages/jonas_test.tscn`).
- `entities/`: gameplay scenes/scripts by domain (`player/`, `environment/`, `note_colors/`).
- `common/components/`: reusable gameplay components (`freezable.gd`, `note_color.gd`).
- `common/manager/`: global systems (for example `freeze_manager.gd` autoload).
- `assets/`: shared art/audio resources used by current gameplay.
- `test_import/`: imported template/prototype content; avoid coupling new core logic here.
- `addons/`: editor/runtime plugins (Git plugin is included).

## Build, Test, and Development Commands
- `godot --path . --editor`: open the project in the Godot editor.
- `godot --path .`: run the configured main scene.
- `godot --path . --headless --quit`: quick CI/sanity load check (detects parse/load errors).
- `git status` and `git diff --name-only`: verify changed files before commit.

If your local binary is `godot4`, use the same commands with `godot4`.

## Coding Style & Naming Conventions
- Language: GDScript (Godot 4.x).
- Use tabs for indentation in `.gd` files (Godot default); keep lines focused and readable.
- File/script names: `snake_case.gd`; scene names: `snake_case.tscn`.
- Class names: `PascalCase` (for example `class_name Freezable`).
- Signals/variables/functions: `snake_case`.
- Prefer small, composable scripts in `common/components` over duplicated logic.

## Testing Guidelines
- No formal test framework is configured yet.
- Validate changes with focused in-editor playtests in `stages/` scenes.
- For freeze mechanic changes, verify:
  - note input emits through `FreezeManager`,
  - matching `NoteColor` objects freeze/unfreeze on timer,
  - non-matching objects remain active.
- Include reproduction steps in PR notes for bug fixes.

## Commit & Pull Request Guidelines
- Current history favors short imperative commits (for example `create freezable`, `added assets`).
- Recommended format: `<area>: <imperative summary>` (example: `player: add note 2/3 freeze input`).
- Keep commits scoped to one logical change.
- PRs should include:
  - what changed and why,
  - scenes/scripts touched,
  - manual test steps,
  - screenshot/GIF for visible gameplay changes.

## Current Handoff
- Project path: `/home/dreptschar/Workspace/GameJam/miniGameJam`
- Engine: Godot 4
- Beat autoload: `BeatManger` in `common/manager/beat_manger.gd`
- Freeze request autoload: `FreezeManager` in `common/manager/freeze_manager.gd`
- `Freezable` logic: `common/components/freezable.gd`
- Player note logic: `entities/player/player.gd`
- Moving platform logic: `entities/moving_platfrom/moving_platform.gd`
- Level manager: `common/manager/level_manager.gd` and `common/manager/level_manager.tscn`

- Current gameplay rules:
  - Non-player objects are intended to move on the beat.
  - Player notes are beat-quantized with a small timing window.
  - Multi-color freezables use two values:
    - `combo_window_beats`: how many beats the player has to complete the full note combination.
    - `freeze_beats`: how long the object stays fully frozen after all required colors have been hit.

- Moving platform details:
  - Movement is beat-driven.
  - Path modes supported: `CUSTOM`, `HORIZONTAL`, `VERTICAL`.
  - Parent inspector exposes `freeze_beats` and `combo_window_beats` and forwards them to the child `FreezableComponent`.
  - Editor preview draws the platform path and beat-step markers.

- Recent merge-related fixes:
  - `stages/level/level_1.tscn` had invalid typed export values and a missing `TileSet` ext_resource restored.
  - `common/manager/level_manager.tscn` had its `levels` array restored.
