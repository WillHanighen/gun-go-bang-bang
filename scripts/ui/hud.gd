extends Control

var weapon_label: Label
var ammo_label: Label
var fire_mode_label: Label
var caliber_label: Label
var hit_info_label: Label
var controls_label: Label

var _hit_info_timer: float = 0.0

var _wm: Node
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
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	await get_tree().process_frame
	_connect_signals()


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
	var spread_deg: float = _wm.current_spread if _wm.current_weapon_data else 0.0

	var caliber: CaliberResource = _wm.get_current_caliber() if _wm.current_weapon_data else null
	if caliber and caliber.pellet_count > 1:
		spread_deg += caliber.pellet_spread_deg

	spread_deg *= lerpf(1.0, 0.35, _wm.player._ads_progress)
	spread_deg *= lerpf(1.0, _wm.player.MOVE_SPREAD_WALK_MAX, _wm.player._walk_spread)
	spread_deg *= lerpf(1.0, _wm.player.MOVE_SPREAD_SPRINT_MAX, _wm.player._sprint_spread)
	spread_deg *= lerpf(1.0, 2.35, _wm.player._air_spread)
	spread_deg *= lerpf(1.0, 0.88, _wm.player._crouch_progress)

	var cam: Camera3D = _wm.player.get_node("Head/Camera3D")
	var half_fov_rad := deg_to_rad(cam.fov * 0.5)
	var pixels_per_deg := (size.y * 0.5) / rad_to_deg(half_fov_rad) if half_fov_rad > 0.0 else 14.0

	var target_px := maxf(2.0, spread_deg * pixels_per_deg)
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
	var weapon: WeaponResource = _wm.current_weapon_data
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

	draw_string(font, center + Vector2(-text_w / 2.0, -6), "SELECT AMMO",
		HORIZONTAL_ALIGNMENT_CENTER, text_w, font_size_hint, Color(0.6, 0.6, 0.6))
	draw_string(font, center + Vector2(-text_w / 2.0, 10), "release R to confirm",
		HORIZONTAL_ALIGNMENT_CENTER, text_w, font_size_hint - 2, Color(0.45, 0.45, 0.45))

	var seg_angle := TAU / float(count)
	for i in count:
		var mid_angle := seg_angle * float(i)
		var pos := center + Vector2(sin(mid_angle), -cos(mid_angle)) * radius

		var cal: CaliberResource = weapon.calibers[i]
		var selected: bool = (i == _wm.ammo_wheel_index)
		var is_current: bool = (i == _wm.current_caliber_index)

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
	var panel := VBoxContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_top = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -260
	panel.offset_top = -130
	panel.offset_right = -10
	panel.offset_bottom = -10
	add_child(panel)

	weapon_label = _make_label(20, Color.WHITE)
	panel.add_child(weapon_label)

	caliber_label = _make_label(14, Color(0.7, 0.7, 0.7))
	panel.add_child(caliber_label)

	fire_mode_label = _make_label(16, Color(1.0, 0.8, 0.3))
	panel.add_child(fire_mode_label)

	ammo_label = _make_label(24, Color.WHITE)
	panel.add_child(ammo_label)

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
	controls_label.text = "WASD: Move | Ctrl: Crouch | LMB: Fire | R: Reload (hold: ammo wheel) | V: Fire Mode | Q/E: Weapon | X: Quick Swap | Esc: Cursor"
	controls_label.add_theme_font_size_override("font_size", 12)
	controls_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.6))
	add_child(controls_label)


func _make_label(font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl


func _connect_signals() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if not p:
		return
	_wm = p.get_node_or_null("WeaponManager")
	if not _wm:
		return

	_wm.weapon_changed.connect(_on_weapon_changed)
	_wm.ammo_changed.connect(_on_ammo_changed)
	_wm.fire_mode_changed.connect(_on_fire_mode_changed)
	_wm.hit_registered.connect(_on_hit_registered)
	_wm.caliber_changed.connect(_on_caliber_changed)
	_wm.reload_started.connect(func(): ammo_label.text = "RELOADING...")

	if _wm.current_weapon_data:
		_on_weapon_changed(_wm.current_weapon_data)
		_on_ammo_changed(_wm.current_ammo, _wm.current_weapon_data.magazine_size)
		_on_fire_mode_changed(_wm.get_current_fire_mode())


func _on_weapon_changed(weapon: WeaponResource) -> void:
	weapon_label.text = weapon.weapon_name
	if weapon.calibers.size() > 0:
		var suffix := "  [hold R]" if weapon.calibers.size() > 1 else ""
		caliber_label.text = weapon.calibers[0].caliber_name + suffix


func _on_ammo_changed(current: int, max_ammo: int) -> void:
	ammo_label.text = "%d / %d" % [current, max_ammo]


func _on_fire_mode_changed(mode: WeaponResource.FireMode) -> void:
	var names := {
		WeaponResource.FireMode.SEMI: "SEMI",
		WeaponResource.FireMode.BURST: "BURST",
		WeaponResource.FireMode.AUTO: "AUTO",
		WeaponResource.FireMode.PUMP: "PUMP",
	}
	fire_mode_label.text = names.get(mode, "???")


func _on_caliber_changed(caliber: CaliberResource) -> void:
	if caliber:
		caliber_label.text = caliber.caliber_name + "  [hold R]"


func _on_hit_registered(distance: float, damage: float, _target_name: String) -> void:
	_volley_dmg += damage
	_volley_hits += 1
	_volley_dist = distance
	_volley_target = _target_name
	_volley_timer = VOLLEY_WINDOW


func _finalize_volley() -> void:
	var yards := _volley_dist / 0.9144
	var parts: PackedStringArray = []

	var weapon: WeaponResource = _wm.current_weapon_data if _wm else null
	var caliber: CaliberResource = _wm.get_current_caliber() if _wm else null
	var mode: WeaponResource.FireMode = _wm.get_current_fire_mode() if _wm else WeaponResource.FireMode.SEMI

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
