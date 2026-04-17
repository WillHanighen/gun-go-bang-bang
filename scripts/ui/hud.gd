extends Control

const InventoryPanelScript := preload("res://scripts/ui/inventory_panel.gd")
const HAND_1 := &"hand_1"
const HAND_2 := &"hand_2"
const STATUS_PANEL_WIDTH := 340.0
const STATUS_PANEL_MARGIN := 12.0

var weapon_label: Label
var ammo_label: Label
var fire_mode_label: Label
var caliber_label: Label
var hit_info_label: Label
var controls_label: Label
var interaction_prompt_label: Label
var inventory_panel: Control
var status_panel: VBoxContainer

var _hit_info_timer: float = 0.0

var _wm: Node
var _inventory: PlayerInventory
var _volley_dmg := 0.0
var _volley_hits := 0
var _volley_dist := 0.0
var _volley_target := ""
var _volley_timer := 0.0
const VOLLEY_WINDOW := 0.15

var _crosshair_gap := 4.0
var _shotgun_circle_radius := 4.0
var _shotgun_crosshair := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
	await get_tree().process_frame
	_connect_signals()
	_layout_status_panel()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_status_panel()


func _process(delta: float) -> void:
	if _volley_timer > 0.0:
		_volley_timer -= delta
		if _volley_timer <= 0.0:
			_finalize_volley()

	if _hit_info_timer > 0.0:
		_hit_info_timer -= delta
		if _hit_info_timer <= 0.0:
			hit_info_label.text = ""

	_update_crosshair()


func _update_crosshair() -> void:
	if not _wm:
		return
	var caliber: CaliberResource = null
	for hand in [HAND_1, HAND_2]:
		var candidate: CaliberResource = _wm.get_hand_caliber(hand)
		if candidate and candidate.pellet_count > 1:
			caliber = candidate
			break
		if candidate and caliber == null:
			caliber = candidate
	var target_px: float = _wm.get_crosshair_pixels(size)
	_shotgun_crosshair = caliber != null and caliber.pellet_count > 1
	if _shotgun_crosshair:
		_shotgun_circle_radius = lerpf(_shotgun_circle_radius, target_px, 0.25)
	else:
		_crosshair_gap = lerpf(_crosshair_gap, target_px, 0.25)
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0

	if _wm and _wm.ammo_wheel_open:
		_draw_ammo_wheel(center)
		return

	var col := Color.WHITE
	var thick := 2.0

	if _shotgun_crosshair:
		var r := _shotgun_circle_radius
		draw_arc(center, r, 0.0, TAU, 64, col, thick, true)
	else:
		var gap := _crosshair_gap
		var length := clampf(gap * 0.8, 6.0, 20.0)
		draw_rect(Rect2(center.x - thick / 2, center.y - gap - length, thick, length), col)
		draw_rect(Rect2(center.x - thick / 2, center.y + gap, thick, length), col)
		draw_rect(Rect2(center.x - gap - length, center.y - thick / 2, length, thick), col)
		draw_rect(Rect2(center.x + gap, center.y - thick / 2, length, thick), col)

	draw_rect(Rect2(center.x - 1, center.y - 1, 2, 2), col)


