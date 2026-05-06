extends RefCounted
## Versioned Survival slot storage. The arena is still a prototype, but saves should already
## look like the durable sandbox state they will grow into.

const SLOT_COUNT := 3
const SAVE_VERSION := 2
const SAVE_KIND := "survival_run"
const DEFAULT_PLAYER_ID := "local_player"
const ARENA_WORLD_KIND := "arena_shell"

const SECTION_KEYS := [
	"settings",
	"world",
	"player",
	"inventory",
	"weapons",
	"bases",
	"zombies",
	"time",
	"radio",
	"map",
	"progression",
	"ownership",
	"weather",
	"vehicles",
	"animals",
]

const DEFAULT_SPAWN_POSITION := Vector3(0, 1.0, 0)


static func path_for_slot(slot_index: int) -> String:
	assert(slot_index >= 0 and slot_index < SLOT_COUNT)
	return "user://survival_slot_%d.json" % (slot_index + 1)


static func has_save(slot_index: int) -> bool:
	return slot_has_save(slot_index)


static func slot_has_save(slot_index: int) -> bool:
	if not _is_valid_slot(slot_index):
		return false
	return FileAccess.file_exists(path_for_slot(slot_index))


static func read_slot(slot_index: int) -> Dictionary:
	if not _is_valid_slot(slot_index) or not slot_has_save(slot_index):
		return {}

	var file := FileAccess.open(path_for_slot(slot_index), FileAccess.READ)
	if file == null:
		push_warning("SurvivalSaveSlots: could not read %s" % path_for_slot(slot_index))
		return {}

	var raw_text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SurvivalSaveSlots: save %d is not valid JSON data" % (slot_index + 1))
		return {}

	return normalize_save_data(parsed as Dictionary, slot_index)


static func write_slot(slot_index: int, save_data: Dictionary) -> bool:
	if not _is_valid_slot(slot_index):
		return false

	var normalized := normalize_save_data(save_data, slot_index)
	normalized["updated_unix_time"] = _now_unix_time()

	var file := FileAccess.open(path_for_slot(slot_index), FileAccess.WRITE)
	if file == null:
		push_warning("SurvivalSaveSlots: could not write %s" % path_for_slot(slot_index))
		return false

	file.store_string(JSON.stringify(normalized, "\t"))
	file.close()
	return true


static func delete_slot(slot_index: int) -> bool:
	if not _is_valid_slot(slot_index) or not slot_has_save(slot_index):
		return false
	var err := DirAccess.remove_absolute(path_for_slot(slot_index))
	if err != OK:
		push_warning("SurvivalSaveSlots: could not delete %s" % path_for_slot(slot_index))
	return err == OK


static func create_new_game(slot_index: int, settings: Dictionary = {}) -> Dictionary:
	var save_data := build_default_save(slot_index, settings)
	write_slot(slot_index, save_data)
	return save_data


static func write_new_game_stub(slot_index: int) -> void:
	create_new_game(slot_index)


static func get_slot_summary(slot_index: int) -> Dictionary:
	if not _is_valid_slot(slot_index):
		return {
			"exists": false,
			"slot_index": slot_index,
			"label": "Invalid slot",
		}
	if not slot_has_save(slot_index):
		return {
			"exists": false,
			"slot_index": slot_index,
			"label": "Empty",
		}

	var save_data := read_slot(slot_index)
	if save_data.is_empty():
		return {
			"exists": true,
			"slot_index": slot_index,
			"label": "Unreadable save",
		}

	var time_data := save_data.get("time", {}) as Dictionary
	var elapsed := float(time_data.get("elapsed_seconds", 0.0))
	var world_data := save_data.get("world", {}) as Dictionary
	var world_seed := int(world_data.get("seed", 0))
	return {
		"exists": true,
		"slot_index": slot_index,
		"label": "Saved run - %.1f min - seed %d" % [elapsed / 60.0, world_seed],
		"version": int(save_data.get("v", SAVE_VERSION)),
		"elapsed_seconds": elapsed,
		"world_seed": world_seed,
		"updated_unix_time": int(save_data.get("updated_unix_time", 0)),
	}


