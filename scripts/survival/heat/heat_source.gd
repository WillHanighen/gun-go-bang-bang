class_name HeatSource
extends Node

const GROUP := "survival_heat_source"

@export var source_id := ""
@export var heat_value := 1.0
@export var noise_value := 0.0
@export var light_value := 0.0
@export var enabled := true


func _ready() -> void:
	add_to_group(GROUP)
	if source_id.is_empty():
		var parent_name := "heat"
		if get_parent():
			parent_name = get_parent().name
		source_id = "%s_%d" % [parent_name, get_instance_id()]


func get_heat_position() -> Vector3:
	var parent_3d := get_parent() as Node3D
	return parent_3d.global_position if parent_3d else Vector3.ZERO


func get_heat_value() -> float:
	if not enabled:
		return 0.0
	return maxf(heat_value + noise_value + light_value, 0.0)


func to_save_data() -> Dictionary:
	return {
		"id": source_id,
		"heat": heat_value,
		"noise": noise_value,
		"light": light_value,
		"enabled": enabled,
	}

