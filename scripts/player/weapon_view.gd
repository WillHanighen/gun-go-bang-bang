extends Node3D
## First-person view models under the camera. Child node names must match
## `WeaponResource.weapon_name` with spaces replaced by underscores (e.g. KRISS_Vector).
## Per-weapon scale / rotation / offset live on each child Node3D in `player.tscn` (imports vary).

const HAND_1 := &"hand_1"
const HAND_2 := &"hand_2"

var _wm: Node
var _secondary_root: Node3D
var _secondary_instances: Dictionary = {}
var _template_nodes: Dictionary = {}


func _ready() -> void:
	_cache_templates()
	_wm = _resolve_weapon_manager()
	if _wm:
		_wm.loadout_changed.connect(_on_loadout_changed)
		_on_loadout_changed(_wm.get_loadout())

	
func _cache_templates() -> void:
	_secondary_root = Node3D.new()
	_secondary_root.name = "SecondaryHand"
	add_child(_secondary_root)
	for child in get_children():
		if child == _secondary_root:
			continue
		if not (child is Node3D):
			continue
		var node := child as Node3D
		_template_nodes[node.name] = node
		node.visible = false
		var duplicate_node := node.duplicate(Node.DUPLICATE_USE_INSTANTIATION) as Node3D
		if not duplicate_node:
			continue
		duplicate_node.visible = false
		duplicate_node.transform.origin.x = -node.transform.origin.x - 0.08
		_secondary_root.add_child(duplicate_node)
		_secondary_instances[node.name] = duplicate_node


func _on_loadout_changed(loadout: Dictionary) -> void:
	for node in _template_nodes.values():
		(node as Node3D).visible = false
	for node in _secondary_instances.values():
		(node as Node3D).visible = false
	var hand_1 := loadout.get(HAND_1, {}) as Dictionary
	var hand_2 := loadout.get(HAND_2, {}) as Dictionary
	_show_weapon_for_hand(hand_1, HAND_1)
	_show_weapon_for_hand(hand_2, HAND_2)


func _show_weapon_for_hand(hand_entry: Dictionary, hand: StringName) -> void:
	if hand_entry.is_empty():
		return
	var weapon := hand_entry.get("weapon") as WeaponResource
	if not weapon:
		return
	var key := weapon.weapon_name.replace(" ", "_")
	if hand == HAND_1 and _template_nodes.has(key):
		(_template_nodes[key] as Node3D).visible = true
	elif hand == HAND_2 and _secondary_instances.has(key):
		(_secondary_instances[key] as Node3D).visible = true


func _resolve_weapon_manager() -> Node:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return null
	return player.get_node_or_null("WeaponManager")
