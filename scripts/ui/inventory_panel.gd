class_name InventoryPanel
extends Control

const CELL_SIZE := 42.0
const CELL_GAP := 4.0
const PANEL_PADDING := 18.0
const FONT_SIZE_TITLE := 18
const FONT_SIZE_SUBTITLE := 11
const FONT_SIZE_ITEM := 13
const HEADER_HEIGHT := 56.0
const STACK_GAP := 22.0
const EQUIPMENT_TO_BACKPACK_GAP := 96.0
const EDGE_MARGIN := 32.0
const FOOTER_GAP := 52.0
const BASE_SCALE_MIN := 0.24

var inventory: PlayerInventory

var _drag_item_id := -1
var _drag_origin_container: StringName = &""
var _drag_origin_position := Vector2i.ZERO
var _drag_grab_cell := Vector2i.ZERO
var _drag_rotated := false
var _drag_start_mouse := Vector2.ZERO
var _mouse_pos := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func setup(player_inventory: PlayerInventory) -> void:
	inventory = player_inventory
	if not inventory:
		return
	inventory.inventory_changed.connect(queue_redraw)
	inventory.inventory_open_changed.connect(_on_inventory_open_changed)
	_on_inventory_open_changed(inventory.inventory_open)
	queue_redraw()


func _draw() -> void:
	if not visible or not inventory:
		return

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.04, 0.05, 0.88), true)

	var metrics := _get_metrics()
	var layouts := _build_layouts(metrics)
	for slot_name in inventory.get_slot_order():
		_draw_container(slot_name, layouts[slot_name] as Dictionary, metrics)
	_draw_container(PlayerInventory.SLOT_BACKPACK, layouts[PlayerInventory.SLOT_BACKPACK] as Dictionary, metrics)

	for entry in inventory.get_items():
		if int(entry.get("id", -1)) == _drag_item_id:
			continue
		_draw_item(entry, layouts, metrics, 1.0)

	if _drag_item_id != -1:
		var dragged_entry := inventory.get_item(_drag_item_id)
		if not dragged_entry.is_empty():
			_draw_drop_preview(dragged_entry, layouts, metrics)
			_draw_dragged_item(dragged_entry, metrics)

	var font := get_theme_default_font()
	var footer_font_size := maxi(int(round(FONT_SIZE_SUBTITLE * metrics.get("scale", 1.0))), 10)
	draw_string(
		font,
		Vector2(EDGE_MARGIN, size.y - EDGE_MARGIN),
		"Tab: close inventory   Shift-click: quick move   Drag items between slots and backpack   R: rotate dragged item   1/2/3: select slots   Q/E: cycle equipped weapons",
		HORIZONTAL_ALIGNMENT_LEFT,
		size.x - EDGE_MARGIN * 2.0,
		footer_font_size,
		Color(0.72, 0.76, 0.82, 0.9)
	)


