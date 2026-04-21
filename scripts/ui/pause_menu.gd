extends Control

## When true, opening pause calls `SceneTree.pause`. Set false when multiplayer runs in the same
## tree so other players are not frozen; pause UI stays local-only in that case (not wired yet).
const SOLO_PLAYER_SESSION := true

## Public issue URL for "Report a Bug". Leave empty to show a friendly placeholder dialog.
const BUG_REPORT_URL := "https://github.com/WillHanighen/gun-go-bang-bang/issues"

const BUTTON_MIN_WIDTH := 280.0

var _main_panel: VBoxContainer
var _settings_panel: VBoxContainer
var _settings_visible := false
var _quit_dialog: ConfirmationDialog
var _bug_dialog: AcceptDialog
var _froze_scene_tree := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("pause_menu")
	_fit_root_to_viewport()
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	_build_ui()
	_build_dialogs()


func _on_viewport_size_changed() -> void:
	_fit_root_to_viewport()


## CanvasLayer parents are not Control; anchors alone often keep size at (0,0), so the menu sticks
## to the top-left. Match the visible viewport every time it changes.
func _fit_root_to_viewport() -> void:
	var r := get_viewport().get_visible_rect()
	set_position(r.position)
	set_size(r.size)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _settings_visible:
			_show_main_panel()
		else:
			request_resume()


func is_pause_open() -> bool:
	return visible


func request_pause() -> void:
	if visible:
		return
	_show_main_panel()
	visible = true
	_fit_root_to_viewport()
	_froze_scene_tree = SOLO_PLAYER_SESSION
	if _froze_scene_tree:
		get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func request_resume() -> void:
	if not visible:
		return
	_show_main_panel()
	visible = false
	if _froze_scene_tree:
		get_tree().paused = false
		_froze_scene_tree = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _show_main_panel() -> void:
	_settings_visible = false
	if _main_panel:
		_main_panel.visible = true
	if _settings_panel:
		_settings_panel.visible = false


func _show_settings() -> void:
	_settings_visible = true
	if _main_panel:
		_main_panel.visible = false
	if _settings_panel:
		_settings_panel.visible = true


func _on_report_bug() -> void:
	if not BUG_REPORT_URL.is_empty():
		OS.shell_open(BUG_REPORT_URL)
		return
	_bug_dialog.popup_centered()


func _on_quit_desktop_pressed() -> void:
	_quit_dialog.popup_centered()


func _quit_confirmed() -> void:
	get_tree().quit()


func _build_dialogs() -> void:
	_quit_dialog = ConfirmationDialog.new()
	_quit_dialog.title = "Leave the range?"
	_quit_dialog.dialog_text = "Quit to desktop? Unsaved… nothing. But still."
	_quit_dialog.ok_button_text = "Quit"
	_quit_dialog.confirmed.connect(_quit_confirmed)
	add_child(_quit_dialog)

	_bug_dialog = AcceptDialog.new()
	_bug_dialog.title = "Report a bug"
	_bug_dialog.dialog_text = (
		"No public bug tracker is linked in this build yet.\n\n"
		+ "If you are playing a local copy, ping whoever gave you the build. "
		+ "If you are hacking on source, set BUG_REPORT_URL in scripts/ui/pause_menu.gd."
	)
	add_child(_bug_dialog)


func _build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.55)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(center)

	var root_col := VBoxContainer.new()
	root_col.add_theme_constant_override("separation", 8)
	center.add_child(root_col)

	_main_panel = VBoxContainer.new()
	_main_panel.add_theme_constant_override("separation", 10)
	root_col.add_child(_main_panel)

	var title := Label.new()
	title.text = "PAUSED\n(sandbox's buffering, not you!)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	_main_panel.add_child(title)

	_main_panel.add_child(_make_button("Resume", request_resume))
	_main_panel.add_child(_make_button("Settings", _show_settings))
	_main_panel.add_child(_make_button("Report a Bug", _on_report_bug))

	_main_panel.add_child(HSeparator.new())

	var mm_block := VBoxContainer.new()
	mm_block.add_theme_constant_override("separation", 4)
	var mm_btn := Button.new()
	mm_btn.text = "Quit to Main Menu"
	mm_btn.disabled = true
	mm_btn.custom_minimum_size.x = BUTTON_MIN_WIDTH
	mm_block.add_child(mm_btn)
	var mm_note := Label.new()
	mm_note.text = "Main menu not implemented yet."
	mm_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mm_note.add_theme_font_size_override("font_size", 11)
	mm_note.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62))
	mm_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mm_note.custom_minimum_size = Vector2(BUTTON_MIN_WIDTH, 0)
	mm_block.add_child(mm_note)
	_main_panel.add_child(mm_block)

	_main_panel.add_child(_make_button("Quit to Desktop", _on_quit_desktop_pressed))

	_settings_panel = VBoxContainer.new()
	_settings_panel.visible = false
	_settings_panel.add_theme_constant_override("separation", 12)
	root_col.add_child(_settings_panel)

	var st_title := Label.new()
	st_title.text = "Settings"
	st_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st_title.add_theme_font_size_override("font_size", 20)
	_settings_panel.add_child(st_title)

	var st_body := Label.new()
	st_body.text = (
		"Volume, mouse sensitivity, reticle color drama, etc. not implemented yet.\n"
		+ "(or hey, do it yourself! It's FOSS after all!)"
	)
	st_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	st_body.custom_minimum_size = Vector2(380, 0)
	_settings_panel.add_child(st_body)

	_settings_panel.add_child(_make_button("Back", _show_main_panel))


func _make_button(text: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.x = BUTTON_MIN_WIDTH
	b.pressed.connect(on_pressed)
	return b
