extends Node3D

const PlayerScene := preload("res://scenes/player/player.tscn")
const ZombieScene := preload("res://scenes/survival/zombie.tscn")
const WeaponPickupScene := preload("res://scenes/pickups/weapon_pickup.tscn")
const ItemPickupScript := preload("res://scripts/pickups/item_pickup.gd")
const CorpsePickupScript := preload("res://scripts/pickups/corpse_pickup.gd")
const HUDScript := preload("res://scripts/ui/hud.gd")
const PauseMenuScript := preload("res://scripts/ui/pause_menu.gd")
const RangeEnvironmentBuilderScript := preload("res://scripts/range/range_environment_builder.gd")
const SaveSlotFiles := preload("res://scripts/survival/survival_save_slots.gd")
const SurvivalRunStateScript := preload("res://scripts/survival/survival_run_state.gd")
const SurvivalWorldManagerScript := preload("res://scripts/survival/world/survival_world_manager.gd")
const SurvivalMapManagerScript := preload("res://scripts/survival/map/survival_map_manager.gd")
const HeatDirectorScript := preload("res://scripts/survival/heat/heat_director.gd")
const HeatSourceScript := preload("res://scripts/survival/heat/heat_source.gd")
const RadioDirectorScript := preload("res://scripts/survival/radio/radio_director.gd")
const ZombieDirectorScript := preload("res://scripts/survival/directors/zombie_director.gd")
const BasePartScript := preload("res://scripts/survival/base/base_part.gd")
const ToolCupboardScript := preload("res://scripts/survival/base/tool_cupboard.gd")
const ProgressionManagerScript := preload("res://scripts/survival/crafting/survival_progression_manager.gd")
const WeatherDirectorScript := preload("res://scripts/survival/weather/weather_director.gd")
const OwnershipManagerScript := preload("res://scripts/survival/ownership/ownership_manager.gd")
const AnimalScript := preload("res://scripts/survival/actors/survival_animal.gd")
const VehicleScript := preload("res://scripts/survival/vehicles/survival_vehicle.gd")

const M1911_MODEL := preload("res://assets/M1911/m1911_handgun 1k.glb")
const M4A1_MODEL := preload("res://assets/M4A1/m4a1_rifle 1k.glb")

const FLOOR_SIZE := Vector2(96, 96)
const ZOMBIE_SPAWN_RADIUS := 34.0
const ZOMBIE_COUNT := 12
const SURVIVAL_COORDINATOR_GROUP := "survival_run_coordinator"
const META_SURVIVAL_SLOT_INDEX := &"survival_slot_index"
const META_SURVIVAL_WRITE_STUB := &"survival_write_stub"
const BED_DEATH_BLOCK_RADIUS := 12.0
const BED_RESPAWN_COOLDOWN := 20.0

var player: CharacterBody3D
var _run_state
var _beds: Array[Dictionary] = []
var _world_manager: Node3D
var _map_manager: Node
var _heat_director: Node
var _radio_director: Node
var _zombie_director: Node
var _progression_manager: Node
var _weather_director: Node
var _ownership_manager: Node


func _ready() -> void:
	add_to_group(SURVIVAL_COORDINATOR_GROUP)
	_boot_survival_run()
	RangeEnvironmentBuilderScript.build(self, false)
	_build_world()
	_create_map_manager()
	_create_radio_and_heat()
	_create_progression_weather_ownership()
	_spawn_bed_root()
	_spawn_starter_base()
	_spawn_living_world_stubs()
	_spawn_player()
	_spawn_weapon_pickups()
	_spawn_zombies_ring()
	_create_zombie_director()
	_restore_corpses()
	_create_hud()
	_create_pause_menu()


func _process(delta: float) -> void:
	if _run_state:
		_run_state.advance_time(delta)
	if player and _map_manager and _map_manager.has_method("update_player_position"):
		_map_manager.call("update_player_position", player.global_position)