func _gui_input(event: InputEvent) -> void:
	if not visible or not inventory:
		return

	if event is InputEventMouseMotion:
		_mouse_pos = event.position
		queue_redraw()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_pos = event.position
		if event.pressed:
			var hit := _find_item_at(event.position)
			if hit.is_empty():
				return
			if event.shift_pressed:
				inventory.quick_transfer_item(int(hit.get("id", -1)))
				accept_event()
				return
			_drag_item_id = int(hit.get("id", -1))
			_drag_origin_container = StringName(hit.get("container", &""))
			_drag_origin_position = hit.get("position", Vector2i.ZERO)
			var hit_rect: Rect2 = hit.get("rect", Rect2())
			var grabbed_entry := inventory.get_item(_drag_item_id)
			var grabbed_weapon := grabbed_entry.get("weapon") as WeaponResource
			var metrics := _get_metrics()
			_drag_rotated = bool(grabbed_entry.get("rotated", false))
			_drag_grab_cell = _get_grab_cell(event.position, hit_rect, grabbed_weapon, _drag_rotated, metrics)
			_drag_start_mouse = event.position
			queue_redraw()
			accept_event()
			return

		if _drag_item_id == -1:
			return

		var moved: bool = event.position.distance_to(_drag_start_mouse) > 5.0
		if moved:
			var metrics := _get_metrics()
			var target := _find_drop_target(event.position, _drag_item_id, metrics)
			if not target.is_empty():
				var target_container := StringName(target.get("container", PlayerInventory.SLOT_BACKPACK))
				var target_position: Vector2i = target.get("position", Vector2i.ZERO)
				var drop_rotated := _drag_rotated if target_container == PlayerInventory.SLOT_BACKPACK else false
				var swap_item_id := int(target.get("swap_item_id", -1))
				if swap_item_id != -1:
					inventory.swap_items(
						_drag_item_id,
						swap_item_id,
						target_container,
						target_position,
						drop_rotated,
						true
					)
				else:
					inventory.move_item(_drag_item_id, target_container, target_position, drop_rotated, true)
		elif inventory.is_equipment_slot(_drag_origin_container):
			inventory.set_active_slot(_drag_origin_container)

		_clear_drag()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _drag_item_id == -1:
		return
	if not event.is_action_pressed("reload"):
		return
	if event is InputEventKey and event.is_echo():
		return

	_toggle_drag_rotation()
	accept_event()


func _draw_container(slot_name: StringName, layout: Dictionary, metrics: Dictionary) -> void:
	var title_rect: Rect2 = layout.get("title_rect", Rect2())
	var subtitle_rect: Rect2 = layout.get("subtitle_rect", Rect2())
	var frame_rect: Rect2 = layout.get("frame_rect", Rect2())
	var grid_origin: Vector2 = layout.get("grid_origin", Vector2.ZERO)
	var grid_size: Vector2i = layout.get("grid_size", Vector2i.ZERO)

	var font := get_theme_default_font()
	var is_active := inventory.get_active_slot() == slot_name
	var title_color := Color(0.98, 0.9, 0.58) if is_active else Color(0.9, 0.92, 0.95)
	var frame_color := Color(0.86, 0.76, 0.42, 0.95) if is_active else Color(0.35, 0.39, 0.46, 0.95)
	var cell_step := _get_cell_step(metrics)
	var cell_size: float = metrics.get("cell_size", CELL_SIZE)
	var title_font_size := maxi(int(round(FONT_SIZE_TITLE * metrics.get("scale", 1.0))), 11)
	var subtitle_font_size := maxi(int(round(FONT_SIZE_SUBTITLE * metrics.get("scale", 1.0))), 9)
	draw_rect(frame_rect, Color(0.08, 0.1, 0.12, 0.95), true)
	draw_rect(frame_rect, frame_color, false, 2.0)

	_draw_wrapped_text(
		font,
		inventory.get_slot_label(slot_name),
		title_rect,
		title_font_size,
		title_color,
		1
	)
	_draw_wrapped_text(
		font,
		inventory.get_slot_description(slot_name),
		subtitle_rect,
		subtitle_font_size,
		Color(0.62, 0.68, 0.76, 0.95),
		2
	)

	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell_rect := Rect2(
				grid_origin + Vector2(x, y) * cell_step,
				Vector2(cell_size, cell_size)
			)
			draw_rect(cell_rect, Color(0.13, 0.15, 0.18, 0.98), true)
			draw_rect(cell_rect, Color(0.22, 0.25, 0.3, 0.9), false, 1.0)


