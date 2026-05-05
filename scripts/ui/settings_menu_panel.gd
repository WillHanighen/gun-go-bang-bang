extends VBoxContainer

signal back_requested

@onready var _master_slider: HSlider = %MasterVolumeSlider
@onready var _master_spin: SpinBox = %MasterVolumeSpin
@onready var _mouse_slider: HSlider = %MouseSensSlider
@onready var _mouse_spin: SpinBox = %MouseSensSpin
@onready var _invert_check: CheckBox = %InvertMouseCheck
@onready var _fov_slider: HSlider = %FovSlider
@onready var _fov_spin: SpinBox = %FovSpin
@onready var _fullscreen_check: CheckBox = %FullscreenCheck
@onready var _vsync_check: CheckBox = %VsyncCheck
@onready var _keybind_list: VBoxContainer = %KeybindList

var _listen_action: StringName = &""
var _listen_button: Button = null


func _bindings_save() -> InputBindingsPersistence:
	return get_tree().root.get_node_or_null("InputBindingsSave") as InputBindingsPersistence


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible:
		_cancel_listen()


func _input(event: InputEvent) -> void:
	if _listen_action.is_empty():
		return
	if event is InputEventKey:
		var ek := event as InputEventKey
		if ek.echo or not ek.pressed:
			return
		get_viewport().set_input_as_handled()
		if ek.physical_keycode == KEY_ESCAPE:
			_cancel_listen()
			return
		var dup_k := ek.duplicate() as InputEventKey
		InputSetup.replace_keyboard_binding(_listen_action, dup_k)
		var bs := _bindings_save()
		if bs:
			bs.save_bindings_from_input_map()
		_cancel_listen()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed:
			return
		get_viewport().set_input_as_handled()
		var dup_m := mb.duplicate() as InputEventMouseButton
		InputSetup.replace_mouse_binding(_listen_action, dup_m)
		var bs2 := _bindings_save()
		if bs2:
			bs2.save_bindings_from_input_map()
		_cancel_listen()


func _ready() -> void:
	GameSettings.settings_changed.connect(_sync_from_game_settings)
	_master_slider.value_changed.connect(_on_master_slider_changed)
	_master_spin.value_changed.connect(_on_master_spin_changed)
	_mouse_slider.value_changed.connect(_on_mouse_slider_changed)
	_mouse_spin.value_changed.connect(_on_mouse_spin_changed)
	_fov_slider.value_changed.connect(_on_fov_slider_changed)
	_fov_spin.value_changed.connect(_on_fov_spin_changed)
	_invert_check.toggled.connect(_on_invert_toggled)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_vsync_check.toggled.connect(_on_vsync_toggled)
	_build_keybind_rows()
	_sync_from_game_settings()


func _sync_from_game_settings() -> void:
	_block_general_signals(true)

	var master_iv := int(round(clampf(GameSettings.master_volume_linear * 100.0, _master_slider.min_value, _master_slider.max_value)))
	_master_slider.value = master_iv
	_master_spin.value = master_iv

	var mouse_iv := int(round(clampf(GameSettings.mouse_sensitivity_mult * 100.0, _mouse_slider.min_value, _mouse_slider.max_value)))
	_mouse_slider.value = mouse_iv
	_mouse_spin.value = mouse_iv

	var fov_iv := int(round(clampf(GameSettings.field_of_view, _fov_slider.min_value, _fov_slider.max_value)))
	_fov_slider.value = fov_iv
	_fov_spin.value = fov_iv

	_invert_check.button_pressed = GameSettings.invert_mouse_y
	_fullscreen_check.button_pressed = GameSettings.fullscreen
	_vsync_check.button_pressed = GameSettings.vsync_enabled

	_block_general_signals(false)


func _block_general_signals(block: bool) -> void:
	_master_slider.set_block_signals(block)
	_master_spin.set_block_signals(block)
	_mouse_slider.set_block_signals(block)
	_mouse_spin.set_block_signals(block)
	_fov_slider.set_block_signals(block)
	_fov_spin.set_block_signals(block)
	_invert_check.set_block_signals(block)
	_fullscreen_check.set_block_signals(block)
	_vsync_check.set_block_signals(block)


func _clamp_spin_to_slider(spin: SpinBox, slider: HSlider) -> int:
	return int(round(clampf(spin.value, slider.min_value, slider.max_value)))


func _on_master_slider_changed(value: float) -> void:
	var iv := int(round(clampf(value, _master_slider.min_value, _master_slider.max_value)))
	_master_spin.set_block_signals(true)
	_master_spin.value = iv
	_master_spin.set_block_signals(false)
	GameSettings.set_master_volume_linear(iv / 100.0)


