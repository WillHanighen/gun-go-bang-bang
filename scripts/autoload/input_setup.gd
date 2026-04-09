extends Node


func _ready() -> void:
	_add_key("move_forward", KEY_W)
	_add_key("move_backward", KEY_S)
	_add_key("move_left", KEY_A)
	_add_key("move_right", KEY_D)
	_add_key("jump", KEY_SPACE)
	_add_key("crouch", KEY_CTRL)
	_add_key("sprint", KEY_SHIFT)
	_add_key("reload", KEY_R)
	_add_key("switch_fire_mode", KEY_V)
	_add_key("next_weapon", KEY_E)
	_add_key("prev_weapon", KEY_Q)
	_add_key("switch_ammo", KEY_X)
	_add_key("interact", KEY_F)
	_add_mouse("fire", MOUSE_BUTTON_LEFT)
	_add_mouse("aim", MOUSE_BUTTON_RIGHT)


func _add_key(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)

 
func _add_mouse(action: String, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