func _draw_item(entry: Dictionary, layouts: Dictionary, metrics: Dictionary, alpha: float, force_rotated: bool = false, use_force_rotation: bool = false) -> void:
	var container := StringName(entry.get("container", PlayerInventory.SLOT_BACKPACK))
	if not layouts.has(container):
		return
	var weapon := entry.get("weapon") as WeaponResource
	if not weapon:
		return

	var rotated := force_rotated if use_force_rotation else bool(entry.get("rotated", false))
	var item_rect := _get_item_rect(entry, layouts[container] as Dictionary, metrics, rotated, use_force_rotation)
	var fill_color := _get_item_color(weapon)
	fill_color.a *= alpha
	draw_rect(item_rect, fill_color, true)
	draw_rect(item_rect, Color(0.06, 0.06, 0.06, alpha), false, 2.0)

	var font := get_theme_default_font()
	var item_font_size := maxi(int(round(FONT_SIZE_ITEM * metrics.get("scale", 1.0))), 10)
	var name_rect := Rect2(
		item_rect.position + Vector2(7, 6) * float(metrics.get("scale", 1.0)),
		Vector2(
			item_rect.size.x - 14.0 * float(metrics.get("scale", 1.0)),
			maxf(item_rect.size.y - 22.0 * float(metrics.get("scale", 1.0)), 14.0)
		)
	)
	_draw_wrapped_text(
		font,
		weapon.weapon_name,
		name_rect,
		item_font_size,
		Color(0.96, 0.96, 0.96, alpha),
		2
	)
	var item_size := _get_entry_size(entry, rotated, use_force_rotation)
	var footprint := "%dx%d" % [item_size.x, item_size.y]
	var footprint_font_size := maxi(int(round(11.0 * float(metrics.get("scale", 1.0)))), 9)
	draw_string(font, item_rect.position + Vector2(7, item_rect.size.y - 8.0 * float(metrics.get("scale", 1.0))), footprint,
		HORIZONTAL_ALIGNMENT_LEFT, item_rect.size.x - 10, footprint_font_size, Color(0.12, 0.14, 0.16, 0.95 * alpha))


func _draw_dragged_item(entry: Dictionary, metrics: Dictionary) -> void:
	var weapon := entry.get("weapon") as WeaponResource
	if not weapon:
		return

	var cell_stride := _get_cell_step(metrics)
	var drag_rect := Rect2(
		_mouse_pos - Vector2(_drag_grab_cell.x, _drag_grab_cell.y) * cell_stride,
		_get_item_pixel_size(_get_entry_size(entry, _drag_rotated, true), metrics)
	)
	var layouts := {
		PlayerInventory.SLOT_BACKPACK: {
			"grid_origin": drag_rect.position,
		}
	}
	_draw_item({
		"id": entry.get("id", -1),
		"weapon": weapon,
		"container": PlayerInventory.SLOT_BACKPACK,
		"position": Vector2i.ZERO,
		"rotated": _drag_rotated,
	}, layouts, metrics, 0.9, _drag_rotated, true)


func _draw_drop_preview(entry: Dictionary, layouts: Dictionary, metrics: Dictionary) -> void:
	var target := _find_drop_target(_mouse_pos, int(entry.get("id", -1)), metrics)
	if target.is_empty():
		return

	var weapon := entry.get("weapon") as WeaponResource
	var container := StringName(target.get("container", PlayerInventory.SLOT_BACKPACK))
	var target_position: Vector2i = target.get("position", Vector2i.ZERO)
	var layout := layouts.get(container, {}) as Dictionary
	var preview_origin: Vector2 = layout.get("grid_origin", Vector2.ZERO)
	var preview_size := _get_entry_size(entry, _drag_rotated, true) if container == PlayerInventory.SLOT_BACKPACK else weapon.get_inventory_size()
	var preview_rect := Rect2(
		preview_origin + Vector2(target_position.x, target_position.y) * _get_cell_step(metrics),
		_get_item_pixel_size(preview_size, metrics)
	)
	draw_rect(preview_rect, Color(0.34, 0.78, 0.48, 0.28), true)
	draw_rect(preview_rect, Color(0.55, 0.95, 0.62, 0.7), false, 2.0)


func _find_item_at(point: Vector2) -> Dictionary:
	if not inventory:
		return {}

	var metrics := _get_metrics()
	var layouts := _build_layouts(metrics)
	var items := inventory.get_items()
	items.reverse()
	for entry in items:
		var container := StringName(entry.get("container", PlayerInventory.SLOT_BACKPACK))
		if not layouts.has(container):
			continue
		var rect := _get_item_rect(entry, layouts[container] as Dictionary, metrics)
		if rect.has_point(point):
			return {
				"id": entry.get("id", -1),
				"container": container,
				"position": entry.get("position", Vector2i.ZERO),
				"rect": rect,
			}
	return {}