func _on_master_spin_changed(_value: float) -> void:
	var iv := _clamp_spin_to_slider(_master_spin, _master_slider)
	_master_spin.set_block_signals(true)
	_master_spin.value = iv
	_master_spin.set_block_signals(false)
	_master_slider.set_block_signals(true)
	_master_slider.value = iv
	_master_slider.set_block_signals(false)
	GameSettings.set_master_volume_linear(iv / 100.0)


func _on_mouse_slider_changed(value: float) -> void:
	var iv := int(round(clampf(value, _mouse_slider.min_value, _mouse_slider.max_value)))
	_mouse_spin.set_block_signals(true)
	_mouse_spin.value = iv
	_mouse_spin.set_block_signals(false)
	GameSettings.set_mouse_sensitivity_mult(iv / 100.0)


func _on_mouse_spin_changed(_value: float) -> void:
	var iv := _clamp_spin_to_slider(_mouse_spin, _mouse_slider)
	_mouse_spin.set_block_signals(true)
	_mouse_spin.value = iv
	_mouse_spin.set_block_signals(false)
	_mouse_slider.set_block_signals(true)
	_mouse_slider.value = iv
	_mouse_slider.set_block_signals(false)
	GameSettings.set_mouse_sensitivity_mult(iv / 100.0)


func _on_fov_slider_changed(value: float) -> void:
	var iv := int(round(clampf(value, _fov_slider.min_value, _fov_slider.max_value)))
	_fov_spin.set_block_signals(true)
	_fov_spin.value = iv
	_fov_spin.set_block_signals(false)
	GameSettings.set_field_of_view(float(iv))


func _on_fov_spin_changed(_value: float) -> void:
	var iv := _clamp_spin_to_slider(_fov_spin, _fov_slider)
	_fov_spin.set_block_signals(true)
	_fov_spin.value = iv
	_fov_spin.set_block_signals(false)
	_fov_slider.set_block_signals(true)
	_fov_slider.value = iv
	_fov_slider.set_block_signals(false)
	GameSettings.set_field_of_view(float(iv))


func _on_invert_toggled(pressed: bool) -> void:
	GameSettings.set_invert_mouse_y(pressed)


func _on_fullscreen_toggled(pressed: bool) -> void:
	GameSettings.set_fullscreen(pressed)


func _on_vsync_toggled(pressed: bool) -> void:
	GameSettings.set_vsync_enabled(pressed)


func _on_settings_tab_selected(_tab: int) -> void:
	_cancel_listen()


func _on_reset_bindings_pressed() -> void:
	_cancel_listen()
	var bs := _bindings_save()
	if bs:
		bs.reset_to_defaults()
	_refresh_all_keybind_buttons()


func _on_back_pressed() -> void:
	_cancel_listen()
	back_requested.emit()


func _build_keybind_rows() -> void:
	for child in _keybind_list.get_children():
		child.queue_free()

	var bs := _bindings_save()
	for action in InputBindingsPersistence.REMAPPABLE_ORDER:
		var row := HBoxContainer.new()
		row.set_meta(&"action", action)
		row.add_theme_constant_override(&"separation", 8)

		var caption := Label.new()
		caption.text = bs.label_for_action(action) if bs else String(action)
		caption.custom_minimum_size.x = 188
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(caption)

		var bind_btn := Button.new()
		bind_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bind_btn.focus_mode = Control.FOCUS_ALL
		bind_btn.set_meta(&"action", action)
		bind_btn.pressed.connect(_on_keybind_bind_pressed.bind(action, bind_btn))
		row.add_child(bind_btn)

		_keybind_list.add_child(row)
		_refresh_one_binding_btn(bind_btn, action)


func _on_keybind_bind_pressed(action: StringName, btn: Button) -> void:
	if _listen_button == btn:
		_cancel_listen()
		return
	_cancel_listen()
	_listen_action = action
	_listen_button = btn
	btn.text = "… press key or mouse (Esc cancel)"


func _cancel_listen() -> void:
	if _listen_button != null and is_instance_valid(_listen_button):
		var act: StringName = _listen_button.get_meta(&"action", _listen_action)
		_refresh_one_binding_btn(_listen_button, act)
	_listen_action = &""
	_listen_button = null


func _refresh_all_keybind_buttons() -> void:
	for row in _keybind_list.get_children():
		if not row.has_meta(&"action"):
			continue
		var action_sn: StringName = row.get_meta(&"action") as StringName
		var btn := row.get_child(1) as Button
		if btn:
			_refresh_one_binding_btn(btn, action_sn)


func _refresh_one_binding_btn(btn: Button, action: StringName) -> void:
	var hint := _primary_binding_as_text(action)
	btn.text = hint if not hint.is_empty() else "Click to bind"


func _primary_binding_as_text(action: StringName) -> String:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return InputBindingsPersistence.format_event_hint(ev)
	for ev in InputMap.action_get_events(action):
		if ev is InputEventMouseButton:
			return InputBindingsPersistence.format_event_hint(ev)
	return ""
