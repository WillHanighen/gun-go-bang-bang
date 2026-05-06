class_name ToolCupboard
extends StaticBody3D

const HeatSourceScript := preload("res://scripts/survival/heat/heat_source.gd")

@export var cupboard_id := "starter_tc"
@export var base_id := "starter_base"
@export var claim_radius := 18.0
@export var upkeep := 60.0
@export var upkeep_drain_per_minute := 1.0
@export var health := 180.0
@export var authorized_player_ids: Array[String] = ["local_player"]

var _heat_source: Node


func _ready() -> void:
	add_to_group("survival_tool_cupboard")
	set_meta("material_type", "wood")
	_heat_source = HeatSourceScript.new()
	_heat_source.name = "HeatSource"
	_heat_source.heat_value = 2.0
	_heat_source.noise_value = 0.25
	_heat_source.light_value = 0.0
	add_child(_heat_source)
	_build_visual()


func _process(delta: float) -> void:
	upkeep = maxf(upkeep - (upkeep_drain_per_minute / 60.0) * delta, 0.0)
	if _heat_source:
		_heat_source.heat_value = 2.0 + claim_radius / 18.0


func is_authorized(player_id: String) -> bool:
	return authorized_player_ids.has(player_id)


func take_damage(amount: float, _hit_position: Vector3 = global_position, _direction: Vector3 = Vector3.ZERO) -> void:
	health = maxf(health - maxf(amount, 0.0), 0.0)
	if health <= 0.0:
		queue_free()


func to_save_data() -> Dictionary:
	return {
		"id": cupboard_id,
		"base_id": base_id,
		"position": [global_position.x, global_position.y, global_position.z],
		"claim_radius": claim_radius,
		"upkeep": upkeep,
		"health": health,
		"authorized": authorized_player_ids.duplicate(),
	}


func _build_visual() -> void:
	if get_child_count() > 1:
		return
	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 1.2, 0.55)
	mesh_i.mesh = box
	mesh_i.position.y = 0.6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.36, 0.24, 0.14)
	mesh_i.set_surface_override_material(0, mat)
	add_child(mesh_i)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	col.shape = shape
	col.position = mesh_i.position
	add_child(col)

