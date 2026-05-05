# Player movement (survival FPS)

## What this is for

First-person locomotion should feel like **survival / grounded** control: walk, sprint, crouch, jump — readable and weighty, not arena skill-jump tech.

## Goals

- **Walk** as the default floor speed; **sprint** as a deliberate faster gait (still sub-arcade).
- **Crouch** lowers capsule and head; speed multiplier applies while crouched.
- **Jump** is a single impulse from the floor; no special wall interactions for movement.
- **Air control** uses the same `move_toward` horizontal model as the ground but with **much lower** accel/decel than ground (`AIR_ACCEL` / `AIR_DECEL` in `player_controller.gd`), so you steer a little in the air without building speed or curving like a source-style strafe.

## Non-goals (do not reintroduce casually)

- **Wall jumps** or probe-based wall kick-offs.
- **Strong air strafe** (wish-direction acceleration that stacks horizontal velocity differently than ground).
- **`AIR_MAX_SPEED`-style** caps that still behave like arena air control.

## Implementation anchor

Main logic: [`scripts/player/player_controller.gd`](../scripts/player/player_controller.gd). Weapon spread still uses `_air_spread` for jump inaccuracy via `get_spread_state()`.

## Easy to get wrong

- Copy-pasting “Quake/Source” air accel back in for “snappier” feel — it fights the survival read.
- Tuning sprint so it feels like the default move speed — sprint should read as a **committed** run.
