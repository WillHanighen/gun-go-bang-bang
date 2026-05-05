extends Control

const SaveSlotFiles := preload("res://scripts/survival/survival_save_slots.gd")

const MAIN_MENU_PATH := "res://scenes/ui/main_menu.tscn"
const SURVIVAL_ARENA_PATH := "res://scenes/survival/zombie_arena.tscn"

const _META_MAIN_MENU_GAME_MODES := &"main_menu_show_game_modes"

@onready var _hub_page: Control = %HubPage
@onready var _settings_section: Control = %SettingsSection
@onready var _slot_list: ItemList = %SaveSlotList
@onready var _btn_load: Button = %BtnLoad
@onready var _btn_new_game: Button = %BtnNewGame
@onready var _overwrite_confirm: ConfirmationDialog = %OverwriteConfirm

var _pending_new_game_slot: int = -1


func _ready() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_settings_section.connect("back_requested", _on_settings_back)
	_slot_list.item_selected.connect(_on_slot_list_item_selected)
	_refresh_slot_list()
	_overwrite_confirm.confirmed.connect(_on_overwrite_confirmed)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _settings_section.visible:
		_show_hub()
		get_viewport().set_input_as_handled()
	elif _overwrite_confirm.visible:
		_overwrite_confirm.hide()
		_pending_new_game_slot = -1
		get_viewport().set_input_as_handled()
	else:
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func _show_hub() -> void:
	_hub_page.visible = true
	_settings_section.visible = false


func _on_slot_list_item_selected(_index: int) -> void:
	_update_slot_buttons()


func _refresh_slot_list() -> void:
	_slot_list.clear()
	for i in SaveSlotFiles.SLOT_COUNT:
		var line := "Slot %d — " % (i + 1)
		line += "Saved run" if SaveSlotFiles.slot_has_save(i) else "Empty"
		_slot_list.add_item(line)
	if _slot_list.item_count > 0:
		_slot_list.select(0)
	_update_slot_buttons()


func _selected_slot_index() -> int:
	var sel: PackedInt32Array = _slot_list.get_selected_items()
	if sel.is_empty():
		return -1
	return int(sel[0])


func _update_slot_buttons() -> void:
	var idx := _selected_slot_index()
	var occupied: bool = idx >= 0 and SaveSlotFiles.slot_has_save(idx)
	_btn_load.disabled = not occupied
	_btn_new_game.disabled = idx < 0


func _goto_arena(slot_index: int, write_new_stub: bool) -> void:
	var root := get_tree().root
	root.set_meta(&"survival_slot_index", slot_index)
	root.set_meta(&"survival_write_stub", write_new_stub)
	get_tree().change_scene_to_file(SURVIVAL_ARENA_PATH)


func _on_load_pressed() -> void:
	var idx := _selected_slot_index()
	if idx < 0 or not SaveSlotFiles.slot_has_save(idx):
		return
	_goto_arena(idx, false)


func _on_new_game_pressed() -> void:
	var idx := _selected_slot_index()
	if idx < 0:
		return
	if SaveSlotFiles.slot_has_save(idx):
		_pending_new_game_slot = idx
		_overwrite_confirm.popup_centered()
	else:
		_goto_arena(idx, true)


func _on_overwrite_confirmed() -> void:
	if _pending_new_game_slot < 0:
		return
	var idx := _pending_new_game_slot
	_pending_new_game_slot = -1
	_goto_arena(idx, true)


func _on_settings_pressed() -> void:
	_hub_page.visible = false
	_settings_section.visible = true


func _on_settings_back() -> void:
	_show_hub()
	_refresh_slot_list()


func _on_back_pressed() -> void:
	get_tree().root.set_meta(_META_MAIN_MENU_GAME_MODES, true)
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
