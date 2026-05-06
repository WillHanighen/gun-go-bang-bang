# Survival Mode Spec

This document defines the intended shape of Survival as a persistent, toyetic zombie survival sandbox. It is not a tuning sheet yet. Exact numbers for heat, hunger, horde sizes, decay, and cooldowns should come later after prototypes exist.

## Design Pillars

- **Toyetic survival:** the stakes are real, but the presentation stays goofy, readable, and pill-person friendly. Avoid grim milsim fantasy.
- **Player-made stories:** the main goal is not to beat a campaign. It is to scavenge, build, get overconfident, recover, and make a base worth defending.
- **Light attracts trouble:** bases need light, heat, power, and noise to feel alive, but those same signals become zombie bait, especially at night.
- **Clear pressure, low tedium:** survival meters should create readable decisions without becoming inventory soup or chore simulation.
- **LAN-first, server-aware:** the first target is singleplayer with optional LAN hosting, but ownership and save rules should not block future dedicated servers.

## Mode Fantasy

Survival drops the player into a persistent procedural island where they scavenge sparse POIs, build or fortify a home, research better gear, and defend against zombies that get bolder as the save gets hotter.

The long-term arc is open-ended: create the best base you can and withstand hordes that slowly become more dangerous through local heat and world events. There is no fixed win condition.

## Core Loops

### Player Loop

1. Wake up or spawn in.
2. Check health, stamina, hunger, thirst, temperature, fatigue, infection, and injuries.
3. Choose a short-term goal: food, water, loot, research materials, base repair, fuel, a contract, or corpse recovery.
4. Leave shelter, scavenge, fight or avoid zombies, and manage carry weight.
5. Return with loot, stash it, craft, research, repair, eat, rest, and prepare for night.

### World Loop

1. The procedural island reveals itself through exploration.
2. Roads connect suburbs, woods, towns, rare small cities, and dangerous hotspots.
3. Loot slowly renews through regrowth, slow respawn, zombie drops, radio contracts, and world events.
4. Weather changes visibility, audio, temperature pressure, zombie behavior, and rain collector output.
5. Local areas accumulate heat from noise, light, generators, vehicles, gunfire, crafting, kills, and base activity.

### Base Loop

1. Start with a bedroll or rough shelter.
2. Claim or fortify a building, or build a grid-based Rust-like base.
3. Place a tool cupboard to control building authorization.
4. Add storage, locks, workstations, defenses, lights, water, heat, and power.
5. Feed upkeep so the base slowly repairs itself and does not decay on top of weather and zombie damage.
6. Balance comfort and productivity against the heat created by lights, generators, noise, and stored value.

### Horde Loop

1. Local heat and world events raise zombie attention.
2. At night, bright player bases become obvious targets because the sun is no longer the brightest thing around.
3. Zombies investigate lights, noise, generators, vehicles, radios, and active work areas.
4. If they discover a base, they may attempt entry through weak points, doors, windows, climbing routes, or block damage.
5. Serious horde and weather events are forecast through NWS-style radio alerts where available.
6. The player survives, repairs, adapts, and either reduces heat or builds stronger.

### Recovery Loop

1. Death leaves the player's gear behind on a body, backpack, or infected player-zombie.
2. Respawn depends on valid bed access unless the save is permadeath.
3. Beds near the death location are blocked, and beds can have cooldowns.
4. If no valid bed exists in a non-permadeath save, the player gets a fallback starter respawn.
5. Recovering the corpse is the main cost of death.
6. If infection caused the death, the player must kill their former zombie to recover items.

## World And Exploration

Survival uses a procedural island with natural borders, road-network generation, and biome layers.

Initial world zones:

- **Coast / spawn fringe:** safe-ish starting resources, weather exposure, low-value loot.
- **Suburbs:** houses, garages, shops, light tools, food, early crafting goods.
- **Woods:** wood, food, animals, exposure risk, quieter travel.
- **Towns and rare small cities:** high-value loot, dense zombies, more events, higher risk.
- **Hotspots:** dangerous POIs with better loot, special zombies, and stronger heat buildup.

The world should support nomad play, but long-distance hauling should naturally push players toward backpacks, containers, carts, vehicles, and eventually a base.

## Map And Navigation

Navigation should feel Rust-like:

- The world map fills in as players explore.
- A minimap supports nearby orientation and basic travel.
- Explored terrain, roads, buildings, POIs, player markers, beds, bases, death locations, radio events, and supply drops can appear on the map.
- Live zombie positions are not shown by default.
- Later tools may add overlays for weather, radio warnings, base heat, noise, or light radius.

The map is a navigation aid, not a combat radar.

## Survival Meters

The explicit survival systems are:

