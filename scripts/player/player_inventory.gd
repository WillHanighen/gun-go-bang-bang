class_name PlayerInventory
extends Node

signal inventory_changed()
signal active_weapon_changed(weapon: WeaponResource)
signal active_loadout_changed(loadout: Dictionary)
signal inventory_open_changed(is_open: bool)

const SLOT_PRIMARY := &"primary"
const SLOT_SECONDARY := &"secondary"
const SLOT_MELEE := &"melee"
const SLOT_BACKPACK := &"backpack"

const SLOT_ORDER := [SLOT_PRIMARY, SLOT_SECONDARY, SLOT_MELEE]
const SLOT_LABELS := {
	SLOT_PRIMARY: "PRIMARY",
	SLOT_SECONDARY: "SECONDARY",
	SLOT_MELEE: "MELEE",
	SLOT_BACKPACK: "BACKPACK",
}
const SLOT_DESCRIPTIONS := {
	SLOT_PRIMARY: "Any weapon",
	SLOT_SECONDARY: "Medium or smaller",
	SLOT_MELEE: "Melee only",
	SLOT_BACKPACK: "General storage",
}
const SLOT_SIZES := {
	SLOT_PRIMARY: Vector2i(6, 3),
	SLOT_SECONDARY: Vector2i(4, 2),
	SLOT_MELEE: Vector2i(3, 1),
	SLOT_BACKPACK: Vector2i(12, 7),
}

var inventory_open := false
var active_slot: StringName = SLOT_PRIMARY

var _items: Dictionary = {}
var _next_item_id := 1


func set_inventory_open(is_open: bool) -> void:
	if inventory_open == is_open:
		return
	inventory_open = is_open
	inventory_open_changed.emit(inventory_open)


func get_items() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in _sorted_item_ids():
		var entry: Dictionary = (_items[id] as Dictionary).duplicate()
		out.append(entry)
	return out


func get_item(item_id: int) -> Dictionary:
	if not _items.has(item_id):
		return {}
	return (_items[item_id] as Dictionary).duplicate()


func get_container_size(container: StringName) -> Vector2i:
	return SLOT_SIZES.get(container, Vector2i.ZERO)


func get_slot_order() -> Array:
	return SLOT_ORDER.duplicate()


func get_slot_label(slot_name: StringName) -> String:
	return str(SLOT_LABELS.get(slot_name, String(slot_name).to_upper()))


func get_slot_description(slot_name: StringName) -> String:
	return str(SLOT_DESCRIPTIONS.get(slot_name, ""))


func get_active_slot() -> StringName:
	return active_slot


func get_active_weapon() -> WeaponResource:
	var loadout := get_active_loadout()
	var hand := loadout.get("hand_1", {}) as Dictionary
	if hand.is_empty():
		return null
	return hand.get("weapon") as WeaponResource


func get_weapon_in_slot(slot_name: StringName) -> WeaponResource:
	var loadout := get_loadout_for_slot(slot_name)
	var hand := loadout.get("hand_1", {}) as Dictionary
	if hand.is_empty():
		return null
	return hand.get("weapon") as WeaponResource


func get_active_loadout() -> Dictionary:
	return get_loadout_for_slot(active_slot)


func get_loadout_for_slot(slot_name: StringName) -> Dictionary:
	return _build_loadout(slot_name, get_items_in_container(slot_name))


func get_items_in_container(container: StringName) -> Array[Dictionary]:
	var entries := _get_container_entries(container)
	var out: Array[Dictionary] = []
	for entry in entries:
		out.append(entry.duplicate())
	return out


func is_equipment_slot(slot_name: StringName) -> bool:
	return slot_name != SLOT_BACKPACK


func has_room_for_weapon(weapon: WeaponResource) -> bool:
	if not weapon:
		return false
	return not _find_auto_placement(weapon).is_empty()


