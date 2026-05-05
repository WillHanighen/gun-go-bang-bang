extends Node

const KEY_DEFAULTS: Array[Dictionary] = [
	{&"action": &"move_forward", &"key": KEY_W},
	{&"action": &"move_backward", &"key": KEY_S},
	{&"action": &"move_left", &"key": KEY_A},
	{&"action": &"move_right", &"key": KEY_D},
	{&"action": &"jump", &"key": KEY_SPACE},
	{&"action": &"crouch", &"key": KEY_CTRL},
	{&"action": &"sprint", &"key": KEY_SHIFT},
	{&"action": &"reload", &"key": KEY_R},
	{&"action": &"switch_fire_mode", &"key": KEY_V},
	{&"action": &"equip_slot_1", &"key": KEY_1},
	{&"action": &"equip_slot_2", &"key": KEY_2},
	{&"action": &"equip_slot_3", &"key": KEY_3},
	{&"action": &"interact", &"key": KEY_F},
	{&"action": &"toggleInventory", &"key": KEY_TAB},
]

const MOUSE_DEFAULTS: Array[Dictionary] = [
	{&"action": &"fire", &"button": MOUSE_BUTTON_LEFT},
	{&"action": &"aim", &"button": MOUSE_BUTTON_RIGHT},
]


func _ready() -> void:
	apply_defaults()


func apply_defaults() -> void:
	for row in KEY_DEFAULTS:
		_replace_action_key(row[&"action"] as StringName, row[&"key"] as Key)
	for row in MOUSE_DEFAULTS:
		_replace_action_mouse(row[&"action"] as StringName, row[&"button"] as MouseButton)


func replace_keyboard_binding(action: StringName, key_ev: InputEventKey) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	clear_keyboard_events(action)
	var dup := key_ev.duplicate() as InputEventKey
	dup.pressed = false
	InputMap.action_add_event(action, dup)


func replace_mouse_binding(action: StringName, mouse_ev: InputEventMouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	clear_mouse_events(action)
	var dup := mouse_ev.duplicate() as InputEventMouseButton
	dup.pressed = false
	InputMap.action_add_event(action, dup)


func clear_keyboard_events(action: StringName) -> void:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			InputMap.action_erase_event(action, ev)


func clear_mouse_events(action: StringName) -> void:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventMouseButton:
			InputMap.action_erase_event(action, ev)


func _replace_action_key(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	clear_keyboard_events(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)


func _replace_action_mouse(action: StringName, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	clear_mouse_events(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
