extends Node3D
## Main menu 3D backdrop: show Mossberg on the menu rig. Camera transform comes from the scene.

const MOSSBERG_NODE := &"Mossberg_590"
const SECONDARY_ROOT := &"SecondaryHand"


func _ready() -> void:
	# Run after WeaponView finishes duplicating off-hand templates.
	call_deferred("_apply_showcase_preview")


func _apply_showcase_preview() -> void:
	_force_mossberg_visible_on_player()


func _force_mossberg_visible_on_player() -> void:
	var player_node := get_node_or_null("Player")
	if not player_node:
		return
	var wv := player_node.get_node_or_null("Head/Camera3D/WeaponView") as Node3D
	if not wv:
		return
	for child in wv.get_children():
		var id := StringName(child.name)
		if id == SECONDARY_ROOT:
			_set_node3d_visible_recursive(child, false)
			continue
		if child is Node3D:
			(child as Node3D).visible = (id == MOSSBERG_NODE)


func _set_node3d_visible_recursive(node: Node, vis: bool) -> void:
	if node is Node3D:
		(node as Node3D).visible = vis
	for c in node.get_children():
		_set_node3d_visible_recursive(c, vis)