func add_weapon(weapon: WeaponResource, auto_activate: bool = true) -> int:
	if not weapon:
		return -1

	var placement := _find_auto_placement(weapon)
	if placement.is_empty():
		return -1

	var previous_weapon := get_active_weapon()
	var item_id := _next_item_id
	_next_item_id += 1
	_items[item_id] = {
		"id": item_id,
		"weapon": weapon,
		"container": placement.get("container", SLOT_BACKPACK),
		"position": placement.get("position", Vector2i.ZERO),
		"rotated": bool(placement.get("rotated", false)),
	}

	var preferred_slot := StringName(placement.get("container", SLOT_BACKPACK))
	_refresh_active_selection(
		previous_weapon,
		preferred_slot if auto_activate and is_equipment_slot(preferred_slot) else &""
	)
	inventory_changed.emit()
	return item_id


func move_item(
	item_id: int,
	target_container: StringName,
	target_position: Vector2i = Vector2i.ZERO,
	target_rotated: bool = false,
	use_target_rotation: bool = false
) -> bool:
	var entry := _get_entry(item_id)
	if entry.is_empty():
		return false

	var weapon := entry.get("weapon") as WeaponResource
	if not weapon:
		return false

	var previous_weapon := get_active_weapon()
	var rotated := target_rotated if use_target_rotation else bool(entry.get("rotated", false))
	if target_container != SLOT_BACKPACK:
		rotated = false

	var normalized_position := _normalize_position(target_container, target_position)
	if not _can_place_weapon(weapon, target_container, normalized_position, rotated, item_id):
		return false

	entry["container"] = target_container
	entry["position"] = normalized_position
	entry["rotated"] = rotated
	_items[item_id] = entry

	_refresh_active_selection(previous_weapon, target_container if is_equipment_slot(target_container) else &"")
	inventory_changed.emit()
	return true


func can_place_item(
	item_id: int,
	target_container: StringName,
	target_position: Vector2i = Vector2i.ZERO,
	target_rotated: bool = false,
	use_target_rotation: bool = false
) -> bool:
	var entry := _get_entry(item_id)
	if entry.is_empty():
		return false

	var weapon := entry.get("weapon") as WeaponResource
	if not weapon:
		return false

	var rotated := target_rotated if use_target_rotation else bool(entry.get("rotated", false))
	if target_container != SLOT_BACKPACK:
		rotated = false

	return _can_place_weapon(
		weapon,
		target_container,
		_normalize_position(target_container, target_position),
		rotated,
		item_id
	)


func can_swap_items(
	item_id: int,
	target_item_id: int,
	target_container: StringName,
	target_position: Vector2i = Vector2i.ZERO,
	target_rotated: bool = false,
	use_target_rotation: bool = false
) -> bool:
	return not _build_swap_plan(
		item_id,
		target_item_id,
		target_container,
		target_position,
		target_rotated,
		use_target_rotation
	).is_empty()


func swap_items(
	item_id: int,
	target_item_id: int,
	target_container: StringName,
	target_position: Vector2i = Vector2i.ZERO,
	target_rotated: bool = false,
	use_target_rotation: bool = false
) -> bool:
	var swap_plan := _build_swap_plan(
		item_id,
		target_item_id,
		target_container,
		target_position,
		target_rotated,
		use_target_rotation
	)
	if swap_plan.is_empty():
		return false

	var previous_weapon := get_active_weapon()
	var item_entry := swap_plan.get("item_entry", {}) as Dictionary
	var displaced_entry := swap_plan.get("displaced_entry", {}) as Dictionary

	item_entry["container"] = swap_plan.get("item_container", SLOT_BACKPACK)
	item_entry["position"] = swap_plan.get("item_position", Vector2i.ZERO)
	item_entry["rotated"] = bool(swap_plan.get("item_rotated", false))

	displaced_entry["container"] = swap_plan.get("displaced_container", SLOT_BACKPACK)
	displaced_entry["position"] = swap_plan.get("displaced_position", Vector2i.ZERO)
	displaced_entry["rotated"] = bool(swap_plan.get("displaced_rotated", false))

	_items[item_id] = item_entry
	_items[target_item_id] = displaced_entry

	_refresh_active_selection(previous_weapon, StringName(swap_plan.get("preferred_slot", &"")))
	inventory_changed.emit()
	return true


