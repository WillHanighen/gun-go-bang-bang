# Survival mode direction

## What this covers

Survival is intended to become a persistent, toyetic zombie survival sandbox. The full working spec lives in [`docs/survival-mode-spec.md`](../docs/survival-mode-spec.md).

## Correct understanding

- Survival is singleplayer-first with optional LAN, but ownership, saves, permissions, and authority should stay clean enough for future dedicated servers.
- The mode is not a grim milsim or hardcore life sim. It should feel like playful survival: real pressure, readable systems, goofy pill-person presentation.
- The main long-term goal is open-ended base improvement and horde defense, not a fixed campaign ending.
- The world should be a procedural island with roads, biomes, sparse-to-medium POIs, dangerous hotspots, Rust-like map reveal, and a minimap.
- Bases should use Rust-like ideas: tool cupboards, authorization, locks, upkeep, deployables, grid building, and fortifying existing structures.
- Light, noise, power, vehicles, gunfire, crafting, stored value, and traffic create base heat that attracts zombies, especially at night.
- Respawn should not use a generic currency by default. The cost is valid beds, bed cooldowns, death-zone restrictions, corpse recovery, and possible injury debt.
- Infection deaths create player-zombies carrying recoverable gear.
- Combat should be weighty but not milsim. Melee, throwables, traps, base defenses, and inventory-fed ammo matter.

## Future changes should preserve

- Rust-like map reveal plus minimap, without default live zombie radar.
- Tool cupboard authorization as the source of build permission.
- Backpack/category inventory with weight layered on top.
- Research bench learning from found items using time, resources, item breakdown, and repeat samples.
- Radio as the source of NWS-style horde and weather alerts, plus contracts and world events.
- Only treat the remaining unknowns as tuning gaps: fallback respawn details, first-hour order, numeric thresholds, future server offline protection, and PvP reputation timing.

## Current implementation notes

- Survival save slots are real versioned JSON saves, not marker stubs. Version 2 saves must keep explicit `settings`, `world`, `player`, `inventory`, `weapons`, `bases`, `zombies`, `time`, `radio`, and `map` sections even while some sections are placeholders.
- `zombie_arena.gd` is currently the Survival scene coordinator: it consumes the existing menu boot metadata, creates/loads `SurvivalRunState`, keeps the arena playable, restores player position/rotation, and exposes a manual save through the pause menu.