func _boot_survival_run() -> void:
	_run_state = SurvivalRunStateScript.new()
	var root := get_tree().root
	if not root.has_meta(META_SURVIVAL_SLOT_INDEX):
		_run_state.start_session_only()
		return
	var slot := int(root.get_meta(META_SURVIVAL_SLOT_INDEX))
	root.remove_meta(META_SURVIVAL_SLOT_INDEX)
	var create_new_game := false
	if root.has_meta(META_SURVIVAL_WRITE_STUB):
		create_new_game = bool(root.get_meta(META_SURVIVAL_WRITE_STUB))
		root.remove_meta(META_SURVIVAL_WRITE_STUB)
	_run_state.boot_from_slot(slot, create_new_game)


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


func _build_world() -> void:
	_world_manager = SurvivalWorldManagerScript.new()
	_world_manager.name = "WorldManager"
	add_child(_world_manager)
	var save_data: Dictionary = _run_state.get_save_data() if _run_state else SaveSlotFiles.build_default_save(-1, {})
	_world_manager.call("build_from_save", save_data.get("world", {}) as Dictionary)


func _create_map_manager() -> void:
	_map_manager = SurvivalMapManagerScript.new()
	_map_manager.name = "MapManager"
	add_child(_map_manager)
	var save_data: Dictionary = _run_state.get_save_data() if _run_state else SaveSlotFiles.build_default_save(-1, {})
	_map_manager.call(
		"setup_from_save",
		save_data.get("map", {}) as Dictionary,
		48.0
	)
	_map_manager.call("add_marker", "starter_bedroll", "Starter Bedroll", Vector3(0, 0, 2.5), "bed")


func _create_radio_and_heat() -> void:
	_radio_director = RadioDirectorScript.new()
	_radio_director.name = "RadioDirector"
	add_child(_radio_director)
	_heat_director = HeatDirectorScript.new()
	_heat_director.name = "HeatDirector"
	add_child(_heat_director)
	if _run_state:
		var save_data: Dictionary = _run_state.get_save_data()
		_radio_director.call("restore_from_save", save_data.get("radio", {}) as Dictionary)


func _create_progression_weather_ownership() -> void:
	var save_data: Dictionary = _run_state.get_save_data() if _run_state else {}
	_progression_manager = ProgressionManagerScript.new()
	_progression_manager.name = "ProgressionManager"
	add_child(_progression_manager)
	_progression_manager.call("restore_from_save", save_data.get("progression", {}) as Dictionary)

	_weather_director = WeatherDirectorScript.new()
	_weather_director.name = "WeatherDirector"
	add_child(_weather_director)
	_weather_director.call("restore_from_save", save_data.get("weather", {}) as Dictionary)
	if _weather_director.has_signal("weather_changed") and _radio_director:
		_weather_director.connect("weather_changed", Callable(self, "_on_weather_changed"))

	_ownership_manager = OwnershipManagerScript.new()
	_ownership_manager.name = "OwnershipManager"
	add_child(_ownership_manager)
	_ownership_manager.call("restore_from_save", save_data.get("ownership", {}) as Dictionary)
	_ownership_manager.call("authorize", "starter_tc", SaveSlotFiles.DEFAULT_PLAYER_ID, "owner")


func _spawn_starter_base() -> void:
	var root := Node3D.new()
	root.name = "StarterBase"
	add_child(root)

	var tc := ToolCupboardScript.new()
	tc.name = "StarterToolCupboard"
	tc.position = Vector3(4, 0, 2.5)
	root.add_child(tc)

	for i in range(4):
		var wall := StaticBody3D.new()
		wall.set_script(BasePartScript)
		wall.name = "ScrapWall_%d" % i
		var angle := float(i) * TAU / 4.0
		wall.position = Vector3(4, 0, 2.5) + Vector3(cos(angle) * 3.0, 0.0, sin(angle) * 3.0)
		var mesh_i := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(3.0, 1.6, 0.28)
		mesh_i.mesh = box
		mesh_i.position.y = 0.8
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.38, 0.32, 0.24)
		mesh_i.set_surface_override_material(0, mat)
		wall.rotation.y = angle
		wall.add_child(mesh_i)
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = box.size
		col.shape = shape
		col.position = mesh_i.position
		wall.add_child(col)
		root.add_child(wall)

	var light := OmniLight3D.new()
	light.name = "BadIdeaPorchLight"
	light.position = Vector3(4, 2.4, 2.5)
	light.light_energy = 2.5
	light.omni_range = 12.0
	var heat := HeatSourceScript.new()
	heat.name = "HeatSource"
	heat.heat_value = 2.0
	heat.light_value = 7.0
	light.add_child(heat)
	root.add_child(light)
	if _map_manager:
		_map_manager.call("add_marker", "starter_base", "Starter Base", Vector3(4, 0, 2.5), "base")


