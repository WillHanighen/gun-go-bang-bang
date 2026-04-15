extends Node3D
## First-person view models under the camera. Child node names must match
## `WeaponResource.weapon_name` with spaces replaced by underscores (e.g. KRISS_Vector).
## Per-weapon scale / rotation / offset live on each child Node3D in `player.tscn` (imports vary).

var _wm: Node


func _ready() -> void:
	_wm = _resolve_weapon_manager()
	if _wm:
		_wm.weapon_changed.connect(_on_weapon_changed)
		if _wm.current_weapon_data:
			_on_weapon_changed(_wm.current_weapon_data)


func _on_weapon_changed(weapon: WeaponResource) -> void:
	if not weapon:
		return
	var key := weapon.weapon_name.replace(" ", "_")
	for c in get_children():
		c.visible = c.name == key


func _resolve_weapon_manager() -> Node:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return null
	return player.get_node_or_null("WeaponManager")