func quick_transfer_item(item_id: int) -> bool:
	var entry := _get_entry(item_id)
	if entry.is_empty():
		return false

	var weapon := entry.get("weapon") as WeaponResource
	if not weapon:
		return false

	var container := StringName(entry.get("container", SLOT_BACKPACK))
	if container == SLOT_BACKPACK:
		var equip_placement := _find_quick_equip_placement(weapon)
		if equip_placement.is_empty():
			return false
		return move_item(
			item_id,
			StringName(equip_placement.get("container", SLOT_BACKPACK)),
			equip_placement.get("position", Vector2i.ZERO),
			bool(equip_placement.get("rotated", false)),
			true
		)

	if not is_equipment_slot(container):
		return false

	var backpack_placement := _find_backpack_placement_for_weapon(
		weapon,
		Vector2i(-1, -1),
		bool(entry.get("rotated", false)),
		[item_id]
	)
	if backpack_placement.is_empty():
		return false

	return move_item(
		item_id,
		SLOT_BACKPACK,
		backpack_placement.get("position", Vector2i.ZERO),
		bool(backpack_placement.get("rotated", false)),
		true
	)


func set_active_slot(slot_name: StringName) -> void:
	if not is_equipment_slot(slot_name):
		return
	if not _has_items_in_container(slot_name):
		return
	if active_slot == slot_name:
		return

	var previous_weapon := get_active_weapon()
	active_slot = slot_name
	_emit_active_selection_changed(previous_weapon)
	inventory_changed.emit()


func cycle_active_slot(step: int) -> void:
	var occupied_slots: Array[StringName] = []
	for slot in SLOT_ORDER:
		if _has_items_in_container(slot):
			occupied_slots.append(slot)

	if occupied_slots.is_empty():
		if get_active_weapon() != null:
			var previous_weapon := get_active_weapon()
			active_slot = SLOT_PRIMARY
			_emit_active_selection_changed(previous_weapon)
			inventory_changed.emit()
		return

	var current_index := occupied_slots.find(active_slot)
	if current_index == -1:
		set_active_slot(occupied_slots[0])
		return

	var next_index := posmod(current_index + step, occupied_slots.size())
	set_active_slot(occupied_slots[next_index])


func _find_auto_placement(weapon: WeaponResource) -> Dictionary:
	var equipment_placement := _find_quick_equip_placement(weapon)
	if not equipment_placement.is_empty():
		return equipment_placement

	var backpack_placement := _find_backpack_placement_for_weapon(weapon)
	if not backpack_placement.is_empty():
		return backpack_placement

	return {}


func _find_quick_equip_placement(weapon: WeaponResource) -> Dictionary:
	for slot_name in [SLOT_MELEE, SLOT_SECONDARY, SLOT_PRIMARY]:
		if not weapon.fits_equipment_slot(slot_name):
			continue
		var slot_position := _find_first_fit_excluding(slot_name, weapon, false, [])
		if slot_position.x < 0:
			continue
		return {"container": slot_name, "position": slot_position, "rotated": false}

	return {}


func _refresh_active_selection(previous_weapon: WeaponResource = null, preferred_slot: StringName = &"") -> void:
	if preferred_slot != &"" and is_equipment_slot(preferred_slot) and _has_items_in_container(preferred_slot):
		active_slot = preferred_slot
	elif not _has_items_in_container(active_slot):
		var fallback_slot := _get_first_occupied_slot()
		active_slot = fallback_slot if fallback_slot != &"" else SLOT_PRIMARY

	_emit_active_selection_changed(previous_weapon)


func _emit_active_selection_changed(previous_weapon: WeaponResource = null) -> void:
	var current_weapon := get_active_weapon()
	if current_weapon != previous_weapon:
		active_weapon_changed.emit(current_weapon)
	active_loadout_changed.emit(get_active_loadout())


