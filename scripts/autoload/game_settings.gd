extends Node

## Persistent gameplay settings (`user://settings.cfg`). Autoload as `GameSettings`.

const SETTINGS_PATH := &"user://settings.cfg"

const SECTION_AUDIO := &"audio"
const SECTION_CONTROLS := &"controls"
const SECTION_VIDEO := &"video"

const MASTER_VOLUME_DEFAULT := 1.0
const MOUSE_SENS_MULT_DEFAULT := 1.0
const MOUSE_SENS_MULT_MIN := 0.25
const MOUSE_SENS_MULT_MAX := 2.5
const INVERT_MOUSE_Y_DEFAULT := false

const FOV_DEFAULT := 75.0
const FOV_MIN := 70.0
const FOV_MAX := 100.0
const FULLSCREEN_DEFAULT := false
const VSYNC_DEFAULT := true

## Linear gain 0..1 for Master bus.
var master_volume_linear: float = MASTER_VOLUME_DEFAULT
## Multiplier on baseline FPS mouse sensitivity (see player_controller).
var mouse_sensitivity_mult: float = MOUSE_SENS_MULT_DEFAULT
var invert_mouse_y: bool = INVERT_MOUSE_Y_DEFAULT

var field_of_view: float = FOV_DEFAULT
var fullscreen: bool = FULLSCREEN_DEFAULT
var vsync_enabled: bool = VSYNC_DEFAULT

signal settings_changed


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_from_disk()
	apply_all()


func apply_all() -> void:
	apply_audio()
	apply_video()
	settings_changed.emit()


func apply_audio() -> void:
	var bus_idx := AudioServer.get_bus_index(&"Master")
	if bus_idx < 0:
		return
	var v := clampf(master_volume_linear, 0.0, 1.0)
	master_volume_linear = v
	var mute := v <= 0.0001
	AudioServer.set_bus_mute(bus_idx, mute)
	if not mute:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(v))


func apply_video() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	)


func clamp_mouse_sensitivity_mult(v: float) -> float:
	return clampf(v, MOUSE_SENS_MULT_MIN, MOUSE_SENS_MULT_MAX)


func clamp_fov(v: float) -> float:
	return clampf(v, FOV_MIN, FOV_MAX)


func set_master_volume_linear(v: float) -> void:
	master_volume_linear = clampf(v, 0.0, 1.0)
	apply_audio()
	save_to_disk()
	settings_changed.emit()


func set_mouse_sensitivity_mult(v: float) -> void:
	mouse_sensitivity_mult = clamp_mouse_sensitivity_mult(v)
	save_to_disk()
	settings_changed.emit()


func set_invert_mouse_y(v: bool) -> void:
	invert_mouse_y = v
	save_to_disk()
	settings_changed.emit()


func set_field_of_view(v: float) -> void:
	field_of_view = clamp_fov(v)
	save_to_disk()
	settings_changed.emit()


func set_fullscreen(v: bool) -> void:
	fullscreen = v
	apply_video()
	save_to_disk()
	settings_changed.emit()


func set_vsync_enabled(v: bool) -> void:
	vsync_enabled = v
	apply_video()
	save_to_disk()
	settings_changed.emit()


func save_to_disk() -> void:
	var cf := ConfigFile.new()
	cf.set_value(SECTION_AUDIO, &"master_linear", master_volume_linear)
	cf.set_value(SECTION_CONTROLS, &"mouse_sensitivity_mult", mouse_sensitivity_mult)
	cf.set_value(SECTION_CONTROLS, &"invert_mouse_y", invert_mouse_y)
	cf.set_value(SECTION_VIDEO, &"fov", field_of_view)
	cf.set_value(SECTION_VIDEO, &"fullscreen", fullscreen)
	cf.set_value(SECTION_VIDEO, &"vsync", vsync_enabled)
	cf.save(SETTINGS_PATH)


func _load_from_disk() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) != OK:
		return
	master_volume_linear = clampf(
		float(cf.get_value(SECTION_AUDIO, &"master_linear", MASTER_VOLUME_DEFAULT)),
		0.0,
		1.0,
	)
	mouse_sensitivity_mult = clamp_mouse_sensitivity_mult(
		float(cf.get_value(SECTION_CONTROLS, &"mouse_sensitivity_mult", MOUSE_SENS_MULT_DEFAULT))
	)
	invert_mouse_y = bool(cf.get_value(SECTION_CONTROLS, &"invert_mouse_y", INVERT_MOUSE_Y_DEFAULT))
	field_of_view = clamp_fov(float(cf.get_value(SECTION_VIDEO, &"fov", FOV_DEFAULT)))
	fullscreen = bool(cf.get_value(SECTION_VIDEO, &"fullscreen", FULLSCREEN_DEFAULT))
	vsync_enabled = bool(cf.get_value(SECTION_VIDEO, &"vsync", VSYNC_DEFAULT))
