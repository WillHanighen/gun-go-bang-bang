# (codename) Gun Go Bang Bang
## ive not decided on a name yet

A **Godot 4.6** first-person shooting sandbox with a playful, slightly ridiculous vibe: procedural outdoor range, multiple firearms, ammo types, and simple ballistics (including penetration). Built for experimenting with weapon feel, not as a serious milsim or a shipped game.

## Tone and direction

This project should feel like a mix of:

- **TABG-style goofiness**: toy-box energy, weird charm, and a willingness to be a little stupid on purpose
- **STRAFTAT-style tech**: fast, sharp, mechanical, and clean in the ways the sandbox actually feels to play

The target is **goofy-tech**, not grim-tactical. That means:

- weapon handling should feel expressive and fun first, realistic second
- systems can be crunchy, but presentation should stay playful and readable
- the sandbox should reward experimentation, odd combinations, and "what if this was a bad idea?" moments
- avoid lore-heavy, military-sim, or self-important framing unless it is clearly being used as a joke

If something has to choose between "serious and authentic" vs "funny, punchy, and memorable," the project should usually prefer the second option.

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
| Move | WASD |
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
