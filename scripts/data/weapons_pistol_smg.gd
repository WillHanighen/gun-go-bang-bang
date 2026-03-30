class_name WeaponsPistolSmg
extends RefCounted
## Handguns and SMGs that use pistol-caliber ammunition.


static func register(calibers: Dictionary, out_weapons: Array[WeaponResource]) -> void:
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
	glock.recoil_vertical = 3.6
	glock.recoil_horizontal_range = 1.15
	glock.recoil_recovery_rate = 6.0
	glock.recoil_mitigation = 0.0
	glock.ads_time = 0.15
	out_weapons.append(glock)

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
	m1911.recoil_vertical = 4.0
	m1911.recoil_horizontal_range = 1.0
	m1911.recoil_recovery_rate = 5.5
	m1911.recoil_mitigation = 0.05
	m1911.ads_time = 0.15
	out_weapons.append(m1911)

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
	vector.recoil_vertical = 2.4
	vector.recoil_horizontal_range = 0.55
	vector.recoil_recovery_rate = 12.0
	vector.recoil_mitigation = 0.6
	vector.recoil_direction = -1.0
	vector.ads_time = 0.2
	# Super V: first 2 rounds stay on one point; bulk of impulse arrives slightly after the pair (delayed recoil).
	vector.burst_compensation_shots = 2
	vector.burst_compensation_recoil_mult = 0.07
	vector.burst_compensation_spread_mult = 0.2
	vector.burst_delayed_recoil_delay_sec = 0.09
	vector.burst_delayed_recoil_impulse_strength = 0.5
	vector.burst_delayed_recoil_horizontal_factor = 0.52
	out_weapons.append(vector)
