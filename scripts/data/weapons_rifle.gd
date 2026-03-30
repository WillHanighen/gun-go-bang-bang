class_name WeaponsRifle
extends RefCounted
## Rifles and carbines using rifle ammunition.


static func register(calibers: Dictionary, out_weapons: Array[WeaponResource]) -> void:
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
	m4a1.recoil_vertical = 2.5
	m4a1.recoil_horizontal_range = 0.85
	m4a1.recoil_recovery_rate = 8.0
	m4a1.recoil_mitigation = 0.1
	m4a1.ads_time = 0.28
	out_weapons.append(m4a1)
