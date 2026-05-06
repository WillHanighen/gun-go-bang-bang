class_name SurvivalRunState
extends RefCounted

const SaveSlotFiles := preload("res://scripts/survival/survival_save_slots.gd")

var slot_index := -1
var settings: Dictionary = {}
var elapsed_time_seconds := 0.0
var world_seed := 0
var permadeath := false
var pvp_mode := "pve"
var dirty := false
var save_requested := false
var is_session_only := true
var loaded_from_existing_save := false
var last_save_error := ""
var last_save_unix_time := 0

var _save_data: Dictionary = {}
var _dirty_elapsed_marker := 0.0


func start_session_only() -> void:
	slot_index = -1
	is_session_only = true
	loaded_from_existing_save = false
	_save_data = SaveSlotFiles.build_default_save(-1, {})
	_apply_save_data(_save_data)
	dirty = false
	save_requested = false
	last_save_error = ""


func boot_from_slot(next_slot_index: int, create_new_game: bool) -> bool:
	slot_index = next_slot_index
	is_session_only = false
	loaded_from_existing_save = SaveSlotFiles.has_save(slot_index) and not create_new_game

	if create_new_game or not SaveSlotFiles.has_save(slot_index):
		_save_data = SaveSlotFiles.create_new_game(slot_index)
		loaded_from_existing_save = false
	else:
		_save_data = SaveSlotFiles.read_slot(slot_index)
		if _save_data.is_empty():
			last_save_error = "Could not read Survival slot %d; starting a fresh run." % (slot_index + 1)
			_save_data = SaveSlotFiles.create_new_game(slot_index)
			loaded_from_existing_save = false

	_save_data = SaveSlotFiles.normalize_save_data(_save_data, slot_index)
	_apply_save_data(_save_data)
	var metadata := _save_data.get("metadata", {}) as Dictionary
	dirty = metadata.has("upgraded_from_version")
	save_requested = false
	return true


func can_save() -> bool:
	return not is_session_only and slot_index >= 0 and slot_index < SaveSlotFiles.SLOT_COUNT


func advance_time(delta: float) -> void:
	if delta <= 0.0:
		return
	elapsed_time_seconds += delta
	if elapsed_time_seconds - _dirty_elapsed_marker >= 1.0:
		_dirty_elapsed_marker = elapsed_time_seconds
		mark_dirty()


func mark_dirty() -> void:
	dirty = true


func request_save() -> void:
	save_requested = true


func consume_save_request() -> bool:
	var requested := save_requested
	save_requested = false
	return requested


func get_save_data() -> Dictionary:
	return _save_data.duplicate(true)


func get_player_position() -> Vector3:
	var player_data := _save_data.get("player", {}) as Dictionary
	var world_data := _save_data.get("world", {}) as Dictionary
	var fallback := SaveSlotFiles.array_to_vector3(
		world_data.get("spawn_position", SaveSlotFiles.vector3_to_array(SaveSlotFiles.DEFAULT_SPAWN_POSITION))
	)
	return SaveSlotFiles.array_to_vector3(player_data.get("position", []), fallback)


func get_player_rotation_y() -> float:
	var player_data := _save_data.get("player", {}) as Dictionary
	return float(player_data.get("rotation_y", 0.0))


func get_player_head_pitch() -> float:
	var player_data := _save_data.get("player", {}) as Dictionary
	return float(player_data.get("head_pitch", 0.0))


func write_runtime_snapshot(runtime_sections: Dictionary) -> bool:
	if not can_save():
		last_save_error = "This Survival run is not attached to a save slot."
		save_requested = false
		return false

	_update_runtime_sections(runtime_sections)
	var ok := SaveSlotFiles.write_slot(slot_index, _save_data)
	save_requested = false
	if ok:
		_save_data = SaveSlotFiles.read_slot(slot_index)
		_apply_save_data(_save_data)
		dirty = false
		last_save_error = ""
		return true

	last_save_error = "Could not write Survival slot %d." % (slot_index + 1)
	return false


func _update_runtime_sections(runtime_sections: Dictionary) -> void:
	var next_data := _save_data.duplicate(true)
	for section in SaveSlotFiles.SECTION_KEYS:
		if not runtime_sections.has(section):
			continue
		var section_data = runtime_sections[section]
		if typeof(section_data) == TYPE_DICTIONARY or typeof(section_data) == TYPE_ARRAY:
			next_data[section] = section_data.duplicate(true)
		else:
			next_data[section] = section_data

	if runtime_sections.has("settings"):
		settings = (runtime_sections["settings"] as Dictionary).duplicate(true)
	next_data["settings"] = settings.duplicate(true)

	var time_data := next_data.get("time", {}) as Dictionary
	time_data["elapsed_seconds"] = elapsed_time_seconds
	next_data["time"] = time_data

	var world_data := next_data.get("world", {}) as Dictionary
	world_data["seed"] = world_seed
	next_data["world"] = world_data

	_save_data = SaveSlotFiles.normalize_save_data(next_data, slot_index)
	_apply_save_data(_save_data)
	mark_dirty()


func _apply_save_data(next_data: Dictionary) -> void:
	_save_data = SaveSlotFiles.normalize_save_data(next_data, slot_index)
	settings = (_save_data.get("settings", {}) as Dictionary).duplicate(true)
	var world_data := _save_data.get("world", {}) as Dictionary
	var time_data := _save_data.get("time", {}) as Dictionary
	world_seed = int(world_data.get("seed", 0))
	elapsed_time_seconds = float(time_data.get("elapsed_seconds", 0.0))
	permadeath = bool(settings.get("permadeath", false))
	pvp_mode = str(settings.get("pvp_mode", "pve"))
	last_save_unix_time = int(_save_data.get("updated_unix_time", 0))
	_dirty_elapsed_marker = elapsed_time_seconds
