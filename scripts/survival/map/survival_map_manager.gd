class_name SurvivalMapManager
extends Node

signal map_changed(snapshot: Dictionary)

const MAP_GROUP := "survival_map_manager"

var chunk_size := 48.0
var revealed_cells: Dictionary = {}
var markers: Array[Dictionary] = []
var current_cell := Vector2i.ZERO


func _ready() -> void:
	add_to_group(MAP_GROUP)


func setup_from_save(map_data: Dictionary, next_chunk_size: float) -> void:
	chunk_size = maxf(next_chunk_size, 1.0)
	revealed_cells.clear()
	for raw_cell in map_data.get("revealed_cells", []):
		var cell := _array_to_cell(raw_cell)
		revealed_cells[_cell_key(cell)] = cell
	markers.clear()
	for marker in map_data.get("markers", []):
		if typeof(marker) == TYPE_DICTIONARY:
			markers.append((marker as Dictionary).duplicate(true))
	map_changed.emit(get_snapshot())


func update_player_position(world_position: Vector3) -> void:
	current_cell = Vector2i(floori(world_position.x / chunk_size), floori(world_position.z / chunk_size))
	var changed := false
	for z in range(current_cell.y - 1, current_cell.y + 2):
		for x in range(current_cell.x - 1, current_cell.x + 2):
			var cell := Vector2i(x, z)
			var key := _cell_key(cell)
			if revealed_cells.has(key):
				continue
			revealed_cells[key] = cell
			changed = true
	if changed:
		map_changed.emit(get_snapshot())


func add_marker(marker_id: String, label: String, world_position: Vector3, marker_type: String = "marker") -> void:
	for marker in markers:
		if str(marker.get("id", "")) == marker_id:
			marker["label"] = label
			marker["position"] = [world_position.x, world_position.y, world_position.z]
			marker["type"] = marker_type
			map_changed.emit(get_snapshot())
			return
	markers.append({
		"id": marker_id,
		"label": label,
		"type": marker_type,
		"position": [world_position.x, world_position.y, world_position.z],
	})
	map_changed.emit(get_snapshot())


func serialize_map(previous: Dictionary = {}) -> Dictionary:
	var data := previous.duplicate(true)
	var cells: Array = []
	for cell in revealed_cells.values():
		cells.append([cell.x, cell.y])
	data["revealed_cells"] = cells
	data["markers"] = markers.duplicate(true)
	data["current_cell"] = [current_cell.x, current_cell.y]
	return data


func get_snapshot() -> Dictionary:
	return {
		"revealed_count": revealed_cells.size(),
		"current_cell": current_cell,
		"markers": markers.duplicate(true),
	}


func get_minimap_text() -> String:
	var nearby: Array[String] = []
	for marker in markers:
		var pos: Variant = marker.get("position", [])
		if typeof(pos) != TYPE_ARRAY or (pos as Array).size() < 3:
			continue
		var marker_cell := Vector2i(floori(float(pos[0]) / chunk_size), floori(float(pos[2]) / chunk_size))
		if abs(marker_cell.x - current_cell.x) <= 1 and abs(marker_cell.y - current_cell.y) <= 1:
			nearby.append(str(marker.get("label", "marker")))
	var near_text := "no marked weirdness nearby"
	if not nearby.is_empty():
		near_text = nearby[0]
		for i in range(1, nearby.size()):
			near_text += ", %s" % nearby[i]
	return "MAP %s | revealed %d | %s" % [_cell_key(current_cell), revealed_cells.size(), near_text]


func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


func _array_to_cell(value) -> Vector2i:
	if typeof(value) != TYPE_ARRAY:
		return Vector2i.ZERO
	var parts := value as Array
	if parts.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))

