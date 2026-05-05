extends Node

const LSD_SHADER := preload("res://shaders/lsd_post_process.gdshader")
const LSD_SHADER_CANVAS := preload("res://shaders/lsd_post_process_canvas.gdshader")

const _KONAMI_KEYS: Array[Key] = [
	KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A,
	KEY_ENTER,
]

const _IDLE_RESET_SEC := 3.5

var _layer: CanvasLayer
var _rect: ColorRect
var _mat_spatial: ShaderMaterial
var _mat_canvas: ShaderMaterial
var _post_quad: MeshInstance3D

var _active: bool = false
var _step: int = 0
var _idle_secs: float = 0.0
var _effect_secs: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_mat_spatial = ShaderMaterial.new()
	_mat_spatial.shader = LSD_SHADER
	_mat_spatial.render_priority = 127

	_mat_canvas = ShaderMaterial.new()
	_mat_canvas.shader = LSD_SHADER_CANVAS

	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.material = _mat_canvas

	_layer = CanvasLayer.new()
	_layer.layer = 100
	_layer.visible = false
	_layer.add_child(_rect)
	add_child(_layer)
	_sync_viewport_to_shaders()


func _process(delta: float) -> void:
	_sync_viewport_to_shaders()

	if _active:
		_effect_secs += delta
		_mat_spatial.set_shader_parameter(&"effect_time", _effect_secs)
		_mat_canvas.set_shader_parameter(&"effect_time", _effect_secs)
		_refresh_post_path()

	if _step > 0:
		_idle_secs += delta
		if _idle_secs >= _IDLE_RESET_SEC:
			_step = 0
			_idle_secs = 0.0


func _sync_viewport_to_shaders() -> void:
	var sz := get_viewport().get_visible_rect().size
	if sz.x < 1.0 or sz.y < 1.0:
		return
	_mat_spatial.set_shader_parameter(&"viewport_pixels", sz)
	_mat_canvas.set_shader_parameter(&"viewport_pixels", sz)


func _refresh_post_path() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		_layer.visible = false
		_ensure_post_quad(cam)
		_post_quad.visible = true
	else:
		if _post_quad != null:
			_post_quad.visible = false
		_layer.visible = true


func _ensure_post_quad(cam: Camera3D) -> void:
	if _post_quad == null:
		_post_quad = MeshInstance3D.new()
		var mq := QuadMesh.new()
		mq.size = Vector2(2, 2)
		mq.flip_faces = true
		_post_quad.mesh = mq
		_post_quad.material_override = _mat_spatial
		_post_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_post_quad.extra_cull_margin = 1.0e15
	if _post_quad.get_parent() != cam:
		if _post_quad.get_parent() != null:
			_post_quad.reparent(cam)
		else:
			cam.add_child(_post_quad)
	_post_quad.position = Vector3.ZERO


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
	if _active:
		_effect_secs = 0.0
		_mat_spatial.set_shader_parameter(&"effect_time", 0.0)
		_mat_canvas.set_shader_parameter(&"effect_time", 0.0)
		_refresh_post_path()
	else:
		_layer.visible = false
		if _post_quad != null:
			_post_quad.visible = false
