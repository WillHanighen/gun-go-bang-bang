class_name CorpsePickup
extends Area3D

@export var corpse_id := ""
@export var display_name := "Dropped backpack"
@export_range(1.0, 6.0, 0.1) var interaction_range := 3.0

var inventory_data: Dictionary = {}
var weapon_data: Dictionary = {}


func _ready() -> void:
	collision_layer = 16
	collision_mask = 0
	monitoring = false
	if corpse_id.is_empty():
		corpse_id = "corpse_%d" % Time.get_ticks_msec()
	_build_visual()


func get_display_name() -> String:
	return display_name


func get_prompt_text() -> String:
	return "[F]: Recover %s" % display_name


func get_prompt_text_for(_player: Node) -> String:
	return get_prompt_text()


func can_player_pick_up(from_position: Vector3) -> bool:
	return global_position.distance_to(from_position) <= interaction_range


func pick_up(player: Node) -> bool:
	var player_inventory: PlayerInventory = player.get_node_or_null("PlayerInventory") as PlayerInventory
	if player_inventory and not inventory_data.is_empty():
		player_inventory.restore_inventory(inventory_data)
	var weapon_manager := player.get_node_or_null("WeaponManager")
	if weapon_manager and weapon_manager.has_method("restore_weapon_state") and not weapon_data.is_empty():
		weapon_manager.call("restore_weapon_state", weapon_data)
	queue_free()
	return true


func to_save_data() -> Dictionary:
	return {
		"id": corpse_id,
		"display_name": display_name,
		"position": [global_position.x, global_position.y, global_position.z],
		"inventory": inventory_data.duplicate(true),
		"weapons": weapon_data.duplicate(true),
	}


func restore_from_save(data: Dictionary) -> void:
	corpse_id = str(data.get("id", corpse_id))
	display_name = str(data.get("display_name", display_name))
	var pos: Variant = data.get("position", [])
	if typeof(pos) == TYPE_ARRAY and (pos as Array).size() >= 3:
		global_position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
	inventory_data = (data.get("inventory", {}) as Dictionary).duplicate(true)
	weapon_data = (data.get("weapons", {}) as Dictionary).duplicate(true)


func _build_visual() -> void:
	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.85, 0.35, 0.55)
	mesh_i.mesh = box
	mesh_i.position.y = 0.28
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.36, 0.18)
	mesh_i.set_surface_override_material(0, mat)
	add_child(mesh_i)

	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.85
	col.shape = sphere
	add_child(col)

