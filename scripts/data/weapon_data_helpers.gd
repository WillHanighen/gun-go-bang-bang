class_name WeaponDataHelpers
extends RefCounted
## Shared factory for CaliberResource entries used by ammo category scripts.


static func make_caliber(
	cal_name: String,
	type: CaliberResource.AmmoType,
	dmg: float,
	vel: float,
	pen: float,
	eff_range: float,
	max_rng: float,
	min_mult: float,
	pellets: int = 1,
	spread: float = 0.0,
	flesh: float = 1.0,
	incen: float = 0.0,
) -> CaliberResource:
	var c := CaliberResource.new()
	c.caliber_name = cal_name
	c.ammo_type = type
	c.base_damage = dmg
	c.muzzle_velocity = vel
	c.penetration_power = pen
	c.effective_range = eff_range
	c.max_range = max_rng
	c.min_damage_mult = min_mult
	c.pellet_count = pellets
	c.pellet_spread_deg = spread
	c.flesh_damage_mult = flesh
	c.incendiary_damage = incen
	return c
