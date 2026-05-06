---
name: Survival Mode Spec
overview: "Create a full survival-mode design spec for a persistent, toyetic survival sandbox: procedural island exploration, Rust-like map/minimap, base building, heat-driven zombie hordes, survival meters, crafting/research, and LAN-first multiplayer rules."
todos:
  - id: draft-spec
    content: Write the full survival-mode markdown spec from the confirmed design decisions.
    status: completed
  - id: capture-loops
    content: Describe the player loop, world loop, base loop, horde loop, and recovery loop.
    status: completed
  - id: mark-gaps
    content: Include only genuine unresolved tuning gaps, not already-answered questions.
    status: completed
  - id: preserve-memory
    content: After approval, add a concise durable project note under learnings/.
    status: completed
isProject: false
---

# Survival Mode Spec Plan

## Core Direction

Build a persistent survival sandbox where players scavenge, travel, build, die, recover, and improve a base against escalating zombie pressure. The mode is singleplayer-first with optional LAN hosting, but systems should be shaped so future dedicated servers are possible.

The vibe should be toyetic survival: readable danger, goofy pill-person presentation, clear feedback, and mechanically grounded systems without grim milsim seriousness.

## Main Gameplay Loop

- Spawn into a procedural island world and quickly secure food, water, warmth, and a bedroll.
- Scavenge sparse-to-medium POIs along roads, suburbs, woods, towns, rare small cities, and dangerous hotspots.
- Haul loot back by backpack, container, cart, or vehicle.
- Research found items, unlock recipes, craft better tools, weapons, stations, and base parts.
- Fortify an existing structure or build a grid-based Rust-like base with deployables.
- Manage base heat from lights, noise, generators, stored value, and player activity.
- Survive nights and escalating horde events, then repair, recover, expand, and push farther out.

## World And Map

- Procedural island with road-network generation and biome layers.
- First biomes/zones: suburbs, woods, towns/small cities.
- Loot renews through world regrowth, slow respawn, zombie drops, radio contracts, and world events.
- Rust-like world map fills in as players explore.
- Minimap supports navigation and nearby orientation.
- Map shows explored terrain, roads, buildings, POIs, markers, beds, bases, death locations, and radio events.
- No live zombie radar by default.

## Survival Systems

- Explicit systems: health, stamina, hunger, thirst, temperature, infection, fatigue.
- Injuries are simple debuffs rather than detailed body-part simulation.
- Weather affects visibility, audio, temperature, zombie behavior, and rain collectors.
- Animals can provide food/materials and can also be threats.
- UI feedback should feel Rust-like: normal health/stamina HUD, top-screen status readouts, hitmarkers, clear status-effect indicators, and radio alerts.

## Death And Respawn

- Non-permadeath saves always allow recovery, but valid beds matter.
- No respawn currency by default.
- Respawn cost comes from corpse recovery, bed cooldowns, death-zone bed restrictions, and potentially injury debt.
- If no valid bed exists, fallback starter respawn should exist unless permadeath is enabled.
- Beds near the death location cannot be selected.
- Bed tiers: bedroll, cot, proper bed, vehicle bed.
- If a player dies from infection, they become a zombie carrying recoverable items and must be killed to retrieve gear.

## Bases And Ownership

- Players can be nomads, but a proper base is strongly recommended.
- Respawning requires some form of bed/base infrastructure.
- Building should combine fortifying existing structures with grid-based Rust-like building and deployables.
- Tool cupboard authorization controls building permissions.
- Tool cupboards consume upkeep, bigger bases cost more, upkeep slowly repairs damage, and no upkeep allows decay plus environmental damage.
- Tool cupboards also become important raid/siege targets.
- Inventories and vehicles can be locked; only authorized players can access without breaking in.
- Loose dropped loot is fair game.

## Zombies And Hordes

- Zombies are attracted to noise, lights, generators, vehicles, gunfire, crafting activity, and general world heat.
- At night, zombies are more dangerous because bright player bases become obvious targets without the sun dominating their attention.
- Zombies can choose to attack bases they discover and attempt entry.
- They prefer doors/windows/weak points, can damage blocks if blocked, can climb/stack/crawl in some cases, and target noisy/bright objects.
- Horde scaling is driven by local heat and events, not just a simple day counter.
- Serious horde/weather events are forecast through NWS-style radio alerts, with warning strictness as a difficulty/save option.
- Special zombies: runners, screamers, sparkheads/light-seekers, plus occasional biome/POI-adapted variants.

## Combat And Gear

- Combat should be weighty but not milsim.
- Melee, throwables, traps, and base defenses should matter heavily.
- Use the current weapon system, but ammo must come from the player inventory rather than an assumed armory supply.
- Basic ammo can be crafted with the right station/resources.
- Ammo quality can affect jams, noise, damage, or other weapon behavior.
- Weapons/tools, clothing/armor, and base parts have durability/condition.

## Crafting, Skills, And Research

- Crafting includes field crafts, special stations, and skill/recipe-gated items.
- Skills come from use-based progression and found books/manuals.
- Research bench lets players study encountered items.
- Research can require time/resources, item breakdown, and repeated samples for advanced recipes.
- Tech tracks: junk, shop, proper base, gunsmith, vehicle, medical/chemistry, farming/cooking, electronics/power, clothing/tailoring.

## Multiplayer And Save Rules

- Current goal: singleplayer with optional LAN.
- LAN model: one player hosts a persistent world, friends join as new survivors, and difficulty scales with active players.
- Future dedicated servers should be possible later, so ownership, permissions, save settings, and authority boundaries should be designed cleanly.
- Save creation settings: permadeath, PvE/PvPvE/PvP, zombie strength/escalation, survival strictness, loot abundance, world seed/size/biomes.
- Locked at creation: permadeath and world seed.
- PvP mode can be changeable later.
- Singleplayer time pauses; future servers may keep time moving slowly and may summarize mild decay/regrowth on load.

## Objectives And Radio

- No fixed win condition.
- Long-term goal is to build the best base possible and withstand hordes that become more dangerous as the save progresses.
- Early tutorial goals should cover food/water, bedroll, basic survival, and eventually base claiming.
- Radio supports random contracts for supply drops, world events, horde alerts, and severe weather warnings.
- Rare wandering traders can exist, but the radio-contract/event loop matters more than a full NPC economy.

## Remaining Real Gaps

- Exact fallback respawn behavior: where the player appears and what starter items they receive.
- Exact first-hour tutorial order after food/water and bedroll.
- Exact numbers for base heat, upkeep, horde thresholds, and bed cooldowns.
- Future dedicated-server offline protection rules.
- Whether reputation consequences for PvP should matter in the first implementation.

## Deliverable

Draft this as a proper markdown design spec, ideally `docs/survival-mode-spec.md`, and preserve the core long-term decisions in `learnings/` after approval so future implementation work follows the same assumptions.