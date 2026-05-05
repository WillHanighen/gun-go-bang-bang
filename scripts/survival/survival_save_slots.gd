extends RefCounted
## Lightweight slot markers for the survival menu. Real run state can layer on later.

const SLOT_COUNT := 3

static func path_for_slot(slot_index: int) -> String:
	assert(slot_index >= 0 and slot_index < SLOT_COUNT)
	return "user://survival_slot_%d.json" % (slot_index + 1)


static func slot_has_save(slot_index: int) -> bool:
	return FileAccess.file_exists(path_for_slot(slot_index))


static func write_new_game_stub(slot_index: int) -> void:
	var path := path_for_slot(slot_index)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("SurvivalSaveSlots: could not write %s" % path)
		return
	file.store_string(JSON.stringify({"v": 1}))
	file.close()
