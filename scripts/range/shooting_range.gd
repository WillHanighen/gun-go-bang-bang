extends Node3D

const PlayerScene := preload("res://scenes/player/player.tscn")
const HUDScript := preload("res://scripts/ui/hud.gd")
const RangeEnvironmentBuilderScript := preload("res://scripts/range/range_environment_builder.gd")
const RangeTargetBuilderScript := preload("res://scripts/range/range_target_builder.gd")

var player: CharacterBody3D


func _ready() -> void:
	RangeEnvironmentBuilderScript.build(self)
	RangeTargetBuilderScript.build(self)
	_spawn_player()
	_create_hud()


# -- player + equip ------------------------------------------------------------

func _spawn_player() -> void:
	player = PlayerScene.instantiate()
	player.position = Vector3(0, 1.0, 2.0)
	add_child(player)


func _create_hud() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "HUD"
	var hud_ctrl := Control.new()
	hud_ctrl.name = "HUDControl"
	hud_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_ctrl.set_script(HUDScript)
	hud_layer.add_child(hud_ctrl)
	add_child(hud_layer)
