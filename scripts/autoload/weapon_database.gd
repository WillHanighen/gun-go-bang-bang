extends Node

var calibers: Dictionary = {}
var weapons: Array[WeaponResource] = []


func _ready() -> void:
	_init_calibers()
	_init_weapons()


# -- helpers -------------------------------------------------------------------

func _cal(
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


# -- calibers ------------------------------------------------------------------

func _init_calibers() -> void:
	# ---- .45 ACP family ----
	calibers["45_fmj"] = _cal(
		".45 ACP FMJ", CaliberResource.AmmoType.FMJ,
		45.0, 253.0, 0.30, 25.0, 100.0, 0.15)
	calibers["45_ap"] = _cal(
		".45 ACP AP", CaliberResource.AmmoType.AP,
		38.0, 260.0, 0.55, 25.0, 100.0, 0.12, 1, 0.0, 0.85)
	calibers["45_hp"] = _cal(
		".45 ACP JHP", CaliberResource.AmmoType.HP,
		55.0, 245.0, 0.10, 20.0, 80.0, 0.10, 1, 0.0, 1.4)
	calibers["45_incen"] = _cal(
		".45 ACP Incendiary", CaliberResource.AmmoType.INCENDIARY,
		40.0, 250.0, 0.25, 22.0, 90.0, 0.12, 1, 0.0, 1.0, 10.0)

	# ---- 9x19mm family ----
	calibers["9_fmj"] = _cal(
		"9x19mm FMJ", CaliberResource.AmmoType.FMJ,
		35.0, 360.0, 0.25, 30.0, 120.0, 0.10)
	calibers["9_ap"] = _cal(
		"9x19mm AP", CaliberResource.AmmoType.AP,
		30.0, 375.0, 0.45, 30.0, 120.0, 0.08, 1, 0.0, 0.85)
	calibers["9_hp"] = _cal(
		"9x19mm JHP", CaliberResource.AmmoType.HP,
		42.0, 340.0, 0.08, 25.0, 90.0, 0.08, 1, 0.0, 1.4)
	calibers["9_subsonic"] = _cal(
		"9x19mm Subsonic", CaliberResource.AmmoType.SUBSONIC,
		32.0, 300.0, 0.22, 20.0, 80.0, 0.12)

	# ---- 12-gauge family ----
	calibers["12_00buck"] = _cal(
		"12ga 00 Buck", CaliberResource.AmmoType.BUCKSHOT,
		12.0, 396.0, 0.20, 18.0, 37.0, 0.05, 9, 5.0)
	calibers["12_4buck"] = _cal(
		"12ga #4 Buck", CaliberResource.AmmoType.BUCKSHOT,
		6.0, 381.0, 0.12, 14.0, 28.0, 0.03, 27, 6.5)
	calibers["12_slug"] = _cal(
		"12ga Slug", CaliberResource.AmmoType.SLUG,
		80.0, 457.0, 0.60, 50.0, 100.0, 0.30)
	calibers["12_ap_slug"] = _cal(
		"12ga AP Slug", CaliberResource.AmmoType.AP,
		70.0, 480.0, 0.75, 45.0, 95.0, 0.25, 1, 0.0, 0.85)

	# ---- 5.56x45mm NATO family ----
	calibers["556_m855"] = _cal(
		"5.56 M855 FMJ", CaliberResource.AmmoType.FMJ,
		40.0, 940.0, 0.50, 200.0, 500.0, 0.20)
	calibers["556_m855a1"] = _cal(
		"5.56 M855A1 AP", CaliberResource.AmmoType.AP,
		35.0, 961.0, 0.70, 200.0, 500.0, 0.18, 1, 0.0, 0.85)
	calibers["556_mk262"] = _cal(
		"5.56 Mk262 OTM", CaliberResource.AmmoType.HP,
		48.0, 850.0, 0.30, 180.0, 450.0, 0.15, 1, 0.0, 1.3)
	calibers["556_m856"] = _cal(
		"5.56 M856 Tracer", CaliberResource.AmmoType.TRACER,
		38.0, 930.0, 0.45, 190.0, 480.0, 0.18)


# -- weapons -------------------------------------------------------------------

func _init_weapons() -> void:
	var cal_45: Array[CaliberResource] = [
		calibers["45_fmj"], calibers["45_ap"],
		calibers["45_hp"], calibers["45_incen"],
	]

	var glock := WeaponResource.new()
	glock.weapon_name = "Glock 45"
	glock.calibers = cal_45
	glock.fire_modes = [WeaponResource.FireMode.SEMI]
	glock.burst_count = 1
	glock.fire_rate = 400.0
	glock.magazine_size = 13
	glock.reload_time = 1.8
	glock.base_spread = 1.0
	glock.spread_increase_per_shot = 0.5
	glock.max_spread = 5.0
	glock.spread_recovery_rate = 8.0
	glock.recoil_vertical = 2.5
	glock.recoil_horizontal_range = 0.8
	glock.recoil_recovery_rate = 6.0
	glock.recoil_mitigation = 0.0
	glock.ads_time = 0.15
	weapons.append(glock)

	var m1911 := WeaponResource.new()
	m1911.weapon_name = "M1911"
	m1911.calibers = cal_45
	m1911.fire_modes = [WeaponResource.FireMode.SEMI]
	m1911.burst_count = 1
	m1911.fire_rate = 350.0
	m1911.magazine_size = 7
	m1911.reload_time = 2.0
	m1911.base_spread = 0.8
	m1911.spread_increase_per_shot = 0.4
	m1911.max_spread = 4.5
	m1911.spread_recovery_rate = 7.0
	m1911.recoil_vertical = 2.8
	m1911.recoil_horizontal_range = 0.6
	m1911.recoil_recovery_rate = 5.5
	m1911.recoil_mitigation = 0.05
	m1911.ads_time = 0.15
	weapons.append(m1911)

	var vector := WeaponResource.new()
	vector.weapon_name = "KRISS Vector"
	vector.calibers = cal_45
	vector.fire_modes = [
		WeaponResource.FireMode.SEMI,
		WeaponResource.FireMode.BURST,
		WeaponResource.FireMode.AUTO,
	]
	vector.burst_count = 2
	vector.fire_rate = 1200.0
	vector.magazine_size = 25
	vector.reload_time = 2.2
	vector.base_spread = 0.6
	vector.spread_increase_per_shot = 0.3
	vector.max_spread = 4.0
	vector.spread_recovery_rate = 10.0
	vector.recoil_vertical = 1.0
	vector.recoil_horizontal_range = 0.3
	vector.recoil_recovery_rate = 12.0
	vector.recoil_mitigation = 0.6
	vector.recoil_direction = -1.0
	vector.ads_time = 0.2
	weapons.append(vector)

	var cal_12ga: Array[CaliberResource] = [
		calibers["12_00buck"], calibers["12_4buck"],
		calibers["12_slug"], calibers["12_ap_slug"],
	]

	var r870 := WeaponResource.new()
	r870.weapon_name = "Remington 870"
	r870.calibers = cal_12ga
	r870.fire_modes = [WeaponResource.FireMode.PUMP]
	r870.burst_count = 1
	r870.fire_rate = 80.0
	r870.magazine_size = 6
	r870.reload_time = 4.0
	r870.base_spread = 0.5
	r870.spread_increase_per_shot = 0.0
	r870.max_spread = 0.5
	r870.spread_recovery_rate = 10.0
	r870.recoil_vertical = 5.0
	r870.recoil_horizontal_range = 1.0
	r870.recoil_recovery_rate = 4.0
	r870.recoil_mitigation = 0.0
	r870.ads_time = 0.35
	weapons.append(r870)

	var cal_556: Array[CaliberResource] = [
		calibers["556_m855"], calibers["556_m855a1"],
		calibers["556_mk262"], calibers["556_m856"],
	]

	var m4a1 := WeaponResource.new()
	m4a1.weapon_name = "M4A1"
	m4a1.calibers = cal_556
	m4a1.fire_modes = [WeaponResource.FireMode.SEMI, WeaponResource.FireMode.AUTO]
	m4a1.burst_count = 1
	m4a1.fire_rate = 700.0
	m4a1.magazine_size = 30
	m4a1.reload_time = 2.5
	m4a1.base_spread = 0.3
	m4a1.spread_increase_per_shot = 0.2
	m4a1.max_spread = 3.0
	m4a1.spread_recovery_rate = 6.0
	m4a1.recoil_vertical = 1.5
	m4a1.recoil_horizontal_range = 0.5
	m4a1.recoil_recovery_rate = 8.0
	m4a1.recoil_mitigation = 0.1
	m4a1.ads_time = 0.28
	weapons.append(m4a1)