func _draw_ammo_wheel(center: Vector2) -> void:
	var wheel_hand: StringName = _wm.get_ammo_wheel_hand()
	var weapon: WeaponResource = _wm.get_hand_weapon(wheel_hand)
	if not weapon:
		return
	var count := weapon.calibers.size()
	if count <= 1:
		return

	var radius := 120.0
	var font := get_theme_default_font()
	var font_size_name := 15
	var font_size_stat := 11
	var font_size_hint := 12
	var text_w := 160

	draw_circle(center, radius + 55.0, Color(0, 0, 0, 0.65))
	draw_arc(center, radius + 55.0, 0.0, TAU, 64, Color(0.4, 0.4, 0.4, 0.4), 1.5)

	var hand_label := "HAND 2" if wheel_hand == HAND_2 else "HAND 1"
	draw_string(font, center + Vector2(-text_w / 2.0, -6), "SELECT AMMO (%s)" % hand_label,
		HORIZONTAL_ALIGNMENT_CENTER, text_w, font_size_hint, Color(0.6, 0.6, 0.6))
	draw_string(font, center + Vector2(-text_w / 2.0, 10), "release R to confirm",
		HORIZONTAL_ALIGNMENT_CENTER, text_w, font_size_hint - 2, Color(0.45, 0.45, 0.45))

	var seg_angle := TAU / float(count)
	for i in count:
		var mid_angle := seg_angle * float(i)
		var pos := center + Vector2(sin(mid_angle), -cos(mid_angle)) * radius

		var cal: CaliberResource = weapon.calibers[i]
		var selected: bool = (i == _wm.ammo_wheel_index)
		var is_current: bool = (i == _wm.get_hand_caliber_index(wheel_hand))

		if selected:
			draw_circle(pos, 42.0, Color(1.0, 0.8, 0.2, 0.25))
			draw_arc(pos, 42.0, 0.0, TAU, 32, Color(1.0, 0.85, 0.3, 0.7), 2.0)
		elif is_current:
			draw_arc(pos, 42.0, 0.0, TAU, 32, Color(0.3, 1.0, 0.3, 0.35), 1.5)

		var name_col := Color.YELLOW if selected else (Color(0.6, 1.0, 0.6) if is_current else Color.WHITE)
		draw_string(font, pos + Vector2(-text_w / 2.0, -6), cal.caliber_name,
			HORIZONTAL_ALIGNMENT_CENTER, text_w, font_size_name, name_col)

		var stats := "DMG:%.0f" % cal.base_damage
		if cal.pellet_count > 1:
			stats += "x%d" % cal.pellet_count
		stats += "  PEN:%.0f%%" % (cal.penetration_power * 100.0)
		if cal.incendiary_damage > 0.0:
			stats += "  FIRE:%.0f" % cal.incendiary_damage
		var stat_col := Color(0.85, 0.85, 0.85) if selected else Color(0.5, 0.5, 0.5)
		draw_string(font, pos + Vector2(-text_w / 2.0, 10), stats,
			HORIZONTAL_ALIGNMENT_CENTER, text_w, font_size_stat, stat_col)


func _build_ui() -> void:
	status_panel = VBoxContainer.new()
	status_panel.custom_minimum_size = Vector2(STATUS_PANEL_WIDTH, 0.0)
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(status_panel)

	weapon_label = _make_label(20, Color.WHITE)
	status_panel.add_child(weapon_label)

	caliber_label = _make_label(14, Color(0.7, 0.7, 0.7))
	status_panel.add_child(caliber_label)

	fire_mode_label = _make_label(16, Color(1.0, 0.8, 0.3))
	status_panel.add_child(fire_mode_label)

	ammo_label = _make_label(24, Color.WHITE)
	status_panel.add_child(ammo_label)

	hit_info_label = Label.new()
	hit_info_label.anchor_left = 0.5
	hit_info_label.anchor_right = 0.5
	hit_info_label.offset_left = -350
	hit_info_label.offset_right = 350
	hit_info_label.offset_top = 50
	hit_info_label.offset_bottom = 80
	hit_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hit_info_label.add_theme_font_size_override("font_size", 18)
	hit_info_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	add_child(hit_info_label)

	controls_label = Label.new()
	controls_label.anchor_left = 0.5
	controls_label.anchor_right = 0.5
	controls_label.offset_left = -450
	controls_label.offset_right = 450
	controls_label.offset_top = 8
	controls_label.offset_bottom = 28
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.text = "WASD: Move | Ctrl: Crouch | F: Interact | Tab: Inventory | LMB: Hand 1 | RMB: Hand 2 | MMB: Aim | R / Alt+R: Reload | V / Alt+V: Fire Mode | X / Alt+X: Ammo | Q/E: Loadout | Esc: Cursor"
	controls_label.add_theme_font_size_override("font_size", 12)
	controls_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.6))
	add_child(controls_label)

	interaction_prompt_label = Label.new()
	interaction_prompt_label.anchor_left = 0.5
	interaction_prompt_label.anchor_right = 0.5
	interaction_prompt_label.offset_left = -280
	interaction_prompt_label.offset_right = 280
	interaction_prompt_label.offset_top = 430
	interaction_prompt_label.offset_bottom = 460
	interaction_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_prompt_label.add_theme_font_size_override("font_size", 18)
	interaction_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	add_child(interaction_prompt_label)

	inventory_panel = Control.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	inventory_panel.set_script(InventoryPanelScript)
	add_child(inventory_panel)