func _find_drop_target(point: Vector2, item_id: int, metrics: Dictionary) -> Dictionary:
	var entry := inventory.get_item(item_id)
	if entry.is_empty():
		return {}
	var weapon := entry.get("weapon") as WeaponResource
	if not weapon:
		return {}

	var hovered_item := _find_item_at(point)
	var hovered_item_id := int(hovered_item.get("id", -1))
	var hovered_container := StringName(hovered_item.get("container", &""))
	var layouts := _build_layouts(metrics)
	for slot_name in inventory.get_slot_order():
		var layout := layouts[slot_name] as Dictionary
		var frame_rect: Rect2 = layout.get("frame_rect", Rect2())
		if frame_rect.has_point(point) and weapon.fits_equipment_slot(slot_name):
			if inventory.can_place_item(item_id, slot_name, Vector2i.ZERO, false, true):
				return {"container": slot_name, "position": Vector2i.ZERO}
			if (
				hovered_item_id != -1
				and hovered_item_id != item_id
				and hovered_container == slot_name
				and inventory.can_swap_items(item_id, hovered_item_id, slot_name, Vector2i.ZERO, false, true)
			):
				return {"container": slot_name, "position": Vector2i.ZERO, "swap_item_id": hovered_item_id}
			return {}

	var backpack_layout := layouts[PlayerInventory.SLOT_BACKPACK] as Dictionary
	var backpack_frame: Rect2 = backpack_layout.get("frame_rect", Rect2())
	if backpack_frame.has_point(point):
		var backpack_origin: Vector2 = backpack_layout.get("grid_origin", Vector2.ZERO)
		var local := point - backpack_origin
		var cell_stride := float(metrics.get("cell_size", CELL_SIZE) + metrics.get("cell_gap", CELL_GAP))
		var hover_cell := Vector2i(floori(local.x / cell_stride), floori(local.y / cell_stride))
		var grid_position := hover_cell - _drag_grab_cell
		if inventory.can_place_item(item_id, PlayerInventory.SLOT_BACKPACK, grid_position, _drag_rotated, true):
			return {"container": PlayerInventory.SLOT_BACKPACK, "position": grid_position}
		if (
			hovered_item_id != -1
			and hovered_item_id != item_id
			and hovered_container == PlayerInventory.SLOT_BACKPACK
			and inventory.can_swap_items(
				item_id,
				hovered_item_id,
				PlayerInventory.SLOT_BACKPACK,
				grid_position,
				_drag_rotated,
				true
			)
		):
			return {
				"container": PlayerInventory.SLOT_BACKPACK,
				"position": grid_position,
				"swap_item_id": hovered_item_id,
			}
	return {}


func _get_item_rect(
	entry: Dictionary,
	layout: Dictionary,
	metrics: Dictionary,
	force_rotated: bool = false,
	use_force_rotation: bool = false
) -> Rect2:
	var item_position: Vector2i = entry.get("position", Vector2i.ZERO)
	var origin: Vector2 = layout.get("grid_origin", Vector2.ZERO)
	var item_size := _get_entry_size(entry, force_rotated, use_force_rotation)
	return Rect2(
		origin + Vector2(item_position.x, item_position.y) * _get_cell_step(metrics),
		_get_item_pixel_size(item_size, metrics)
	)


func _get_item_pixel_size(item_size: Vector2i, metrics: Dictionary) -> Vector2:
	var cell_size: float = metrics.get("cell_size", CELL_SIZE)
	var cell_gap: float = metrics.get("cell_gap", CELL_GAP)
	return Vector2(
		item_size.x * cell_size + maxf(float(item_size.x - 1), 0.0) * cell_gap,
		item_size.y * cell_size + maxf(float(item_size.y - 1), 0.0) * cell_gap
	)


