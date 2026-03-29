class_name CaliberResource
extends Resource

enum AmmoType { FMJ, AP, HP, INCENDIARY, SUBSONIC, TRACER, BUCKSHOT, SLUG }

@export var caliber_name: String = ""
@export var ammo_type: AmmoType = AmmoType.FMJ
@export var base_damage: float = 0.0
@export var muzzle_velocity: float = 0.0
@export var penetration_power: float = 0.0
@export var effective_range: float = 0.0
@export var max_range: float = 0.0
@export var min_damage_mult: float = 0.0
@export var pellet_count: int = 1
@export var pellet_spread_deg: float = 0.0

@export_group("Ammo Modifiers")
@export var flesh_damage_mult: float = 1.0
@export var incendiary_damage: float = 0.0


func get_damage_at_distance(distance: float) -> float:
	if distance <= effective_range:
		return base_damage
	if distance >= max_range:
		return base_damage * min_damage_mult
	var t := (distance - effective_range) / (max_range - effective_range)
	return base_damage * lerpf(1.0, min_damage_mult, t * t)
