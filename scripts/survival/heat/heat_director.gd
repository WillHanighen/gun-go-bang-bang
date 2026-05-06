class_name HeatDirector
extends Node

const GROUP := "survival_heat_director"

var total_heat := 0.0
var hottest_target: Node3D
var hottest_value := 0.0


func _ready() -> void:
	add_to_group(GROUP)


func _process(_delta: float) -> void:
	refresh_heat()


func refresh_heat() -> void:
	total_heat = 0.0
	hottest_target = null
	hottest_value = 0.0
	for source in get_tree().get_nodes_in_group("survival_heat_source"):
		if not source.has_method("get_heat_value"):
			continue
		var heat := float(source.call("get_heat_value"))
		total_heat += heat
		if heat <= hottest_value:
			continue
		hottest_value = heat
		var parent_3d := source.get_parent() as Node3D
		if parent_3d:
			hottest_target = parent_3d


func get_total_heat() -> float:
	return total_heat


func get_hottest_target() -> Node3D:
	return hottest_target


func serialize_heat(previous: Dictionary = {}) -> Dictionary:
	var data := previous.duplicate(true)
	data["total_heat"] = total_heat
	data["hottest_value"] = hottest_value
	return data