- **Health:** direct damage and recovery.
- **Stamina:** sprinting, melee pressure, exhaustion, and carry strain.
- **Hunger and thirst:** day-to-day scavenging pressure.
- **Temperature:** cold nights, wet weather, shelter, clothing, fires, and heating.
- **Infection:** bite or scratch risk that worsens if untreated.
- **Fatigue:** rest, sleep quality, and death recovery pressure.
- **Injuries:** simple debuffs such as limping, shaky aim, slower actions, or reduced stamina.

These systems should be readable and tunable. The goal is meaningful decisions, not a hardcore medical simulator.

## Feedback And UI

Feedback should be clear and Rust-like:

- Normal health and stamina HUD.
- Top-screen survival/status readouts where useful.
- Hitmarkers and readable combat confirmation.
- Clear status-effect indicators for hunger, thirst, cold, wetness, fatigue, infection, and injuries.
- Strong weather and temperature feedback in animation, audio, and visuals.
- Radio alerts for incoming hordes, severe weather, supply contracts, and major world events.

Text can be playful, but it should never obscure what is happening.

## Death And Respawn

Survival supports normal respawn saves and optional permadeath saves.

Save creation:

- Permadeath is locked at save creation.
- In permadeath saves, death ends that survivor according to the save rules.
- In non-permadeath saves, recovery should always be possible, but death should still hurt.

Respawn rules:

- There is no generic respawn currency by default.
- A valid bed is the preferred respawn route.
- Beds near the death location cannot be selected.
- Beds can have cooldowns.
- Destroyed beds cannot be used.
- If no valid bed exists, non-permadeath saves provide a fallback starter respawn.
- Corpse recovery is the main cost of death.

Bed tiers:

- **Bedroll:** cheap, portable, vulnerable, and weaker.
- **Cot:** basic indoor respawn for early shelters.
- **Proper bed:** best normal respawn, supports better recovery.
- **Vehicle bed:** mobile and useful, but risky and expensive to maintain.

Infection death:

- Bites or scratches can infect.
- Infection is a meter that worsens over time.
- Untreated infection can kill.
- A player who dies from infection becomes a zombie carrying recoverable items.
- That player-zombie must be killed to retrieve the gear.

## Bases, Building, And Ownership

Players can stay nomadic, but a proper base is recommended. Some form of bed or respawn infrastructure is required for reliable respawning.

Building should combine:

- Fortifying existing structures.
- Grid-based building.
- Rust-like deployables.
- Barricades, doors, locks, traps, storage, lights, generators, water collectors, workstations, and defenses.

Tool cupboards:

- Control build authorization.
- Define the claimed base area.
- Consume upkeep resources.
- Scale upkeep cost with base size/value.
- Slowly repair base damage while stocked.
- Allow decay if not stocked, on top of weather and zombie damage.
- Become important raid or siege targets.

Ownership and access:

- Tool cupboard authorization controls whether a player can build in an area.
- Beds and cupboards have ownership or authorization.
- Inventories, storage, and vehicles can be locked.
- Authorized players can open locks.
- Unauthorized players must break in if rules allow it.
- Loose dropped loot is fair game.

## Base Heat

Base heat is the main bridge between comfort and danger.

Heat sources include:

- Lights.
- Generators.
- Vehicles.
- Gunfire.
- Loud crafting or machinery.
- Radios.
- Large stockpiles or valuable base structures.
- Frequent zombie kills.
- Player traffic.

Consequences:

- Zombies investigate hot areas.
- At night, light becomes especially dangerous.
- Roaming hordes can stumble onto a base naturally.
- High heat can trigger or intensify horde events.
- Players should be able to understand heat through radio forecasts, tool cupboard or map-table readouts, and world feedback such as distant moans, birds fleeing, or flickering lights.

## Zombies

Zombies should be readable, toyetic threats, not gross horror props.

Baseline behavior:

- Attracted to noise and light.
- More active and dangerous at night.
- Prefer doors, windows, weak points, and obvious entry routes.
- Can damage blocks if blocked long enough.
- Some can climb, stack, crawl, or squeeze through lazy defenses.
- Target bright or noisy objects such as lamps, generators, vehicles, radios, and machines.

Special roles:

- **Runner:** fast panic pressure, especially at night.
- **Screamer:** calls more zombies if not handled quickly.
- **Sparkhead / light-seeker:** obsessed with powered objects and bulbs.
- **Biome or POI variants:** occasional adapted zombies tied to towns, woods, or special locations.

Scaling:

- Driven primarily by local heat and world events.
- Events introduce stronger or stranger threats over time.
- Avoid relying only on a global day counter.

## Combat And Gear

Combat should be weighty but not milsim.

Core expectations:

- Melee matters, especially early.
- Throwables and traps are major survival tools.
- Base defenses matter as much as handheld weapons during horde pressure.
- Guns should keep the current weapon-system direction.
- Ammo comes from inventory, not an assumed wormhole armory supply.
- Basic ammo can be crafted with the right station and resources.
- Ammo quality can affect jams, noise, damage, reliability, or special behavior.

