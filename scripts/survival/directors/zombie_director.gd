class_name ZombieDirector
extends Node

var zombie_scene: PackedScene
var zombie_root: Node3D
var heat_director: Node
var radio_director: Node
var player: Node3D

var spawn_interval := 18.0
var heat_threshold := 6.0
var max_director_zombies := 18
var _spawn_timer := 0.0


func setup(
	next_zombie_scene: PackedScene,
	next_zombie_root: Node3D,
	next_heat_director: Node,
	next_radio_director: Node,
	next_player: Node3D
) -> void:
	zombie_scene = next_zombie_scene
	zombie_root = next_zombie_root
	heat_director = next_heat_director
	radio_director = next_radio_director
	player = next_player


func _process(delta: float) -> void:
	if not zombie_scene or not zombie_root or not heat_director:
		return
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	_spawn_timer = spawn_interval
	heat_director.call("refresh_heat")
	var heat: float = float(heat_director.call("get_total_heat"))
	if heat < heat_threshold:
		return
	if zombie_root.get_child_count() >= max_director_zombies:
		return
	if radio_director:
		radio_director.call("push_alert", "NWS ZOMBIE ALERT: bright/noisy base activity detected. Local shamblers are getting ideas.")
	_spawn_heat_horde(mini(3 + int(heat / 6.0), 8))


func _spawn_heat_horde(count: int) -> void:
	var target := heat_director.call("get_hottest_target") as Node3D
	var center: Vector3 = target.global_position if target else (player.global_position if player else Vector3.ZERO)
	for i in count:
		var z := zombie_scene.instantiate()
		var angle := randf() * TAU
		var radius := randf_range(22.0, 34.0)
		z.position = center + Vector3(cos(angle) * radius, 1.0, sin(angle) * radius)
		zombie_root.add_child(z)


func serialize_director(previous: Dictionary = {}) -> Dictionary:
	var data := previous.duplicate(true)
	data["spawn_interval"] = spawn_interval
	data["heat_threshold"] = heat_threshold
	data["active_director"] = true
	return data

