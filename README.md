# gun go bang bang

A **Godot 4.6** first-person shooting sandbox: procedural outdoor range, multiple firearms, ammo types, and simple ballistics (including penetration). Built for experimenting with weapon feel, not as a shipped game.

## Requirements

- [Godot 4.6](https://godotengine.org/download) (project targets `4.6` with **Forward+** rendering and **Jolt** 3D physics)

Clone the repo and open the project folder in the Godot editor, or run the main scene from the command line:

```bash
godot --path /path/to/gun-go-bang-bang
```

The entry scene is `res://scenes/range/shooting_range.tscn`.

## Controls

| Action | Default binding |
|--------|-----------------|
| Move | W A S D |
| Jump | Space |
| Sprint | Shift |
| Fire | Left mouse |
| Aim (ADS) | Right mouse |
| Reload | R (hold briefly to open ammo selection when multiple calibers exist) |
| Next / previous weapon | E / Q |
| Cycle fire mode | V |
| Cycle ammo / ammo wheel | X (mouse moves selection when wheel is open) |
| Interact | F |
| Release / capture mouse | Esc |

## What’s in the range

The main scene builds a **shooting range** at runtime: ground, sky, lighting, distance labels (meters and yards), steel plates and paper targets at **10 / 25 / 50 / 100 m**, and **wood** and **thin metal** panels in front of extra plates to try penetration. The player spawns with the full weapon list from the autoload database.

## Project layout (high level)

| Path | Role |
|------|------|
| `scenes/range/` | Main range scene and setup |
| `scenes/player/` | Player body, camera, weapon manager |
| `scripts/autoload/` | `InputSetup` (default keymap), `WeaponDatabase` (calibers + weapons) |
| `scripts/data/` | Caliber and weapon definitions |
| `scripts/resources/` | `WeaponResource`, caliber resources |
| `assets/` | 3D models and textures for firearms |

## Third-party assets

Model credits and licenses (CC BY 4.0 where noted) are listed in [`attributions.md`](attributions.md).
