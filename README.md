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


| Action                         | Default binding                                                                   |
| ------------------------------ | --------------------------------------------------------------------------------- |
| Move                           | WASD                                                                              |
| Jump                           | Space                                                                             |
| Crouch                         | Ctrl                                                                              |
| Sprint                         | Shift                                                                             |
| Fire                           | Left mouse                                                                        |
| Aim (ADS)                      | Right mouse when only one hand has a gun; with two guns, right mouse fires hand 2 |
| Reload / caliber wheel         | R (hold briefly to open caliber selection when multiple calibers exist; mouse moves when open; hold **Alt** when pressing R for off-hand) |
| Equip loadout slot             | 1 / 2 / 3 (primary / secondary / melee)                                           |
| Cycle fire mode                | V (hold **Alt** for off-hand when dual-wielding)                                  |
| Inventory                      | Tab                                                                               |
| Interact                       | F                                                                                 |
| Pause menu                     | Esc                                                                               |

While `SOLO_PLAYER_SESSION` is true in `scripts/ui/pause_menu.gd`, opening pause **freezes** the scene tree (`SceneTree.pause`). For future multiplayer, flip it to false so the match can keep simulating while the menu is open.


## What’s in the range

The main scene builds a **shooting range** at runtime: ground, sky, lighting, distance labels (meters and yards), steel plates and paper targets at **10 / 25 / 50 / 100 m**, and **wood** and **thin metal** panels in front of extra plates to try penetration. The **player starts unarmed**; every firearm in the project is available as a **world pickup** (Colt Python, M1911, KRISS Vector, Remington 870, M4A1, Mossberg 590) placed on the range. Weapons live in a **grid inventory** (`WeaponDatabase` autoload supplies definitions; `PlayerInventory` tracks items and equipped slots).

## Project layout (high level)


| Path                 | Role                                                                 |
| -------------------- | -------------------------------------------------------------------- |
| `scenes/range/`      | Main range scene; pickups and authored props                         |
| `scenes/player/`     | Player body (pill silhouette), camera, weapon view, inventory        |
| `scenes/pickups/`    | Weapon pickup scenes                                                 |
| `scripts/autoload/`  | `InputSetup` (default keymap), `WeaponDatabase` (calibers + weapons) |
| `scripts/combat/`    | Ballistics                                                           |
| `scripts/data/`      | Caliber and weapon registration (`ammo_*`, `weapons_*`)              |
| `scripts/player/`    | Movement, `WeaponManager`, inventory, spread, shots, decals          |
| `scripts/range/`     | Environment and target builders, range logic                         |
| `scripts/ui/`        | HUD, inventory UI, pause menu                                        |
| `scripts/pickups/`   | Pickup behavior                                                      |
| `scripts/resources/` | `WeaponResource`, `CaliberResource`                                  |
| `assets/`            | 3D models and textures for firearms                                  |
| `export_presets.cfg` | Export presets (Linux, Windows, macOS)                               |

## Builds

Godot writes platform builds under `export/` (contents are gitignored; only `.gitkeep` files are tracked). Presets are defined in `export_presets.cfg`:

- **Linux** → `export/linux/` (example binary name: `GGBB.x86_64`)
- **Windows Desktop** → `export/windows/`
- **macOS** (universal) → `export/mac/`

## Platforms (in order of priority)

- Linux
- Windows
- macOS

## Third-party assets

Model credits and licenses (CC BY 4.0 where noted) are listed in `[attributions.md](attributions.md)`.
