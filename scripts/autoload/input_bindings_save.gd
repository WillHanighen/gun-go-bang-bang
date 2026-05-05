class_name InputBindingsPersistence
extends Node

const SAVE_PATH := "user://input_bindings.json"

const REMAPPABLE_ORDER: PackedStringArray = [
	&"move_forward",
	&"move_backward",
	&"move_left",
	&"move_right",
	&"jump",
	&"crouch",
	&"sprint",
	&"reload",
	&"switch_fire_mode",
	&"equip_slot_1",
	&"equip_slot_2",
	&"equip_slot_3",
	&"interact",
	&"toggleInventory",
	&"fire",
	&"aim",
]

const ACTION_LABELS: Dictionary = {
	"move_forward": "Move forward",
	"move_backward": "Move back",
	"move_left": "Strafe left",
	"move_right": "Strafe right",
	"jump": "Jump",
	"crouch": "Crouch",
	"sprint": "Sprint",
	"reload": "Reload / caliber wheel",
	"switch_fire_mode": "Fire mode",
	"equip_slot_1": "Equip slot 1 (primary)",
	"equip_slot_2": "Equip slot 2 (secondary)",
	"equip_slot_3": "Equip slot 3 (melee)",
	"interact": "Interact / pickup",
	"toggleInventory": "Inventory",
	"fire": "Fire",
	"aim": "Aim / alt fire",
}


func _ready() -> void:
	load_saved_bindings()


func label_for_action(action: StringName) -> String:
	var k := String(action)
	return String(ACTION_LABELS.get(k, k))


func load_saved_bindings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var txt := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	for action_sn in REMAPPABLE_ORDER:
		var action_str := String(action_sn)
		if not data.has(action_str):
			continue
		var entry: Variant = data[action_str]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		_apply_entry(action_sn, entry as Dictionary)


func reset_to_defaults() -> void:
	var da := DirAccess.open("user://")
	if da and da.file_exists("input_bindings.json"):
		da.remove("input_bindings.json")
	InputSetup.apply_defaults()


func save_bindings_from_input_map() -> void:
	var data := {}
	for action_sn in REMAPPABLE_ORDER:
		var ser := _serialize_action(action_sn)
		if ser.is_empty():
			continue
		data[String(action_sn)] = ser
	var json := JSON.stringify(data, "\t")
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(json)


func _serialize_action(action: StringName) -> Dictionary:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			var k := ev as InputEventKey
			return {"kind": "key", "physical_keycode": int(k.physical_keycode)}
	for ev in InputMap.action_get_events(action):
		if ev is InputEventMouseButton:
			var m := ev as InputEventMouseButton
			return {"kind": "mouse", "button_index": int(m.button_index)}
	return {}


func _apply_entry(action: StringName, entry: Dictionary) -> void:
	var kind: String = String(entry.get("kind", ""))
	match kind:
		"key":
			var code := int(entry.get("physical_keycode", 0))
			if code == 0:
				return
			var ev := InputEventKey.new()
			ev.physical_keycode = code as Key
			InputSetup.replace_keyboard_binding(action, ev)
		"mouse":
			var btn := int(entry.get("button_index", -1))
			if btn < 0:
				return
			var ev := InputEventMouseButton.new()
			ev.button_index = btn as MouseButton
			InputSetup.replace_mouse_binding(action, ev)


static func format_event_hint(ev: InputEvent) -> String:
	var t := ev.as_text()
	return t if not t.is_empty() else "?"
