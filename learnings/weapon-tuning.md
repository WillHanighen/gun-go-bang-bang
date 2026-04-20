# Weapon tuning

## Shotgun spread

- Treat real-world shotgun spread references as full pattern spread, not the internal half-angle used by the ballistics code.
- For now, target roughly `2.5` degrees total buckshot spread at rest.
- In data terms, that means buckshot `pellet_spread_deg` should stay around `0.85` while shotgun base handling spread remains around `0.4`.
- Keep `12ga 00 Buck` as the default shotgun shell selection; longer-range buckshot like `000 Buck` should be an alternate load, not the default.

## Inventory and spread state

- Moving a weapon through the inventory should not make it less accurate.
- Do not persist temporary `current_spread` bloom across inventory moves, slot swaps, or re-equips.
- When restoring a weapon from inventory state, keep ammo, fire mode, caliber, and reload progress, but reset spread to the weapon's `base_spread`.

## Pistol hand space

- Equipment slots now behave like loadout grids: `primary` and `secondary` can hold up to two items if both are one-handed and their footprints fit.
- Large or otherwise two-hand weapons should reserve the whole active loadout and not share a slot with another equipped item.
- A single one-handed pistol with no second-hand item should get a support bonus rather than pretending there is a second gun.
- Dual-wield: **left mouse** fires hand 1; **right mouse** fires hand 2 when a second weapon is equipped. **Right mouse** is ADS only when the second hand has no gun (single-gun or empty off-hand).
- Hold **Alt** so the off-hand is targeted for fire mode (`V`) and reload / hold-to-open caliber wheel (`R` picks the wheel hand at press time, so use Alt there for hand 2).