func _get_first_occupied_slot() -> StringName:
	for slot in SLOT_ORDER:
		if _has_items_in_container(slot):
			return slot
	return &""


func _find_backpack_placement_for_weapon(
	weapon: WeaponResource,
	preferred_position: Vector2i = Vector2i(-1, -1),
	preferred_rotated: bool = false,
	ignore_item_ids: Array = []
) -> Dictionary:
	if not weapon:
		return {}

	if preferred_position.x >= 0 and preferred_position.y >= 0:
		if _can_place_weapon_excluding(
			weapon,
			SLOT_BACKPACK,
			preferred_position,
			preferred_rotated,
			ignore_item_ids
		):
			return {
				"container": SLOT_BACKPACK,
				"position": preferred_position,
				"rotated": preferred_rotated,
			}

		var alternate_preferred_rotation := not preferred_rotated
		if _can_place_weapon_excluding(
			weapon,
			SLOT_BACKPACK,
			preferred_position,
			alternate_preferred_rotation,
			ignore_item_ids
		):
			return {
				"container": SLOT_BACKPACK,
				"position": preferred_position,
				"rotated": alternate_preferred_rotation,
			}

	var first_position := _find_first_fit_excluding(
		SLOT_BACKPACK,
		weapon,
		preferred_rotated,
		ignore_item_ids
	)
	if first_position.x >= 0:
		return {
			"container": SLOT_BACKPACK,
			"position": first_position,
			"rotated": preferred_rotated,
		}

	var alternate_rotation := not preferred_rotated
	var alternate_position := _find_first_fit_excluding(
		SLOT_BACKPACK,
		weapon,
		alternate_rotation,
		ignore_item_ids
	)
	if alternate_position.x >= 0:
		return {
			"container": SLOT_BACKPACK,
			"position": alternate_position,
			"rotated": alternate_rotation,
		}

	return {}


func _find_first_fit(container: StringName, weapon: WeaponResource, rotated: bool, ignore_item_id: int) -> Vector2i:
	return _find_first_fit_excluding(container, weapon, rotated, [ignore_item_id])


func _find_first_fit_excluding(
	container: StringName,
	weapon: WeaponResource,
	rotated: bool,
	ignore_item_ids: Array
) -> Vector2i:
	var container_size := get_container_size(container)
	var item_size := _get_weapon_size(weapon, rotated)
	for y in range(container_size.y - item_size.y + 1):
		for x in range(container_size.x - item_size.x + 1):
			var candidate := Vector2i(x, y)
			if _can_place_weapon_excluding(weapon, container, candidate, rotated, ignore_item_ids):
				return candidate
	return Vector2i(-1, -1)


func _can_place_weapon(
	weapon: WeaponResource,
	container: StringName,
	position: Vector2i,
	rotated: bool,
	ignore_item_id: int
) -> bool:
	return _can_place_weapon_excluding(weapon, container, position, rotated, [ignore_item_id])


func _can_place_weapon_excluding(
	weapon: WeaponResource,
	container: StringName,
	position: Vector2i,
	rotated: bool,
	ignore_item_ids: Array
) -> bool:
	var container_size := get_container_size(container)
	if container_size == Vector2i.ZERO:
		return false

	var normalized_position := _normalize_position(container, position)
	var item_size := _get_weapon_size(weapon, rotated)
	if normalized_position.x < 0 or normalized_position.y < 0:
		return false
	if normalized_position.x + item_size.x > container_size.x:
		return false
	if normalized_position.y + item_size.y > container_size.y:
		return false
	if is_equipment_slot(container):
		if not weapon.fits_equipment_slot(container):
			return false
		if rotated:
			return false

	var other_entries := _get_container_entries(container, ignore_item_ids)
	if is_equipment_slot(container):
		if other_entries.size() >= _get_equipment_item_limit(container):
			return false
		if not _can_share_equipment_container(weapon, other_entries):
			return false

	for other_entry in other_entries:
		var other_weapon := other_entry.get("weapon") as WeaponResource
		if not other_weapon:
			continue
		var other_position: Vector2i = other_entry.get("position", Vector2i.ZERO)
		var other_rotated := bool(other_entry.get("rotated", false))
		if _rects_overlap(normalized_position, item_size, other_position, _get_weapon_size(other_weapon, other_rotated)):
			return false
	return true