func _get_grab_cell(mouse_position: Vector2, item_rect: Rect2, weapon: WeaponResource, rotated: bool, metrics: Dictionary) -> Vector2i:
	if not weapon:
		return Vector2i.ZERO

	var local := mouse_position - item_rect.position
	var cell_stride := float(metrics.get("cell_size", CELL_SIZE) + metrics.get("cell_gap", CELL_GAP))
	var item_grid_size := weapon.get_inventory_size()
	if rotated:
		item_grid_size = Vector2i(item_grid_size.y, item_grid_size.x)
	return Vector2i(
		clampi(floori(local.x / cell_stride), 0, item_grid_size.x - 1),
		clampi(floori(local.y / cell_stride), 0, item_grid_size.y - 1)
	)


func _build_layouts(metrics: Dictionary) -> Dictionary:
	var primary_size := inventory.get_container_size(PlayerInventory.SLOT_PRIMARY)
	var secondary_size := inventory.get_container_size(PlayerInventory.SLOT_SECONDARY)
	var melee_size := inventory.get_container_size(PlayerInventory.SLOT_MELEE)
	var backpack_size := inventory.get_container_size(PlayerInventory.SLOT_BACKPACK)

	var primary_frame_size := _get_frame_size(primary_size, metrics)
	var secondary_frame_size := _get_frame_size(secondary_size, metrics)
	var melee_frame_size := _get_frame_size(melee_size, metrics)
	var backpack_frame_size := _get_frame_size(backpack_size, metrics)
	var equipment_width := maxf(primary_frame_size.x, maxf(secondary_frame_size.x, melee_frame_size.x))
	var equipment_height := (
		primary_frame_size.y
		+ float(metrics.get("stack_gap", STACK_GAP))
		+ secondary_frame_size.y
		+ float(metrics.get("stack_gap", STACK_GAP))
		+ melee_frame_size.y
	)
	var backpack_width := _get_item_pixel_size(backpack_size, metrics).x
	var total_width := equipment_width + float(metrics.get("equipment_gap", EQUIPMENT_TO_BACKPACK_GAP)) + backpack_width
	var start_x := (size.x - total_width) * 0.5
	var total_height := maxf(equipment_height, backpack_frame_size.y)
	var top_y := maxf((size.y - total_height) * 0.5, EDGE_MARGIN)

	var layouts := {}
	var equipment_x := start_x
	var current_y := top_y
	layouts[PlayerInventory.SLOT_PRIMARY] = _make_layout(Vector2(equipment_x, current_y), primary_size, metrics)
	current_y += primary_frame_size.y + float(metrics.get("stack_gap", STACK_GAP))
	layouts[PlayerInventory.SLOT_SECONDARY] = _make_layout(Vector2(equipment_x, current_y), secondary_size, metrics)
	current_y += secondary_frame_size.y + float(metrics.get("stack_gap", STACK_GAP))
	layouts[PlayerInventory.SLOT_MELEE] = _make_layout(Vector2(equipment_x, current_y), melee_size, metrics)
	layouts[PlayerInventory.SLOT_BACKPACK] = _make_layout(
		Vector2(start_x + equipment_width + float(metrics.get("equipment_gap", EQUIPMENT_TO_BACKPACK_GAP)), top_y),
		backpack_size,
		metrics
	)
	return layouts


func _make_layout(grid_origin: Vector2, grid_size: Vector2i, metrics: Dictionary) -> Dictionary:
	var header_height: float = metrics.get("header_height", HEADER_HEIGHT)
	var header_padding: float = metrics.get("panel_padding", PANEL_PADDING)
	var grid_pixel_size := _get_item_pixel_size(grid_size, metrics)
	var title_rect := Rect2(
		grid_origin + Vector2(0, -header_height + 6.0 * float(metrics.get("scale", 1.0))),
		Vector2(grid_pixel_size.x, 22.0 * float(metrics.get("scale", 1.0)))
	)
	var subtitle_rect := Rect2(
		grid_origin + Vector2(0, -header_height + 28.0 * float(metrics.get("scale", 1.0))),
		Vector2(grid_pixel_size.x, 24.0 * float(metrics.get("scale", 1.0)))
	)
	var frame_rect := Rect2(
		grid_origin - Vector2(header_padding, header_height + 8.0 * float(metrics.get("scale", 1.0))),
		Vector2(grid_pixel_size.x + header_padding * 2.0, grid_pixel_size.y + header_height + 24.0 * float(metrics.get("scale", 1.0)))
	)
	return {
		"grid_origin": grid_origin,
		"grid_size": grid_size,
		"title_rect": title_rect,
		"subtitle_rect": subtitle_rect,
		"frame_rect": frame_rect,
	}