static func normalize_save_data(raw_data: Dictionary, slot_index: int = -1) -> Dictionary:
	var source_version := int(raw_data.get("v", 0))
	var normalized := raw_data.duplicate(true)
	if source_version < SAVE_VERSION:
		normalized = _upgrade_legacy_save(raw_data, slot_index)

	normalized["v"] = SAVE_VERSION
	normalized["kind"] = SAVE_KIND
	if not normalized.has("created_unix_time"):
		normalized["created_unix_time"] = _now_unix_time()
	if not normalized.has("updated_unix_time"):
		normalized["updated_unix_time"] = int(normalized.get("created_unix_time", _now_unix_time()))

	var defaults := build_default_save(slot_index, {})
	for key in SECTION_KEYS:
		if not normalized.has(key) or typeof(normalized[key]) != TYPE_DICTIONARY:
			normalized[key] = (defaults[key] as Dictionary).duplicate(true)

	_merge_missing_keys(normalized["settings"] as Dictionary, defaults["settings"] as Dictionary)
	_merge_missing_keys(normalized["world"] as Dictionary, defaults["world"] as Dictionary)
	_merge_missing_keys(normalized["player"] as Dictionary, defaults["player"] as Dictionary)
	_merge_missing_keys(normalized["inventory"] as Dictionary, defaults["inventory"] as Dictionary)
	_merge_missing_keys(normalized["weapons"] as Dictionary, defaults["weapons"] as Dictionary)
	_merge_missing_keys(normalized["bases"] as Dictionary, defaults["bases"] as Dictionary)
	_merge_missing_keys(normalized["zombies"] as Dictionary, defaults["zombies"] as Dictionary)
	_merge_missing_keys(normalized["time"] as Dictionary, defaults["time"] as Dictionary)
	_merge_missing_keys(normalized["radio"] as Dictionary, defaults["radio"] as Dictionary)
	_merge_missing_keys(normalized["map"] as Dictionary, defaults["map"] as Dictionary)
	_merge_missing_keys(normalized["progression"] as Dictionary, defaults["progression"] as Dictionary)
	_merge_missing_keys(normalized["ownership"] as Dictionary, defaults["ownership"] as Dictionary)
	_merge_missing_keys(normalized["weather"] as Dictionary, defaults["weather"] as Dictionary)
	_merge_missing_keys(normalized["vehicles"] as Dictionary, defaults["vehicles"] as Dictionary)
	_merge_missing_keys(normalized["animals"] as Dictionary, defaults["animals"] as Dictionary)

	return normalized


static func build_default_save(slot_index: int = -1, settings: Dictionary = {}) -> Dictionary:
	var created_at := _now_unix_time()
	var world_seed := int(settings.get("world_seed", _generate_world_seed(slot_index)))
	var save_settings := _default_settings()
	for key in settings.keys():
		if key == "world_seed":
			continue
		save_settings[key] = settings[key]

	return {
		"v": SAVE_VERSION,
		"kind": SAVE_KIND,
		"created_unix_time": created_at,
		"updated_unix_time": created_at,
		"settings": save_settings,
		"world": {
			"seed": world_seed,
			"kind": ARENA_WORLD_KIND,
			"spawn_position": vector3_to_array(DEFAULT_SPAWN_POSITION),
			"generated_chunks": [],
		},
		"player": {
			"id": DEFAULT_PLAYER_ID,
			"position": vector3_to_array(DEFAULT_SPAWN_POSITION),
			"rotation_y": 0.0,
			"head_pitch": 0.0,
			"alive": true,
			"spawn_reason": "arena_boot",
		},
		"inventory": {
			"items": [],
			"containers": {},
			"active_slot": "primary",
		},
		"weapons": {
			"equipped": {},
			"items": {},
		},
		"bases": {
			"claims": [],
			"structures": [],
			"beds": [],
		},
		"zombies": {
			"arena_spawn_count": 12,
			"active": [],
			"director": {},
		},
		"time": {
			"elapsed_seconds": 0.0,
			"day": 1,
			"time_of_day": 8.0,
		},
		"radio": {
			"active_contracts": [],
			"heard_alerts": [],
		},
		"map": {
			"revealed_cells": [],
			"markers": [],
		},
		"progression": {
			"unlocked_recipes": {},
			"skills": {},
			"research_samples": {},
			"in_progress_crafts": [],
		},
		"ownership": {
			"players": {},
			"permissions": {},
		},
		"weather": {
			"weather": "clear",
			"time_of_day": 8.0,
		},
		"vehicles": {
			"active": [],
		},
		"animals": {
			"active": [],
		},
	}


static func vector3_to_array(value: Vector3) -> Array:
	return [value.x, value.y, value.z]


static func array_to_vector3(value, fallback: Vector3 = DEFAULT_SPAWN_POSITION) -> Vector3:
	if typeof(value) != TYPE_ARRAY:
		return fallback
	var parts := value as Array
	if parts.size() < 3:
		return fallback
	return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))


static func _is_valid_slot(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < SLOT_COUNT


static func _upgrade_legacy_save(raw_data: Dictionary, slot_index: int) -> Dictionary:
	var upgraded := build_default_save(slot_index, {})
	upgraded["metadata"] = {
		"upgraded_from_version": int(raw_data.get("v", 0)),
		"legacy_marker_only": raw_data.keys().size() <= 1,
	}
	return upgraded


static func _default_settings() -> Dictionary:
	return {
		"permadeath": false,
		"pvp_mode": "pve",
		"survival_strictness": "normal",
		"zombie_strength": "normal",
		"loot_abundance": "normal",
		"world_size": "arena",
	}


static func _merge_missing_keys(target: Dictionary, defaults: Dictionary) -> void:
	for key in defaults.keys():
		if target.has(key):
			continue
		var default_value = defaults[key]
		if typeof(default_value) == TYPE_DICTIONARY or typeof(default_value) == TYPE_ARRAY:
			target[key] = default_value.duplicate(true)
		else:
			target[key] = default_value


static func _generate_world_seed(slot_index: int) -> int:
	var basis := int(Time.get_unix_time_from_system()) & 0x7fffffff
	if slot_index >= 0:
		basis = int((basis + 1009 * (slot_index + 1)) & 0x7fffffff)
	if basis == 0:
		basis = 1
	return basis


static func _now_unix_time() -> int:
	return int(Time.get_unix_time_from_system())
