class_name BasePart
extends StaticBody3D

signal destroyed(part: Node)

@export var part_id := ""
@export var base_id := "starter_base"
@export var max_health := 120.0
@export var health := 120.0
@export var locked := false


func _ready() -> void:
	add_to_group("survival_base_part")
	if part_id.is_empty():
		part_id = "%s_%d" % [name, get_instance_id()]
	set_meta("material_type", "wood")


func take_damage(amount: float, _hit_position: Vector3 = global_position, _direction: Vector3 = Vector3.ZERO) -> void:
	health = maxf(health - maxf(amount, 0.0), 0.0)
	if health <= 0.0:
		destroyed.emit(self)
		queue_free()


func repair(amount: float) -> void:
	health = minf(health + maxf(amount, 0.0), max_health)


func to_save_data() -> Dictionary:
	return {
		"id": part_id,
		"base_id": base_id,
		"position": [global_position.x, global_position.y, global_position.z],
		"health": health,
		"max_health": max_health,
		"locked": locked,
		"kind": "base_part",
	}