func _make_label(font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl


func _connect_signals() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if not p:
		return

	_inventory = p.get_node_or_null("PlayerInventory") as PlayerInventory
	if _inventory and inventory_panel:
		inventory_panel.call("setup", _inventory)

	p.interaction_prompt_changed.connect(_on_interaction_prompt_changed)
	_on_interaction_prompt_changed(p.get_interaction_prompt())

	_wm = p.get_node_or_null("WeaponManager")
	if not _wm:
		return

	_wm.weapon_changed.connect(_on_weapon_changed)
	_wm.ammo_changed.connect(_on_ammo_changed)
	_wm.fire_mode_changed.connect(_on_fire_mode_changed)
	_wm.hit_registered.connect(_on_hit_registered)
	_wm.caliber_changed.connect(_on_caliber_changed)
	_wm.loadout_changed.connect(_on_loadout_changed)
	_wm.reload_started.connect(_refresh_loadout)

	if _wm.current_weapon_data:
		_refresh_loadout()
	else:
		_on_weapon_changed(null)
		_on_ammo_changed(0, 0)
		_on_fire_mode_changed(WeaponResource.FireMode.SEMI)


func _on_interaction_prompt_changed(prompt: String) -> void:
	interaction_prompt_label.text = prompt


func _on_weapon_changed(_weapon: WeaponResource) -> void:
	_refresh_loadout()


func _on_ammo_changed(_current: int, _max_ammo: int) -> void:
	_refresh_loadout()


func _on_fire_mode_changed(_mode: WeaponResource.FireMode) -> void:
	_refresh_loadout()


func _on_caliber_changed(_caliber: CaliberResource) -> void:
	_refresh_loadout()


func _on_loadout_changed(_loadout: Dictionary) -> void:
	_refresh_loadout()


func _on_hit_registered(distance: float, damage: float, _target_name: String) -> void:
	_volley_dmg += damage
	_volley_hits += 1
	_volley_dist = distance
	_volley_target = _target_name
	_volley_timer = VOLLEY_WINDOW


func _finalize_volley() -> void:
	var yards := _volley_dist / 0.9144
	var parts: PackedStringArray = []

	var hand: StringName = _wm.get_last_fired_hand() if _wm else HAND_1
	var weapon: WeaponResource = _wm.get_hand_weapon(hand) if _wm else null
	var caliber: CaliberResource = _wm.get_hand_caliber(hand) if _wm else null
	var mode: WeaponResource.FireMode = _wm.get_hand_fire_mode(hand) if _wm else WeaponResource.FireMode.SEMI

	if _volley_hits > 1 and caliber and caliber.pellet_count > 1:
		parts.append("%d/%d pellets" % [_volley_hits, caliber.pellet_count])
		parts.append("%.1f total" % _volley_dmg)
	elif _volley_hits > 1:
		parts.append("BURST: %d hits" % _volley_hits)
		parts.append("%.1f total" % _volley_dmg)
	else:
		parts.append("%.1f dmg" % _volley_dmg)

	parts.append("%.1f yd (%.1f m)" % [yards, _volley_dist])

	if weapon:
		var cycle: float
		if mode == WeaponResource.FireMode.BURST:
			cycle = weapon.burst_count * weapon.get_seconds_between_shots()
		else:
			cycle = weapon.get_seconds_between_shots()
		if cycle > 0.0:
			parts.append("DPS: %.0f" % (_volley_dmg / cycle))

	hit_info_label.text = " | ".join(parts)
	_hit_info_timer = 4.0

	_volley_dmg = 0.0
	_volley_hits = 0
	_volley_dist = 0.0
	_volley_target = ""


func _refresh_loadout() -> void:
	if not _wm:
		return
	var loadout: Dictionary = _wm.get_loadout()
	var hand_1 := _format_hand_line(HAND_1, loadout.get(HAND_1, {}) as Dictionary)
	var hand_2 := _format_hand_line(HAND_2, loadout.get(HAND_2, {}) as Dictionary)
	if hand_1.is_empty() and hand_2.is_empty():
		weapon_label.text = "UNARMED"
		caliber_label.text = ""
		fire_mode_label.text = ""
		ammo_label.text = ""
		return

	weapon_label.text = hand_1
	if not hand_2.is_empty():
		weapon_label.text += "\n" + hand_2

	var caliber_lines: PackedStringArray = []
	var fire_mode_lines: PackedStringArray = []
	var ammo_lines: PackedStringArray = []
	for hand in [HAND_1, HAND_2]:
		var hand_entry := loadout.get(hand, {}) as Dictionary
		if hand_entry.is_empty():
			continue
		var hand_label := "H2" if hand == HAND_2 else "H1"
		var caliber: CaliberResource = _wm.get_hand_caliber(hand)
		var caliber_line := "%s %s" % [hand_label, caliber.caliber_name if caliber else "NO CAL"]
		if _wm.get_hand_weapon(hand) and _wm.get_hand_weapon(hand).calibers.size() > 1:
			caliber_line += "  [hold %sR]" % ("Alt+" if hand == HAND_2 else "")
		caliber_lines.append(caliber_line)

		var mode_name := _mode_name(_wm.get_hand_fire_mode(hand))
		fire_mode_lines.append("%s %s" % [hand_label, mode_name])

		var ammo_line := "%s %d / %d" % [hand_label, _wm.get_hand_ammo(hand), _wm.get_hand_max_ammo(hand)]
		if _wm.is_hand_reloading(hand):
			ammo_line += "  RELOADING"
		ammo_lines.append(ammo_line)

	caliber_label.text = "\n".join(caliber_lines)
	fire_mode_label.text = "\n".join(fire_mode_lines)
	ammo_label.text = "\n".join(ammo_lines)
	_layout_status_panel()


func _format_hand_line(hand: StringName, hand_entry: Dictionary) -> String:
	if hand_entry.is_empty():
		return ""
	var weapon := hand_entry.get("weapon") as WeaponResource
	if not weapon:
		return ""
	var hand_label := "H2" if hand == HAND_2 else "H1"
	var suffix := ""
	if bool(hand_entry.get("has_support_hand", false)):
		suffix = "  [2H support]"
	elif bool(hand_entry.get("is_offhand", false)):
		suffix = "  [off-hand]"
	elif bool(_wm.get_loadout().get("two_handed", false)):
		suffix = "  [2H]"
	return "%s %s%s" % [hand_label, weapon.weapon_name, suffix]


func _mode_name(mode: WeaponResource.FireMode) -> String:
	var names := {
		WeaponResource.FireMode.SEMI: "SEMI",
		WeaponResource.FireMode.BURST: "BURST",
		WeaponResource.FireMode.AUTO: "AUTO",
		WeaponResource.FireMode.PUMP: "PUMP",
	}
	return names.get(mode, "???")


func _layout_status_panel() -> void:
	if not status_panel:
		return
	var min_size := status_panel.get_combined_minimum_size()
	min_size.x = maxf(min_size.x, STATUS_PANEL_WIDTH)
	status_panel.size = min_size
	status_panel.position = Vector2(
		maxf(size.x - min_size.x - STATUS_PANEL_MARGIN, STATUS_PANEL_MARGIN),
		maxf(size.y - min_size.y - STATUS_PANEL_MARGIN, STATUS_PANEL_MARGIN)
	)
