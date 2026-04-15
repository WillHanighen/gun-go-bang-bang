---
name: maintenance refactor
overview: "Refactor the highest-risk large scripts with clean boundaries: split `weapon_manager.gd`, reduce HUD/player coupling, harden scene-node references, and break up `shooting_range.gd` without changing core gameplay behavior beyond small obvious cleanups."
todos:
  - id: split-weapon-manager
    content: Design and extract clean helper boundaries from `scripts/player/weapon_manager.gd` while preserving weapon behavior and signals.
    status: completed
  - id: unify-spread-api
    content: Create a single spread/crosshair calculation path shared by `weapon_manager.gd` and `hud.gd`, and reduce direct private-player coupling.
    status: completed
  - id: harden-node-refs
    content: Replace brittle node-path assumptions in `weapon_manager.gd`, `weapon_view.gd`, and related HUD/player access with safer references.
    status: completed
  - id: split-range-builder
    content: Extract procedural range-building responsibilities out of `scripts/range/shooting_range.gd` into focused helpers.
    status: completed
  - id: verify-and-report
    content: Run diagnostics on all touched files and return a file-by-file touched list plus a targeted manual test checklist.
    status: completed
isProject: false
---

# Maintenance Refactor Plan
## Goals
- Reduce the biggest maintenance hotspots without changing weapon feel or range behavior in meaningful ways.
- Split oversized scripts along clean boundaries so future edits are less risky.
- Remove brittle scene-path dependencies and duplicated gameplay math.

## Planned Changes
- Refactor [`/home/cottage-end/projects/godot/gun-go-bang-bang/scripts/player/weapon_manager.gd`](scripts/player/weapon_manager.gd) into smaller responsibilities.
  - Keep weapon state/signals in `weapon_manager.gd`.
  - Extract the shot-resolution / hitscan / penetration path into a helper under `scripts/player/` or `scripts/combat/`.
  - Extract decal/material setup and pooling into a helper so combat logic stops owning VFX details.
  - Replace name-based delayed burst recoil checks with a stronger state/instance-safe guard.
- Remove duplicated spread math shared by [`/home/cottage-end/projects/godot/gun-go-bang-bang/scripts/player/weapon_manager.gd`](scripts/player/weapon_manager.gd) and [`/home/cottage-end/projects/godot/gun-go-bang-bang/scripts/ui/hud.gd`](scripts/ui/hud.gd).
  - Introduce one authoritative helper/API for effective spread + crosshair spread calculation.
  - Stop `hud.gd` from reading underscore-prefixed player internals directly where possible.
- Harden brittle node access in [`/home/cottage-end/projects/godot/gun-go-bang-bang/scripts/player/weapon_manager.gd`](scripts/player/weapon_manager.gd), [`/home/cottage-end/projects/godot/gun-go-bang-bang/scripts/player/weapon_view.gd`](scripts/player/weapon_view.gd), and [`/home/cottage-end/projects/godot/gun-go-bang-bang/scripts/ui/hud.gd`](scripts/ui/hud.gd).
  - Replace hardcoded paths like `"Head/Camera3D"` and `"../../../WeaponManager"` with cached typed refs or narrow getters.
  - Keep scene structure stable unless a tiny scene edit makes the reference wiring safer.
- Split [`/home/cottage-end/projects/godot/gun-go-bang-bang/scripts/range/shooting_range.gd`](scripts/range/shooting_range.gd) along clean procedural-build seams.
  - Extract range-building helpers for environment/ground/targets/panels into one or two focused helper scripts.
  - Keep `_ready()` orchestration in `shooting_range.gd` so scene boot remains easy to read.

## Why These Targets
- `weapon_manager.gd` is the largest and most coupled script in the repo, mixing input, reload, burst timing, hitscan, penetration, and decals.
- `hud.gd` duplicates shot spread math and is tightly coupled to private player state.
- `weapon_view.gd` and `weapon_manager.gd` rely on fragile scene-depth/node-name assumptions.
- `shooting_range.gd` is large but has very clean extraction boundaries, making it a safer “second big split” than deeper movement surgery.

## Expected Files Touched
- Existing files, very likely:
  - [`/home/cottage-end/projects/godot/gun-go-bang-bang/scripts/player/weapon_manager.gd`](scripts/player/weapon_manager.gd)
  - [`/home/cottage-end/projects/godot/gun-go-bang-bang/scripts/ui/hud.gd`](scripts/ui/hud.gd)
  - [`/home/cottage-end/projects/godot/gun-go-bang-bang/scripts/player/weapon_view.gd`](scripts/player/weapon_view.gd)
  - [`/home/cottage-end/projects/godot/gun-go-bang-bang/scripts/range/shooting_range.gd`](scripts/range/shooting_range.gd)
- New helper files, likely:
  - one or more under `scripts/player/` or `scripts/combat/` for weapon shot/spread/decal responsibilities
  - one or more under `scripts/range/` for range construction helpers
- Possibly touched only if needed for safe wiring:
  - [`/home/cottage-end/projects/godot/gun-go-bang-bang/scenes/player/player.tscn`](scenes/player/player.tscn)
  - [`/home/cottage-end/projects/godot/gun-go-bang-bang/scripts/player/player_controller.gd`](scripts/player/player_controller.gd)

## Test Focus I Will Hand Back To You
- Weapon fire still matches crosshair spread.
- Reload, ammo wheel, burst fire, recoil, and hit registration still behave correctly.
- Weapon models still switch correctly in first person.
- Range scene still spawns environment, targets, moving targets, labels, panels, player, and HUD.
- No regressions in the recent movement/crouch/wall-jump fixes unless a touched interface requires a tiny follow-up.