func _spawn_living_world_stubs() -> void:
	var animals := Node3D.new()
	animals.name = "Animals"
	add_child(animals)
	var deer := CharacterBody3D.new()
	deer.set_script(AnimalScript)
	deer.name = "SnackDeer"
	deer.position = Vector3(16, 1, -12)
	animals.add_child(deer)

	var vehicles := Node3D.new()
	vehicles.name = "Vehicles"
	add_child(vehicles)
	var hauler := StaticBody3D.new()
	hauler.set_script(VehicleScript)
	hauler.name = "QuestionableHauler"
	hauler.position = Vector3(-5, 0, -5)
	vehicles.add_child(hauler)
	if _map_manager:
		_map_manager.call("add_marker", "starter_hauler", "Questionable Hauler", hauler.position, "vehicle")

	if _radio_director and _radio_director.has_method("generate_supply_contract"):
		var contract := _radio_director.call("generate_supply_contract", _run_state.world_seed if _run_state else 1, Vector3.ZERO) as Dictionary
		var pos: Variant = contract.get("position", [])
		if _map_manager and typeof(pos) == TYPE_ARRAY and (pos as Array).size() >= 3:
			_map_manager.call("add_marker", str(contract.get("id", "contract")), "Supply Drop", Vector3(float(pos[0]), float(pos[1]), float(pos[2])), "radio")


func _spawn_player() -> void:
	player = PlayerScene.instantiate()
	player.position = _run_state.get_player_position() if _run_state else SaveSlotFiles.DEFAULT_SPAWN_POSITION
	player.rotation.y = _run_state.get_player_rotation_y() if _run_state else 0.0
	var head := player.get_node_or_null("Head") as Node3D
	if head and _run_state:
		head.rotation.x = _run_state.get_player_head_pitch()
	add_child(player)
	if player.has_signal("player_died"):
		player.connect("player_died", Callable(self, "_on_player_died"))
	_restore_player_runtime_state()


func _spawn_bed_root() -> void:
	var root := Node3D.new()
	root.name = "Beds"
	add_child(root)
	var save_data: Dictionary = _run_state.get_save_data() if _run_state else {}
	var bases := save_data.get("bases", {}) as Dictionary
	var saved_beds := bases.get("beds", []) as Array
	if saved_beds.is_empty():
		_beds = [
			{
				"id": "starter_bedroll",
				"tier": "bedroll",
				"position": SaveSlotFiles.vector3_to_array(Vector3(0, 0.05, 2.5)),
				"cooldown_until": 0.0,
				"destroyed": false,
			}
		]
	else:
		_beds.clear()
		for bed in saved_beds:
			if typeof(bed) == TYPE_DICTIONARY:
				_beds.append((bed as Dictionary).duplicate(true))
	for bed_data in _beds:
		_spawn_bed_visual(bed_data, root)


func _spawn_bed_visual(bed_data: Dictionary, root: Node3D) -> void:
	var bed := Node3D.new()
	bed.name = str(bed_data.get("id", "bed"))
	bed.position = SaveSlotFiles.array_to_vector3(bed_data.get("position", []), Vector3.ZERO)
	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.4, 0.16, 0.65)
	mesh_i.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.32, 0.68)
	mesh_i.set_surface_override_material(0, mat)
	bed.add_child(mesh_i)
	root.add_child(bed)


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

	var ammo_45 := _make_item_pickup(".45 ACP FMJ rounds", "ammo:45_acp_fmj", "ammo", ".45 ACP FMJ", 28, Vector3(3, 0, 8))
	root.add_child(ammo_45)

	var ammo_556 := _make_item_pickup("5.56 M855 FMJ rounds", "ammo:556_m855", "ammo", "5.56 M855 FMJ", 90, Vector3(-3, 0, 8))
	root.add_child(ammo_556)