func _build_swap_plan(
	item_id: int,
	target_item_id: int,
	target_container: StringName,
	target_position: Vector2i,
	target_rotated: bool,
	use_target_rotation: bool
) -> Dictionary:
	if item_id == target_item_id:
		return {}

	var item_entry := _get_entry(item_id)
	var displaced_entry := _get_entry(target_item_id)
	if item_entry.is_empty() or displaced_entry.is_empty():
		return {}

	var item_weapon := item_entry.get("weapon") as WeaponResource
	var displaced_weapon := displaced_entry.get("weapon") as WeaponResource
	if not item_weapon or not displaced_weapon:
		return {}

	var item_origin_container := StringName(item_entry.get("container", SLOT_BACKPACK))
	var item_origin_position: Vector2i = item_entry.get("position", Vector2i.ZERO)
	var item_origin_rotated := bool(item_entry.get("rotated", false))
	var resolved_item_rotated := target_rotated if use_target_rotation else item_origin_rotated
	if target_container != SLOT_BACKPACK:
		resolved_item_rotated = false

	var ignore_item_ids := [item_id, target_item_id]
	var normalized_target_position := _normalize_position(target_container, target_position)
	if not _can_place_weapon_excluding(
		item_weapon,
		target_container,
		normalized_target_position,
		resolved_item_rotated,
		ignore_item_ids
	):
		return {}

	var displaced_destination := _find_swap_destination_for_item(
		displaced_weapon,
		item_origin_container,
		item_origin_position,
		item_origin_rotated,
		ignore_item_ids
	)
	if displaced_destination.is_empty():
		return {}

	return {
		"item_entry": item_entry,
		"displaced_entry": displaced_entry,
		"item_container": target_container,
		"item_position": normalized_target_position,
		"item_rotated": resolved_item_rotated,
		"displaced_container": StringName(displaced_destination.get("container", SLOT_BACKPACK)),
		"displaced_position": displaced_destination.get("position", Vector2i.ZERO),
		"displaced_rotated": bool(displaced_destination.get("rotated", false)),
		"preferred_slot": _get_preferred_slot_for_swap(
			target_container,
			StringName(displaced_destination.get("container", SLOT_BACKPACK))
		),
	}


func _find_swap_destination_for_item(
	weapon: WeaponResource,
	target_container: StringName,
	target_position: Vector2i,
	target_rotated: bool,
	ignore_item_ids: Array
) -> Dictionary:
	var resolved_rotated := target_rotated if target_container == SLOT_BACKPACK else false
	var normalized_target_position := _normalize_position(target_container, target_position)
	if not _can_place_weapon_excluding(
		weapon,
		target_container,
		normalized_target_position,
		resolved_rotated,
		ignore_item_ids
	):
		return {}

	return {
		"container": target_container,
		"position": normalized_target_position,
		"rotated": resolved_rotated,
	}


func _get_preferred_slot_for_swap(
	item_container: StringName,
	displaced_container: StringName
) -> StringName:
	if is_equipment_slot(item_container):
		return item_container
	if is_equipment_slot(displaced_container):
		return displaced_container
	return &""


func _normalize_position(_container: StringName, position: Vector2i) -> Vector2i:
	return position


func _rects_overlap(pos_a: Vector2i, size_a: Vector2i, pos_b: Vector2i, size_b: Vector2i) -> bool:
	return (
		pos_a.x < pos_b.x + size_b.x
		and pos_a.x + size_a.x > pos_b.x
		and pos_a.y < pos_b.y + size_b.y
		and pos_a.y + size_a.y > pos_b.y
	)