func _get_frame_size(grid_size: Vector2i, metrics: Dictionary) -> Vector2:
	var grid_pixel_size := _get_item_pixel_size(grid_size, metrics)
	var panel_padding: float = metrics.get("panel_padding", PANEL_PADDING)
	var header_height: float = metrics.get("header_height", HEADER_HEIGHT)
	var panel_scale: float = metrics.get("scale", 1.0)
	return Vector2(grid_pixel_size.x + panel_padding * 2.0, grid_pixel_size.y + header_height + 24.0 * panel_scale)


func _get_metrics() -> Dictionary:
	var available_width := maxf(size.x - EDGE_MARGIN * 2.0, 320.0)
	var available_height := maxf(size.y - EDGE_MARGIN * 2.0 - FOOTER_GAP, 240.0)
	var natural := _build_metrics(1.0)
	var width_scale := available_width / float(natural.get("total_width", available_width))
	var height_scale := available_height / float(natural.get("total_height", available_height))
	var panel_scale := clampf(minf(1.0, minf(width_scale, height_scale)), BASE_SCALE_MIN, 1.0)
	return _build_metrics(panel_scale)


func _build_metrics(panel_scale: float) -> Dictionary:
	var metrics := {
		"scale": panel_scale,
		"cell_size": CELL_SIZE * panel_scale,
		"cell_gap": maxf(CELL_GAP * panel_scale, 2.0),
		"panel_padding": maxf(PANEL_PADDING * panel_scale, 10.0),
		"header_height": maxf(HEADER_HEIGHT * panel_scale, 34.0),
		"stack_gap": maxf(STACK_GAP * panel_scale, 12.0),
		"equipment_gap": maxf(EQUIPMENT_TO_BACKPACK_GAP * panel_scale, 26.0),
	}

	var primary_frame := _get_frame_size(inventory.get_container_size(PlayerInventory.SLOT_PRIMARY), metrics)
	var secondary_frame := _get_frame_size(inventory.get_container_size(PlayerInventory.SLOT_SECONDARY), metrics)
	var melee_frame := _get_frame_size(inventory.get_container_size(PlayerInventory.SLOT_MELEE), metrics)
	var backpack_frame := _get_frame_size(inventory.get_container_size(PlayerInventory.SLOT_BACKPACK), metrics)

	var equipment_width := maxf(primary_frame.x, maxf(secondary_frame.x, melee_frame.x))
	var equipment_height := primary_frame.y + secondary_frame.y + melee_frame.y + float(metrics.get("stack_gap")) * 2.0
	metrics["total_width"] = equipment_width + float(metrics.get("equipment_gap")) + backpack_frame.x
	metrics["total_height"] = maxf(equipment_height, backpack_frame.y)
	return metrics


func _get_cell_step(metrics: Dictionary) -> Vector2:
	return Vector2(
		float(metrics.get("cell_size", CELL_SIZE) + metrics.get("cell_gap", CELL_GAP)),
		float(metrics.get("cell_size", CELL_SIZE) + metrics.get("cell_gap", CELL_GAP))
	)


func _get_entry_size(entry: Dictionary, force_rotated: bool = false, use_force_rotation: bool = false) -> Vector2i:
	var weapon := entry.get("weapon") as WeaponResource
	if not weapon:
		return Vector2i.ZERO
	var rotated := force_rotated if use_force_rotation else bool(entry.get("rotated", false))
	var base_size := weapon.get_inventory_size()
	return Vector2i(base_size.y, base_size.x) if rotated else base_size