func _make_item_pickup(
	display_name: String,
	item_id: String,
	category: String,
	caliber_name: String,
	quantity: int,
	pickup_position: Vector3
) -> Area3D:
	var pickup := Area3D.new()
	pickup.set_script(ItemPickupScript)
	pickup.position = pickup_position
	pickup.set("display_name", display_name)
	pickup.set("item_id", item_id)
	pickup.set("category", category)
	pickup.set("caliber_name", caliber_name)
	pickup.set("quantity", quantity)
	pickup.set("max_stack", 120)
	pickup.set("weight", 0.025)
	pickup.set("inventory_size", Vector2i(1, 1))
	return pickup


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


func _create_zombie_director() -> void:
	var zombies := get_node_or_null("Zombies") as Node3D
	_zombie_director = ZombieDirectorScript.new()
	_zombie_director.name = "ZombieDirector"
	add_child(_zombie_director)
	_zombie_director.call("setup", ZombieScene, zombies, _heat_director, _radio_director, player)


func _restore_corpses() -> void:
	var root := Node3D.new()
	root.name = "Corpses"
	add_child(root)
	if not _run_state:
		return
	var save_data: Dictionary = _run_state.get_save_data()
	var player_data := save_data.get("player", {}) as Dictionary
	for corpse_data in player_data.get("corpses", []):
		if typeof(corpse_data) != TYPE_DICTIONARY:
			continue
		var corpse := _make_corpse_pickup(corpse_data as Dictionary)
		root.add_child(corpse)


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
	if _run_state and _run_state.can_save():
		pause_root.call("set_manual_save_enabled", true)
		if pause_root.has_signal("manual_save_requested"):
			pause_root.connect("manual_save_requested", Callable(self, "_on_manual_save_requested"))


func _on_manual_save_requested() -> void:
	if not _run_state:
		return
	_run_state.request_save()
	var saved := _save_current_run()
	var pause_menu := get_tree().get_first_node_in_group("pause_menu")
	if pause_menu and pause_menu.has_method("show_manual_save_feedback"):
		var message := "Survival run saved."
		if not saved:
			message = _run_state.last_save_error
		pause_menu.call("show_manual_save_feedback", saved, message)


func _save_current_run() -> bool:
	if not _run_state:
		return false
	return _run_state.write_runtime_snapshot(_collect_runtime_save_sections())


func _collect_runtime_save_sections() -> Dictionary:
	var current_save: Dictionary = _run_state.get_save_data() if _run_state else {}
	return {
		"world": _collect_world_save_data(current_save.get("world", {}) as Dictionary),
		"player": _collect_player_save_data(current_save.get("player", {}) as Dictionary),
		"inventory": _collect_inventory_save_data(current_save.get("inventory", {}) as Dictionary),
		"weapons": _collect_weapon_save_data(current_save.get("weapons", {}) as Dictionary),
		"bases": _collect_bases_save_data(current_save.get("bases", {}) as Dictionary),
		"zombies": _collect_zombie_save_data(current_save.get("zombies", {}) as Dictionary),
		"time": _collect_time_save_data(current_save.get("time", {}) as Dictionary),
		"radio": _collect_radio_save_data(current_save.get("radio", {}) as Dictionary),
		"map": _collect_map_save_data(current_save.get("map", {}) as Dictionary),
		"progression": _collect_progression_save_data(current_save.get("progression", {}) as Dictionary),
		"ownership": _collect_ownership_save_data(current_save.get("ownership", {}) as Dictionary),
		"weather": _collect_weather_save_data(current_save.get("weather", {}) as Dictionary),
		"vehicles": _collect_vehicle_save_data(current_save.get("vehicles", {}) as Dictionary),
		"animals": _collect_animal_save_data(current_save.get("animals", {}) as Dictionary),
	}