func get_item_size(item_id: int) -> Vector2i:
	var entry := _get_entry(item_id)
	if entry.is_empty():
		return Vector2i.ZERO
	var weapon := entry.get("weapon") as WeaponResource
	if not weapon:
		return Vector2i.ZERO
	return _get_weapon_size(weapon, bool(entry.get("rotated", false)))


func _get_weapon_size(weapon: WeaponResource, rotated: bool) -> Vector2i:
	var base_size := weapon.get_inventory_size()
	return Vector2i(base_size.y, base_size.x) if rotated else base_size


func _get_entry(item_id: int) -> Dictionary:
	if not _items.has(item_id):
		return {}
	return _items[item_id] as Dictionary


func _get_container_entries(container: StringName, ignore_item_ids: Array = []) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for item_id in _sorted_item_ids():
		if ignore_item_ids.has(item_id):
			continue
		var entry := _items[item_id] as Dictionary
		if entry.get("container", SLOT_BACKPACK) != container:
			continue
		entries.append(entry)
	entries.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var pos_a: Vector2i = a.get("position", Vector2i.ZERO)
			var pos_b: Vector2i = b.get("position", Vector2i.ZERO)
			if pos_a.y != pos_b.y:
				return pos_a.y < pos_b.y
			if pos_a.x != pos_b.x:
				return pos_a.x < pos_b.x
			return int(a.get("id", -1)) < int(b.get("id", -1))
	)
	return entries


func _sorted_item_ids() -> Array[int]:
	var ids: Array[int] = []
	for item_id in _items.keys():
		ids.append(int(item_id))
	ids.sort()
	return ids


func _has_items_in_container(container: StringName) -> bool:
	for entry in _items.values():
		if (entry as Dictionary).get("container", SLOT_BACKPACK) == container:
			return true
	return false


func _get_equipment_item_limit(container: StringName) -> int:
	if container == SLOT_MELEE:
		return 1
	return 2


func _can_share_equipment_container(weapon: WeaponResource, existing_entries: Array[Dictionary]) -> bool:
	if existing_entries.is_empty():
		return true
	if not weapon.is_one_handed():
		return false
	for entry in existing_entries:
		var other_weapon := entry.get("weapon") as WeaponResource
		if other_weapon and not other_weapon.is_one_handed():
			return false
	return true


func _build_loadout(slot_name: StringName, slot_entries: Array[Dictionary]) -> Dictionary:
	var loadout := {
		"slot": slot_name,
		"items": slot_entries,
		"hand_1": {},
		"hand_2": {},
		"two_handed": false,
		"supported": false,
	}
	if not is_equipment_slot(slot_name) or slot_entries.is_empty():
		return loadout

	var first_entry := slot_entries[0]
	var first_weapon := first_entry.get("weapon") as WeaponResource
	if not first_weapon:
		return loadout

	if first_weapon.requires_full_hands():
		loadout["hand_1"] = _make_hand_loadout_entry(first_entry, false, false)
		loadout["two_handed"] = true
		return loadout

	var hand_1 := _make_hand_loadout_entry(first_entry, false, slot_entries.size() == 1)
	loadout["hand_1"] = hand_1
	if slot_entries.size() == 1:
		loadout["supported"] = true
		return loadout

	loadout["hand_2"] = _make_hand_loadout_entry(slot_entries[1], true, false)
	return loadout


func _make_hand_loadout_entry(entry: Dictionary, is_offhand: bool, has_support_hand: bool) -> Dictionary:
	var weapon := entry.get("weapon") as WeaponResource
	return {
		"id": int(entry.get("id", -1)),
		"weapon": weapon,
		"container": StringName(entry.get("container", SLOT_BACKPACK)),
		"position": entry.get("position", Vector2i.ZERO),
		"rotated": bool(entry.get("rotated", false)),
		"is_offhand": is_offhand,
		"has_support_hand": has_support_hand,
	}
