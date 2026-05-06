class_name SurvivalVehicle
extends StaticBody3D

const HeatSourceScript := preload("res://scripts/survival/heat/heat_source.gd")

@export var vehicle_id := "starter_hauler"
@export var display_name := "Questionable Hauler"
@export var fuel := 25.0
@export var storage_inventory: Dictionary = {"items": [], "active_slot": "primary", "next_item_id": 1}
@export var locked := false
@export var owner_id := "local_player"


func _ready() -> void:
	add_to_group("survival_vehicle")
	set_meta("material_type", "metal")
	var heat := HeatSourceScript.new()
	heat.name = "HeatSource"
	heat.heat_value = 1.0
	heat.noise_value = 1.5
	add_child(heat)
	_build_visual()


func to_save_data() -> Dictionary:
	return {
		"id": vehicle_id,
		"display_name": display_name,
		"position": [global_position.x, global_position.y, global_position.z],
		"fuel": fuel,
		"storage": storage_inventory.duplicate(true),
		"locked": locked,
		"owner_id": owner_id,
	}


func _build_visual() -> void:
	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.2, 0.8, 1.2)
	mesh_i.mesh = box
	mesh_i.position.y = 0.55
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.22, 0.16)
	mesh_i.set_surface_override_material(0, mat)
	add_child(mesh_i)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	col.shape = shape
	col.position = mesh_i.position
	add_child(col)