func _collect_world_save_data(previous: Dictionary) -> Dictionary:
	if _world_manager and _world_manager.has_method("serialize_world"):
		return _world_manager.call("serialize_world", previous) as Dictionary
	var data := previous.duplicate(true)
	data["seed"] = _run_state.world_seed if _run_state else int(data.get("seed", 0))
	data["kind"] = SaveSlotFiles.ARENA_WORLD_KIND
	data["spawn_position"] = SaveSlotFiles.vector3_to_array(SaveSlotFiles.DEFAULT_SPAWN_POSITION)
	return data


func _collect_player_save_data(previous: Dictionary) -> Dictionary:
	var data := previous.duplicate(true)
	if not player:
		return data
	data["id"] = SaveSlotFiles.DEFAULT_PLAYER_ID
	data["position"] = SaveSlotFiles.vector3_to_array(player.global_position)
	data["rotation_y"] = player.rotation.y
	var head := player.get_node_or_null("Head") as Node3D
	data["head_pitch"] = head.rotation.x if head else 0.0
	var vitals := player.get_node_or_null("PlayerVitals")
	data["alive"] = not (vitals and vitals.dead)
	if vitals:
		data["vitals"] = vitals.get_snapshot()
	data["corpses"] = _collect_corpse_save_data()
	data["spawn_reason"] = "manual_save"
	return data


func _collect_inventory_save_data(previous: Dictionary) -> Dictionary:
	if not player:
		return previous.duplicate(true)
	var inventory := player.get_node_or_null("PlayerInventory") as PlayerInventory
	if not inventory:
		return previous.duplicate(true)
	var data: Dictionary = inventory.serialize_inventory()
	data["containers"] = previous.get("containers", {})
	return data


func _collect_weapon_save_data(previous: Dictionary) -> Dictionary:
	var data := previous.duplicate(true)
	if not player:
		return data
	var weapon_manager := player.get_node_or_null("WeaponManager")
	if not weapon_manager:
		return data
	if weapon_manager.has_method("serialize_weapon_state"):
		data = weapon_manager.call("serialize_weapon_state") as Dictionary
	var current_weapon := weapon_manager.get("current_weapon_data") as Resource
	data["current_weapon_path"] = current_weapon.resource_path if current_weapon else ""
	data["current_ammo"] = int(weapon_manager.get("current_ammo"))
	data["current_caliber_index"] = int(weapon_manager.get("current_caliber_index"))
	data["current_fire_mode_index"] = int(weapon_manager.get("current_fire_mode_index"))
	return data


func _collect_bases_save_data(previous: Dictionary) -> Dictionary:
	var data := previous.duplicate(true)
	data["beds"] = _beds.duplicate(true)
	var claims: Array[Dictionary] = []
	for tc in get_tree().get_nodes_in_group("survival_tool_cupboard"):
		if tc.has_method("to_save_data"):
			claims.append(tc.call("to_save_data") as Dictionary)
	data["claims"] = claims
	var structures: Array[Dictionary] = []
	for part in get_tree().get_nodes_in_group("survival_base_part"):
		if part.has_method("to_save_data"):
			structures.append(part.call("to_save_data") as Dictionary)
	data["structures"] = structures
	return data


func _restore_player_runtime_state() -> void:
	if not player or not _run_state:
		return
	var save_data: Dictionary = _run_state.get_save_data()
	var inventory := player.get_node_or_null("PlayerInventory") as PlayerInventory
	if inventory:
		inventory.restore_inventory(save_data.get("inventory", {}) as Dictionary)
	var vitals := player.get_node_or_null("PlayerVitals")
	if vitals:
		var player_data := save_data.get("player", {}) as Dictionary
		vitals.restore_from_save(player_data.get("vitals", {}) as Dictionary)
	var weapon_manager := player.get_node_or_null("WeaponManager")
	if weapon_manager:
		if weapon_manager.has_method("set_inventory_ammo_required"):
			weapon_manager.call("set_inventory_ammo_required", true)
		if weapon_manager.has_method("restore_weapon_state"):
			weapon_manager.call("restore_weapon_state", save_data.get("weapons", {}) as Dictionary)


