extends Node3D
## First-person view models under the camera. Child node names must match
## `WeaponResource.weapon_name` with spaces replaced by underscores (e.g. KRISS_Vector).
## Per-weapon scale / rotation / offset live on each child Node3D in `player.tscn` (imports vary).

@onready var _wm: Node = $"../../../WeaponManager"


func _ready() -> void:
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
