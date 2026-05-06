class_name OwnershipManager
extends Node

const GROUP := "survival_ownership_manager"
const LOCAL_PLAYER_ID := "local_player"

var players := {
	LOCAL_PLAYER_ID: {
		"display_name": "Local Pill",
		"kind": "host",
	}
}
var permissions := {}


func _ready() -> void:
	add_to_group(GROUP)


func authorize(object_id: String, player_id: String = LOCAL_PLAYER_ID, role: String = "owner") -> void:
	if not permissions.has(object_id):
		permissions[object_id] = {}
	var object_permissions := permissions[object_id] as Dictionary
	object_permissions[player_id] = role
	permissions[object_id] = object_permissions


func has_permission(object_id: String, player_id: String = LOCAL_PLAYER_ID) -> bool:
	if not permissions.has(object_id):
		return false
	return (permissions[object_id] as Dictionary).has(player_id)


func serialize_ownership(previous: Dictionary = {}) -> Dictionary:
	var data := previous.duplicate(true)
	data["players"] = players.duplicate(true)
	data["permissions"] = permissions.duplicate(true)
	return data


func restore_from_save(data: Dictionary) -> void:
	players = (data.get("players", players) as Dictionary).duplicate(true)
	permissions = (data.get("permissions", {}) as Dictionary).duplicate(true)

