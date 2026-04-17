class_name WeaponPickup
extends Area3D

@export var weapon_name := ""
@export var pickup_name := ""
@export var model_scene: PackedScene
@export var model_position := Vector3.ZERO
@export var model_rotation_degrees := Vector3.ZERO
@export var model_scale := Vector3.ONE
@export_range(1.0, 6.0, 0.1) var interaction_range := 2.8
@export_range(0.0, 360.0, 1.0) var spin_speed_deg := 90.0
@export_range(0.0, 0.5, 0.01) var bob_height := 0.08
@export_range(0.0, 8.0, 0.1) var bob_speed := 2.1

@onready var visual_root: Node3D = $VisualRoot
@onready var model_anchor: Node3D = $VisualRoot/ModelAnchor

var _base_visual_y := 0.0
var _bob_phase := 0.0
var _weapon_data: WeaponResource


func _ready() -> void:
	collision_layer = 16
	collision_mask = 0
	monitoring = false
	_base_visual_y = visual_root.position.y
	_bob_phase = fmod(absf(global_position.x) * 0.83 + absf(global_position.z) * 0.37, TAU)
	_resolve_weapon_data()
	_spawn_model()


func _process(delta: float) -> void:
	visual_root.rotate_y(deg_to_rad(spin_speed_deg) * delta)
	_bob_phase += delta * bob_speed
	visual_root.position.y = _base_visual_y + sin(_bob_phase) * bob_height


func get_display_name() -> String:
	if not pickup_name.is_empty():
		return pickup_name
	if _weapon_data:
		return _weapon_data.weapon_name
	return weapon_name


func get_prompt_text() -> String:
	return "[F]: Pick up %s" % get_display_name()


func get_prompt_text_for(player: Node) -> String:
	_resolve_weapon_data()
	var player_inventory: PlayerInventory = player.get_node_or_null("PlayerInventory") as PlayerInventory
	if player_inventory and not player_inventory.has_room_for_weapon(_weapon_data):
		return "[F]: No room for %s" % get_display_name()
	return get_prompt_text()


func can_player_pick_up(from_position: Vector3) -> bool:
	return global_position.distance_to(from_position) <= interaction_range


func pick_up(player: Node) -> bool:
	_resolve_weapon_data()
	if not _weapon_data:
		return false

	var weapon_manager: Node = player.get_node_or_null("WeaponManager")
	if not weapon_manager:
		return false

	var weapon_index: int = weapon_manager.add_weapon(_weapon_data, true)
	if weapon_index == -1:
		return false

	queue_free()
	return true


func _resolve_weapon_data() -> void:
	if _weapon_data:
		return
	_weapon_data = WeaponDatabase.get_weapon_by_name(weapon_name)
	if pickup_name.is_empty() and _weapon_data:
		pickup_name = _weapon_data.weapon_name


func _spawn_model() -> void:
	if not model_scene or model_anchor.get_child_count() > 0:
		return

	var model := model_scene.instantiate() as Node3D
	if not model:
		return

	model.position = model_position
	model.rotation_degrees = model_rotation_degrees
	model.scale = model_scale
	model_anchor.add_child(model)
