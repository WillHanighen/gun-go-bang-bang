extends Node3D

const PlayerScene := preload("res://scenes/player/player.tscn")
const ZombieScene := preload("res://scenes/survival/zombie.tscn")
const WeaponPickupScene := preload("res://scenes/pickups/weapon_pickup.tscn")
const HUDScript := preload("res://scripts/ui/hud.gd")
const PauseMenuScript := preload("res://scripts/ui/pause_menu.gd")
const RangeEnvironmentBuilderScript := preload("res://scripts/range/range_environment_builder.gd")
const SaveSlotFiles := preload("res://scripts/survival/survival_save_slots.gd")

const M1911_MODEL := preload("res://assets/M1911/m1911_handgun 1k.glb")
const M4A1_MODEL := preload("res://assets/M4A1/m4a1_rifle 1k.glb")

const FLOOR_SIZE := Vector2(96, 96)
const ZOMBIE_SPAWN_RADIUS := 34.0
const ZOMBIE_COUNT := 12

var player: CharacterBody3D


func _apply_survival_menu_boot() -> void:
	var root := get_tree().root
	if not root.has_meta(&"survival_slot_index"):
		return
	var slot: int = root.get_meta(&"survival_slot_index")
	root.remove_meta(&"survival_slot_index")
	var write_stub := false
	if root.has_meta(&"survival_write_stub"):
		write_stub = root.get_meta(&"survival_write_stub")
		root.remove_meta(&"survival_write_stub")
	if write_stub:
		SaveSlotFiles.write_new_game_stub(slot)


func _ready() -> void:
	_apply_survival_menu_boot()
	RangeEnvironmentBuilderScript.build(self, false)
	_build_floor()
	_spawn_player()
	_spawn_weapon_pickups()
	_spawn_zombies_ring()
	_create_hud()
	_create_pause_menu()


func _build_floor() -> void:
	var ground_a := StaticBody3D.new()
	ground_a.name = "Ground"

	var mesh_i := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = FLOOR_SIZE
	mesh_i.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.28, 0.2)
	mesh_i.set_surface_override_material(0, mat)
	ground_a.add_child(mesh_i)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(FLOOR_SIZE.x, 0.2, FLOOR_SIZE.y)
	col.shape = box
	col.position.y = -0.1
	ground_a.add_child(col)

	add_child(ground_a)


func _spawn_player() -> void:
	player = PlayerScene.instantiate()
	player.position = Vector3(0, 1.0, 0)
	add_child(player)


func _spawn_weapon_pickups() -> void:
	var root := Node3D.new()
	root.name = "WeaponPickups"
	add_child(root)

	var p1: WeaponPickup = WeaponPickupScene.instantiate()
	p1.position = Vector3(6, 0, 5)
	p1.weapon_name = "M1911"
	p1.model_scene = M1911_MODEL
	p1.model_rotation_degrees = Vector3(0, -90, 0)
	p1.model_scale = Vector3(0.22, 0.22, 0.22)
	root.add_child(p1)

	var p2: WeaponPickup = WeaponPickupScene.instantiate()
	p2.position = Vector3(-6, 0, 5)
	p2.weapon_name = "M4A1"
	p2.model_scene = M4A1_MODEL
	p2.model_rotation_degrees = Vector3(0, 180, 0)
	p2.model_scale = Vector3(0.045, 0.045, 0.045)
	root.add_child(p2)


func _spawn_zombies_ring() -> void:
	var root := Node3D.new()
	root.name = "Zombies"
	add_child(root)
	var step := TAU / float(ZOMBIE_COUNT)
	for i in ZOMBIE_COUNT:
		var z := ZombieScene.instantiate()
		var ang := step * float(i)
		z.position = Vector3(cos(ang) * ZOMBIE_SPAWN_RADIUS, 1.0, sin(ang) * ZOMBIE_SPAWN_RADIUS)
		root.add_child(z)


func _create_hud() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "HUD"
	var hud_ctrl := Control.new()
	hud_ctrl.name = "HUDControl"
	hud_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_ctrl.set_script(HUDScript)
	hud_layer.add_child(hud_ctrl)
	add_child(hud_layer)


func _create_pause_menu() -> void:
	var pause_layer := CanvasLayer.new()
	pause_layer.name = "PauseLayer"
	pause_layer.layer = 10
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var pause_root := Control.new()
	pause_root.name = "PauseMenu"
	pause_root.set_script(PauseMenuScript)
	pause_layer.add_child(pause_root)
	add_child(pause_layer)
