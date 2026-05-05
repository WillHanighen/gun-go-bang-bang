# (codename) Gun Go Bang Bang

## ive not decided on a name yet

A **Godot 4.6** first-person project pivoting toward **survival / zombie-apocalypse** gameplay: procedural **shooting range** for now (weapon pickups, grid inventory, ballistics including penetration), with **grounded movement** (walk, sprint, crouch, jump) instead of arena-style skill movement. Still a codename sandbox, not a shipped-title commitment.

## Tone and direction

Creative target is **playful survival**: zombies / scarcity / danger are on-brand, but **not** nitty-gritty sims, grimdark misery, or tacticool cosplay. Think tension plus jokes, not “authentic suffering.”

- Keep **toyetic, readable** characters (pill silhouettes, accessories) and room for dumb-fun weapons — goofy survival, not faux-realism.
- **Movement and moment-to-moment combat** should skew **readable and weighty** over Krunker-like air control or wall-tech.
- Systems can stay crunchy (inventory, ballistics) while **UI and copy** stay light and punchy where it helps.
- Avoid lore dumps and tacticool framing unless it is clearly a joke.

If something has to choose between "serious authenticity" and "funny, memorable, still fun to play," the project should usually prefer the second option.

## Requirements

- [Godot 4.6](https://godotengine.org/download) (project targets `4.6` with **Forward+** rendering and **Jolt** 3D physics)

Clone the repo and open the project folder in the Godot editor, or run the main scene from the command line:

```bash
godot --path /path/to/gun-go-bang-bang
```

The entry scene is `res://scenes/ui/main_menu.tscn`; from there you reach the playable **shooting range** at `res://scenes/range/shooting_range.tscn`, or **Zombie Apocalypse** at `res://scenes/survival/zombie_arena.tscn` (simple horde + pickups; expand later).

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

When you reach the playable **shooting range** from **Play → Shooting range**, the scene file includes the **floor** (ground mesh, collision, and lane markings); **sky, lighting, and distance labels** are still created at runtime along with **steel plates and paper targets** at **10 / 25 / 50 / 100 m**, and **wood** and **thin metal** panels in front of extra plates to try penetration. The **player starts unarmed**; every firearm in the project is available as a **world pickup** (Colt Python, M1911, KRISS Vector, Remington 870, M4A1, Mossberg 590) placed on the range. Weapons live in a **grid inventory** (`WeaponDatabase` autoload supplies definitions; `PlayerInventory` tracks items and equipped slots).

## Project layout (high level)


| Path                 | Role                                                                 |
| -------------------- | -------------------------------------------------------------------- |
| `scenes/range/`      | Shooting range scene; pickups and authored props                     |
| `scenes/survival/`   | Zombie arena horde mode (WIP)                                        |
| `scenes/ui/`         | Main menu (+ 3D `main_menu_showcase` backdrop); settings panel reused by pause and menu |
| `scenes/player/`     | Player body (pill silhouette), camera, weapon view, inventory        |
| `scenes/pickups/`    | Weapon pickup scenes                                                 |
| `scripts/autoload/`  | `InputSetup` (default keymap), `WeaponDatabase` (calibers + weapons) |
| `scripts/combat/`    | Ballistics                                                           |
| `scripts/data/`      | Caliber and weapon registration (`ammo_*`, `weapons_*`)              |
| `scripts/player/`    | Movement, `WeaponManager`, inventory, spread, shots, decals          |
| `scripts/range/`     | Environment and target builders, range logic                         |
| `scripts/survival/`  | Zombie horde mode (arena + zombie actors)                            |
| `scripts/ui/`        | HUD, inventory UI, pause menu, main menu, shared settings UI         |
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