func _collect_zombie_save_data(previous: Dictionary) -> Dictionary:
	var data := previous.duplicate(true)
	var zombies := get_node_or_null("Zombies")
	data["arena_spawn_count"] = ZOMBIE_COUNT
	data["active_count"] = zombies.get_child_count() if zombies else 0
	if _zombie_director and _zombie_director.has_method("serialize_director"):
		data["director"] = _zombie_director.call("serialize_director", data.get("director", {}) as Dictionary)
	return data


func _collect_time_save_data(previous: Dictionary) -> Dictionary:
	var data := previous.duplicate(true)
	data["elapsed_seconds"] = _run_state.elapsed_time_seconds if _run_state else float(data.get("elapsed_seconds", 0.0))
	return data


func _collect_map_save_data(previous: Dictionary) -> Dictionary:
	if _map_manager and _map_manager.has_method("serialize_map"):
		return _map_manager.call("serialize_map", previous) as Dictionary
	return previous.duplicate(true)


func _collect_radio_save_data(previous: Dictionary) -> Dictionary:
	if _radio_director and _radio_director.has_method("serialize_radio"):
		return _radio_director.call("serialize_radio", previous) as Dictionary
	return previous.duplicate(true)


func _collect_progression_save_data(previous: Dictionary) -> Dictionary:
	if _progression_manager and _progression_manager.has_method("serialize_progression"):
		return _progression_manager.call("serialize_progression", previous) as Dictionary
	return previous.duplicate(true)


func _collect_ownership_save_data(previous: Dictionary) -> Dictionary:
	if _ownership_manager and _ownership_manager.has_method("serialize_ownership"):
		return _ownership_manager.call("serialize_ownership", previous) as Dictionary
	return previous.duplicate(true)


func _collect_weather_save_data(previous: Dictionary) -> Dictionary:
	if _weather_director and _weather_director.has_method("serialize_weather"):
		return _weather_director.call("serialize_weather", previous) as Dictionary
	return previous.duplicate(true)


func _collect_vehicle_save_data(previous: Dictionary) -> Dictionary:
	var data := previous.duplicate(true)
	var active: Array[Dictionary] = []
	for vehicle in get_tree().get_nodes_in_group("survival_vehicle"):
		if vehicle.has_method("to_save_data"):
			active.append(vehicle.call("to_save_data") as Dictionary)
	data["active"] = active
	return data


func _collect_animal_save_data(previous: Dictionary) -> Dictionary:
	var data := previous.duplicate(true)
	var active: Array[Dictionary] = []
	for animal in get_tree().get_nodes_in_group("survival_animal"):
		var animal_3d := animal as Node3D
		if animal_3d:
			active.append({
				"name": animal_3d.name,
				"position": SaveSlotFiles.vector3_to_array(animal_3d.global_position),
			})
	data["active"] = active
	return data


func _on_weather_changed(weather: String) -> void:
	if not _radio_director:
		return
	if weather == "rain":
		_radio_director.call("push_alert", "NWS WEATHER ALERT: rain is filling collectors faster. Also, everyone is damp and dramatic.")
	elif weather == "cold_front":
		_radio_director.call("push_alert", "NWS WEATHER ALERT: cold front moving in. Warmth is about to stop being optional.")


func _collect_corpse_save_data() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var corpses := get_node_or_null("Corpses")
	if not corpses:
		return out
	for child in corpses.get_children():
		if child.has_method("to_save_data"):
			out.append(child.call("to_save_data") as Dictionary)
	return out


