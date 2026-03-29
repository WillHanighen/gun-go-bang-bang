class_name WeaponResource
extends Resource

enum FireMode { SEMI, BURST, AUTO, PUMP }

@export var weapon_name: String = ""
@export var calibers: Array[CaliberResource] = []
@export var fire_modes: Array[FireMode] = [FireMode.SEMI]
@export var burst_count: int = 2
@export var fire_rate: float = 600.0
@export var magazine_size: int = 30
@export var reload_time: float = 2.0

@export_group("Accuracy")
@export var base_spread: float = 1.0
@export var spread_increase_per_shot: float = 0.5
@export var max_spread: float = 5.0
@export var spread_recovery_rate: float = 8.0

@export_group("Handling")
## Seconds to reach full ADS. Pistols ~0.15, SMGs ~0.2, rifles ~0.3, shotguns ~0.35
@export var ads_time: float = 0.25

@export_group("Recoil")
@export var recoil_vertical: float = 2.0
@export var recoil_horizontal_range: float = 0.5
@export var recoil_recovery_rate: float = 6.0
@export var recoil_mitigation: float = 0.0
## 1.0 = normal upward kick, -1.0 = downward (Super V / Vector)
@export var recoil_direction: float = 1.0


func get_seconds_between_shots() -> float:
	if fire_rate <= 0.0:
		return 1.0
	return 60.0 / fire_rate


func get_effective_recoil_vertical() -> float:
	return recoil_vertical * (1.0 - recoil_mitigation) * recoil_direction


func get_effective_recoil_horizontal() -> float:
	return recoil_horizontal_range * (1.0 - recoil_mitigation)
