class_name ItemPickup
extends Area3D

@export var item_id := ""
@export var display_name := ""
@export var category := "resource"
@export var quantity := 1
@export var max_stack := 50
@export var weight := 0.1
@export var inventory_size := Vector2i(1, 1)
@export var caliber_name := ""
@export_range(1.0, 6.0, 0.1) var interaction_range := 2.8
@export_range(0.0, 360.0, 1.0) var spin_speed_deg := 70.0
@export_range(0.0, 0.5, 0.01) var bob_height := 0.06
@export_range(0.0, 8.0, 0.1) var bob_speed := 1.8

var _visual_root: Node3D
var _base_visual_y := 0.0
var _bob_phase := 0.0


func _ready() -> void:
	collision_layer = 16
	collision_mask = 0
	monitoring = false
	_build_default_visual()
	_base_visual_y = _visual_root.position.y
	_bob_phase = fmod(absf(global_position.x) * 0.73 + absf(global_position.z) * 0.41, TAU)


func _process(delta: float) -> void:
	if not _visual_root:
		return
	_visual_root.rotate_y(deg_to_rad(spin_speed_deg) * delta)
	_bob_phase += delta * bob_speed
	_visual_root.position.y = _base_visual_y + sin(_bob_phase) * bob_height


func get_display_name() -> String:
	if not display_name.is_empty():
		return display_name
	if not caliber_name.is_empty():
		return "%s x%d" % [caliber_name, quantity]
	return "%s x%d" % [item_id, quantity]


func get_prompt_text() -> String:
	return "[F]: Pick up %s" % get_display_name()


func get_prompt_text_for(player: Node) -> String:
	var player_inventory: PlayerInventory = player.get_node_or_null("PlayerInventory") as PlayerInventory
	if player_inventory and not player_inventory.has_room_for_stack(_make_stack_data()):
		return "[F]: No room for %s" % get_display_name()
	return get_prompt_text()


func can_player_pick_up(from_position: Vector3) -> bool:
	return global_position.distance_to(from_position) <= interaction_range


func pick_up(player: Node) -> bool:
	var player_inventory: PlayerInventory = player.get_node_or_null("PlayerInventory") as PlayerInventory
	if not player_inventory:
		return false
	var item_id_added: int = player_inventory.add_stack(_make_stack_data())
	if item_id_added == -1:
		return false
	queue_free()
	return true


func _make_stack_data() -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": get_display_name(),
		"category": category,
		"count": maxi(quantity, 1),
		"max_stack": maxi(max_stack, 1),
		"weight": maxf(weight, 0.0),
		"size": inventory_size,
		"caliber_name": caliber_name,
	}


func _build_default_visual() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "VisualRoot"
	add_child(_visual_root)

	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.25, 0.35)
	mesh_i.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.72, 0.28) if category == "ammo" else Color(0.45, 0.72, 0.86)
	mesh_i.set_surface_override_material(0, mat)
	mesh_i.position.y = 0.35
	_visual_root.add_child(mesh_i)

	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.75
	col.shape = sphere
	add_child(col)