func _on_player_died(reason: String) -> void:
	if not player:
		return
	var death_position := player.global_position
	var inventory := player.get_node_or_null("PlayerInventory") as PlayerInventory
	var weapon_manager := player.get_node_or_null("WeaponManager")
	var inventory_data: Dictionary = inventory.serialize_inventory() if inventory else {}
	var weapon_data: Dictionary = {}
	if weapon_manager and weapon_manager.has_method("serialize_weapon_state"):
		weapon_data = weapon_manager.call("serialize_weapon_state") as Dictionary
	if inventory:
		inventory.restore_inventory({"items": [], "active_slot": "primary", "next_item_id": 1})
	if weapon_manager and weapon_manager.has_method("restore_weapon_state"):
		weapon_manager.call("restore_weapon_state", {})

	if reason == "infection":
		_spawn_player_zombie(death_position, inventory_data, weapon_data)
	else:
		_spawn_corpse(death_position, inventory_data, weapon_data, "Dropped backpack")

	player.global_position = _choose_respawn_position(death_position)
	if player.has_method("reset_after_respawn"):
		player.call("reset_after_respawn")
	if _run_state:
		_run_state.mark_dirty()


func _choose_respawn_position(death_position: Vector3) -> Vector3:
	var now: float = _run_state.elapsed_time_seconds if _run_state else 0.0
	var selected_index := -1
	for i in range(_beds.size()):
		var bed := _beds[i]
		if bool(bed.get("destroyed", false)):
			continue
		if float(bed.get("cooldown_until", 0.0)) > now:
			continue
		var bed_position := SaveSlotFiles.array_to_vector3(bed.get("position", []), SaveSlotFiles.DEFAULT_SPAWN_POSITION)
		if bed_position.distance_to(death_position) < BED_DEATH_BLOCK_RADIUS:
			continue
		selected_index = i
		break
	if selected_index == -1:
		return SaveSlotFiles.DEFAULT_SPAWN_POSITION + Vector3(-8, 0, -8)
	var selected := _beds[selected_index]
	selected["cooldown_until"] = now + BED_RESPAWN_COOLDOWN
	_beds[selected_index] = selected
	return SaveSlotFiles.array_to_vector3(selected.get("position", []), SaveSlotFiles.DEFAULT_SPAWN_POSITION) + Vector3(0, 0.95, 0)


func _spawn_corpse(corpse_position: Vector3, inventory_data: Dictionary, weapon_data: Dictionary, display_name: String) -> void:
	var corpses := get_node_or_null("Corpses")
	if not corpses:
		corpses = Node3D.new()
		corpses.name = "Corpses"
		add_child(corpses)
	var corpse_data := {
		"id": "corpse_%d" % Time.get_ticks_msec(),
		"display_name": display_name,
		"position": SaveSlotFiles.vector3_to_array(corpse_position),
		"inventory": inventory_data,
		"weapons": weapon_data,
	}
	corpses.add_child(_make_corpse_pickup(corpse_data))


func _make_corpse_pickup(corpse_data: Dictionary) -> Area3D:
	var corpse := Area3D.new()
	corpse.set_script(CorpsePickupScript)
	corpse.call("restore_from_save", corpse_data)
	return corpse


func _spawn_player_zombie(zombie_position: Vector3, inventory_data: Dictionary, weapon_data: Dictionary) -> void:
	var zombies := get_node_or_null("Zombies")
	if not zombies:
		zombies = Node3D.new()
		zombies.name = "Zombies"
		add_child(zombies)
	var z := ZombieScene.instantiate()
	z.position = zombie_position
	z.set_meta("recoverable_inventory", inventory_data)
	z.set_meta("recoverable_weapons", weapon_data)
	if z.has_signal("died"):
		z.connect("died", Callable(self, "_on_recoverable_zombie_died"))
	zombies.add_child(z)


func _on_recoverable_zombie_died(zombie: Node) -> void:
	if not zombie.has_meta("recoverable_inventory"):
		return
	var inventory_data: Dictionary = zombie.get_meta("recoverable_inventory") as Dictionary
	var weapon_data: Dictionary = zombie.get_meta("recoverable_weapons") as Dictionary
	_spawn_corpse((zombie as Node3D).global_position, inventory_data, weapon_data, "Former you")