func _draw_wrapped_text(
	font: Font,
	text: String,
	rect: Rect2,
	font_size: int,
	color: Color,
	max_lines: int = 0
) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0 or text.is_empty():
		return

	var lines := _wrap_text(font, text, rect.size.x, font_size, max_lines)
	var y := rect.position.y + float(font_size)
	var line_step := float(font_size) + 2.0
	for line in lines:
		if y > rect.position.y + rect.size.y + 1.0:
			break
		draw_string(font, Vector2(rect.position.x, y), line,
			HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, font_size, color)
		y += line_step


func _wrap_text(
	font: Font,
	text: String,
	max_width: float,
	font_size: int,
	max_lines: int = 0
) -> Array[String]:
	var words := text.split(" ", false)
	var lines: Array[String] = []
	var current := ""

	for word in words:
		if current.is_empty():
			current = word
		else:
			var candidate := "%s %s" % [current, word]
			if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= max_width:
				current = candidate
			else:
				lines.append(current)
				current = word
		if max_lines > 0 and lines.size() >= max_lines:
			break

	if max_lines == 0 or lines.size() < max_lines:
		if not current.is_empty():
			lines.append(current)

	if max_lines > 0 and lines.size() > max_lines:
		lines.resize(max_lines)

	if max_lines > 0 and not lines.is_empty():
		var last_index := lines.size() - 1
		lines[last_index] = _fit_text_with_ellipsis(font, lines[last_index], max_width, font_size)

	return lines


func _fit_text_with_ellipsis(font: Font, text: String, max_width: float, font_size: int) -> String:
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= max_width:
		return text

	var clipped := text
	while not clipped.is_empty():
		clipped = clipped.left(clipped.length() - 1)
		var candidate := "%s..." % clipped
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= max_width:
			return candidate
	return "..."


func _get_item_color(weapon: WeaponResource) -> Color:
	match weapon.carry_class:
		WeaponResource.CarryClass.SMALL:
			return Color(0.28, 0.52, 0.7, 0.95)
		WeaponResource.CarryClass.MEDIUM:
			return Color(0.38, 0.63, 0.42, 0.95)
		WeaponResource.CarryClass.LARGE:
			return Color(0.64, 0.46, 0.3, 0.95)
		WeaponResource.CarryClass.VERY_LARGE:
			return Color(0.63, 0.28, 0.24, 0.95)
		WeaponResource.CarryClass.MELEE:
			return Color(0.7, 0.3, 0.28, 0.95)
		_:
			return Color(0.5, 0.5, 0.56, 0.95)


func _clear_drag() -> void:
	_drag_item_id = -1
	_drag_origin_container = &""
	_drag_origin_position = Vector2i.ZERO
	_drag_grab_cell = Vector2i.ZERO
	_drag_rotated = false
	_drag_start_mouse = Vector2.ZERO
	queue_redraw()


func _on_inventory_open_changed(is_open: bool) -> void:
	visible = is_open
	queue_redraw()


func _toggle_drag_rotation() -> void:
	if _drag_item_id == -1:
		return

	var entry := inventory.get_item(_drag_item_id)
	if entry.is_empty():
		return

	var weapon := entry.get("weapon") as WeaponResource
	if not weapon:
		return

	var current_size := _get_entry_size(entry, _drag_rotated, true)
	var next_rotated := not _drag_rotated
	_drag_grab_cell = _rotate_grab_cell(_drag_grab_cell, current_size, next_rotated)
	_drag_rotated = next_rotated
	queue_redraw()


func _rotate_grab_cell(grab_cell: Vector2i, current_size: Vector2i, next_rotated: bool) -> Vector2i:
	if next_rotated:
		return Vector2i(current_size.y - 1 - grab_cell.y, grab_cell.x)
	return Vector2i(grab_cell.y, current_size.x - 1 - grab_cell.x)
