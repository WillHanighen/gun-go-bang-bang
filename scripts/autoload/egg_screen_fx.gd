extends Node

const LSD_SHADER := preload("res://shaders/lsd_post_process.gdshader")

const _KONAMI_KEYS: Array[Key] = [
	KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A,
	KEY_ENTER,
]

const _IDLE_RESET_SEC := 3.5

var _layer: CanvasLayer
var _rect: ColorRect
var _material: ShaderMaterial
var _active: bool = false
var _step: int = 0
var _idle_secs: float = 0.0
var _effect_secs: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_material = ShaderMaterial.new()
	_material.shader = LSD_SHADER

	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.material = _material

	_layer = CanvasLayer.new()
	_layer.layer = 100
	_layer.visible = false
	_layer.add_child(_rect)
	add_child(_layer)


func _process(delta: float) -> void:
	if _active:
		_effect_secs += delta
		if _material:
			_material.set_shader_parameter(&"effect_time", _effect_secs)

	if _step > 0:
		_idle_secs += delta
		if _idle_secs >= _IDLE_RESET_SEC:
			_step = 0
			_idle_secs = 0.0


# -----------------------------------------------------------------------------
# Undocumented easter egg: do not surface in README, UI copy, changelogs, or other
# player-facing documentation. Wrong key resets progress; prolonged idle does too.
# -----------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_touch_sequence(event as InputEventKey)


func _touch_sequence(ev: InputEventKey) -> void:
	var k := ev.physical_keycode
	var expected: Key = _KONAMI_KEYS[_step]

	var matched := false
	if expected == KEY_ENTER:
		matched = k == KEY_ENTER or k == KEY_KP_ENTER
	else:
		matched = k == expected

	if matched:
		_idle_secs = 0.0
		_step += 1
		if _step >= _KONAMI_KEYS.size():
			_step = 0
			_toggle_ls_d()
	elif _step > 0:
		_step = 0
		_idle_secs = 0.0


func _toggle_ls_d() -> void:
	_active = not _active
	_layer.visible = _active
	if _active:
		_effect_secs = 0.0
		if _material:
			_material.set_shader_parameter(&"effect_time", 0.0)