Durability:

- Weapons and tools degrade.
- Clothing and armor degrade.
- Base parts show damage states.
- Durability should create tension without becoming constant repair chores.

## Inventory And Hauling

The inventory should build on the current backpack/category direction.

Rules:

- Backpacks, categories, equipped slots, and containers stay central.
- Item weight matters on top of slots.
- Containers matter: backpacks, crates, coolers, toolboxes, carts, and vehicles.
- Inventory interactions should stay quick and convenient.
- Hauling more stuff should be a real reason to use carts and vehicles.

## Crafting, Skills, And Research

Crafting should support field improvisation, base progression, and specialized stations.

Crafting types:

- Field crafts for essentials.
- Special stations for advanced items.
- Skills and recipes for gated crafts.
- Workbenches for specific categories.

Progression sources:

- Use-based progression.
- Found books, manuals, recipe cards, or similar learning items.
- Research bench study of encountered items.

Research bench:

- Takes time and resources.
- Can consume or break down items.
- May require repeat samples for advanced recipes.
- Lets the player turn found objects into craftable knowledge.

Tech tracks:

- Junk.
- Shop.
- Proper base.
- Gunsmith.
- Vehicle.
- Medical / chemistry.
- Farming / cooking.
- Electronics / power.
- Clothing / tailoring.

## Food, Farming, And Nature

Food and water should matter day to day without dominating every minute.

Sources and pressures:

- Houses, shops, and towns provide scavenged food.
- Woods and animals provide renewable food/materials.
- Farming and cooking support long-term bases.
- Weather can affect water collection.
- Temperature and wetness make shelter, clothing, fires, and heating meaningful.
- Animals can be food sources, material sources, threats, or noise-makers.

## Vehicles

Vehicles are not central early, but they should be valuable later.

Uses:

- Travel long distances more quickly.
- Haul more loot.
- Move more safely through some areas.
- Support mobile-base or vehicle-bed play in limited form.

Costs:

- Fuel.
- Noise.
- Repairs.
- Storage risk.
- Attraction from zombies due to sound and lights.

## Radio, Events, And Objectives

The mode should guide without forcing a questline.

Objective style:

- No fixed ending.
- Early tutorial goals cover food, water, shelter, bedroll, basic weapon/tool, and eventually base claiming.
- Radio and map events provide optional direction.

Radio features:

- NWS-style horde alerts.
- Severe weather and temperature warnings.
- Random contracts for supply drops.
- World events such as crashed convoys, odd signals, blackouts, migrations, or trader rumors.

NPCs:

- Rare wandering traders can exist.
- Radio contracts and event rewards matter more than a full NPC economy.

## Multiplayer And Save Rules

The first implementation target is singleplayer with optional LAN.

LAN model:

- One player hosts a persistent world.
- Friends join temporarily as new survivors.
- Difficulty scales with active players.
- The host world persists when the host saves.

Future server-aware rules:

- Ownership, permissions, locks, and save settings should be cleanly separated from singleplayer assumptions.
- Dedicated servers may keep time moving slowly.
- Server loads may summarize mild decay/regrowth instead of simulating every offline detail.
- Offline protection should be designed later if dedicated servers become real.

Save creation settings:

- Permadeath.
- PvE / PvPvE / PvP.
- Zombie amount, strength, and escalation.
- Survival strictness.
- Loot abundance and respawn rate.
- World seed, size, and biomes.

Locked at creation:

- Permadeath.
- World seed.

Potentially changeable:

- PvP mode.
- Some difficulty rates.
- Loot abundance if the save owner allows it.

PvP consequences:

- If PvP is enabled, violence should create noise and heat.
- Reputation consequences can exist later, but are not required for the first implementation.

## Implementation Guidance

Early prototypes should focus on the systems that prove the mode's identity:

1. Persistent world/save shell.
2. Bedroll, death, corpse recovery, and fallback respawn.
3. Inventory-fed ammo and basic scavenging.
4. Rust-like explored map plus minimap.
5. Tool cupboard claim, basic building, locks, and upkeep.
6. Heat sources that attract zombies.
7. Night behavior and a simple horde event.
8. Radio alerts for horde/weather events.

Keep systems modular:

- Survival meters should be data-driven and tunable.
- Base heat should be queryable by zombies, radio, UI, and future map overlays.
- Ownership should not assume only one local player.
- Save settings should be explicit and serialized.
- World generation should expose POIs, roads, biomes, and discovered map cells as durable data.

## Open Tuning Gaps

These are the remaining real unknowns, not missing design direction:

- Exact fallback respawn location and starter items.
- Exact first-hour tutorial order after food/water and bedroll.
- Numeric values for base heat, upkeep, horde thresholds, bed cooldowns, survival drain rates, and loot respawn.
- Dedicated-server offline protection rules.
- Whether PvP reputation matters in the first real PvP implementation.

