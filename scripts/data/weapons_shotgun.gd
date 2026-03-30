class_name WeaponsShotgun
extends RefCounted
## Pump and semi-auto shotguns.


static func register(calibers: Dictionary, out_weapons: Array[WeaponResource]) -> void:
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
	r870.recoil_vertical = 7.5
	r870.recoil_horizontal_range = 1.45
	r870.recoil_recovery_rate = 4.0
	r870.recoil_mitigation = 0.0
	r870.ads_time = 0.35
	out_weapons.append(r870)

	var moss590 := WeaponResource.new()
	moss590.weapon_name = "Mossberg 590"
	moss590.calibers = cal_12ga
	moss590.fire_modes = [WeaponResource.FireMode.PUMP]
	moss590.burst_count = 1
	moss590.fire_rate = 85.0
	moss590.magazine_size = 8
	moss590.reload_time = 3.6
	moss590.base_spread = 0.48
	moss590.spread_increase_per_shot = 0.0
	moss590.max_spread = 0.48
	moss590.spread_recovery_rate = 10.0
	moss590.recoil_vertical = 6.8
	moss590.recoil_horizontal_range = 1.35
	moss590.recoil_recovery_rate = 4.2
	moss590.recoil_mitigation = 0.0
	moss590.ads_time = 0.33
	out_weapons.append(moss590)
