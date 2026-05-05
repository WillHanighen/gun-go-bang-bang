extends Control

const SHOOTING_RANGE_PATH := "res://scenes/range/shooting_range.tscn"
const SURVIVAL_MENU_PATH := "res://scenes/ui/main_menu_survival.tscn"

const _META_SHOW_GAME_MODES := &"main_menu_show_game_modes"

@onready var _main_page: Control = %MainPage
@onready var _play_page: Control = %PlayPage
@onready var _settings_section: Control = %SettingsSection


func _ready() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_settings_section.connect("back_requested", _on_settings_back)
	_apply_survival_return_route()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _settings_section.visible:
		_show_main()
		get_viewport().set_input_as_handled()
	elif _play_page.visible:
		_show_main()
		get_viewport().set_input_as_handled()


func _show_main() -> void:
	_main_page.visible = true
	_play_page.visible = false
	_settings_section.visible = false


func _show_game_modes() -> void:
	_main_page.visible = false
	_play_page.visible = true
	_settings_section.visible = false


func _apply_survival_return_route() -> void:
	var root := get_tree().root
	if not root.has_meta(_META_SHOW_GAME_MODES):
		return
	root.remove_meta(_META_SHOW_GAME_MODES)
	_show_game_modes()


func _on_play_pressed() -> void:
	_show_game_modes()


func _on_play_back_pressed() -> void:
	_show_main()


func _on_start_shooting_range_pressed() -> void:
	get_tree().change_scene_to_file(SHOOTING_RANGE_PATH)


func _on_survival_menu_pressed() -> void:
	get_tree().change_scene_to_file(SURVIVAL_MENU_PATH)


func _on_settings_pressed() -> void:
	_main_page.visible = false
	_settings_section.visible = true


func _on_settings_back() -> void:
	_show_main()


func _on_quit_pressed() -> void:
	get_tree().quit()
