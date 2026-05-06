class_name RadioDirector
extends Node

signal alert_changed(message: String)

const GROUP := "survival_radio_director"

var latest_alert := ""
var heard_alerts: Array[String] = []
var active_contracts: Array[Dictionary] = []


func _ready() -> void:
	add_to_group(GROUP)


func push_alert(message: String) -> void:
	if message.is_empty() or message == latest_alert:
		return
	latest_alert = message
	heard_alerts.append(message)
	if heard_alerts.size() > 20:
		heard_alerts.pop_front()
	alert_changed.emit(latest_alert)


func generate_supply_contract(world_seed: int, near_position: Vector3) -> Dictionary:
	var contract := {
		"id": "radio_contract_%d_%d" % [world_seed, Time.get_ticks_msec()],
		"kind": "supply_drop",
		"label": "Random radio supply drop",
		"position": [near_position.x + 18.0, near_position.y, near_position.z - 12.0],
		"reward_hint": "scrap, food, maybe bullets if the box isn't lying",
		"active": true,
	}
	active_contracts.append(contract)
	push_alert("RADIO CONTRACT: supply drop pinged nearby. Box may contain snacks or betrayal.")
	return contract


func serialize_radio(previous: Dictionary = {}) -> Dictionary:
	var data := previous.duplicate(true)
	data["latest_alert"] = latest_alert
	data["heard_alerts"] = heard_alerts.duplicate()
	data["active_contracts"] = active_contracts.duplicate(true)
	return data


func restore_from_save(data: Dictionary) -> void:
	latest_alert = str(data.get("latest_alert", ""))
	heard_alerts.clear()
	for alert in data.get("heard_alerts", []):
		heard_alerts.append(str(alert))
	active_contracts.clear()
	for contract in data.get("active_contracts", []):
		if typeof(contract) == TYPE_DICTIONARY:
			active_contracts.append((contract as Dictionary).duplicate(true))
	if not latest_alert.is_empty():
		alert_changed.emit(latest_alert)

