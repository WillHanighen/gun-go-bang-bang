extends Node

signal weapon_fired(caliber: CaliberResource, directions: Array[Vector3], origin: Vector3)
signal weapon_changed(weapon: WeaponResource)
signal ammo_changed(current: int, max_ammo: int)
signal fire_mode_changed(mode: WeaponResource.FireMode)
signal caliber_changed(caliber: CaliberResource)
signal hit_registered(distance: float, damage: float, target_name: String)
signal reload_started()

var weapons: Array[WeaponResource] = []
var current_weapon_index: int = 0
var current_caliber_index: int = 0
var current_weapon_data: WeaponResource
var current_ammo: int = 0
var current_fire_mode_index: int = 0
var current_spread: float = 0.0

var _time_since_last_shot: float = 999.0
var _burst_remaining: int = 0
var _burst_timer: float = 0.0
var _is_reloading: bool = false
var _reload_timer: float = 0.0

var ammo_wheel_open := false
var ammo_wheel_index := 0
var _wheel_cursor := Vector2.ZERO
var _reload_key_held := false
var _reload_hold_time := 0.0
const WHEEL_HOLD_THRESHOLD := 0.15
const WHEEL_DEADZONE := 15.0

const MAX_DECALS := 200
var _decals: Array[MeshInstance3D] = []
var _decal_mesh: QuadMesh
var _decal_mat: StandardMaterial3D
var _decal_mat_incen: StandardMaterial3D

@onready var player: CharacterBody3D = get_parent()


func _ready() -> void:
	_init_decal_resources()


func _process(delta: float) -> void:
	_time_since_last_shot += delta
	_update_spread(delta)
	_process_reload(delta)
	_process_ammo_wheel(delta)
	_handle_input()
	_process_burst(delta)


func equip_weapon(index: int) -> void:
	if index < 0 or index >= weapons.size():
		return
	current_weapon_index = index
	current_weapon_data = weapons[index]
	current_caliber_index = 0
	current_fire_mode_index = 0
	current_ammo = current_weapon_data.magazine_size
	current_spread = current_weapon_data.base_spread
	_burst_remaining = 0
	_is_reloading = false
	ammo_wheel_open = false
	_reload_key_held = false
	weapon_changed.emit(current_weapon_data)
	fire_mode_changed.emit(get_current_fire_mode())
	ammo_changed.emit(current_ammo, current_weapon_data.magazine_size)
	if current_weapon_data.calibers.size() > 0:
		caliber_changed.emit(current_weapon_data.calibers[0])


func get_current_fire_mode() -> WeaponResource.FireMode:
	if not current_weapon_data or current_weapon_data.fire_modes.is_empty():
		return WeaponResource.FireMode.SEMI
	return current_weapon_data.fire_modes[current_fire_mode_index]


func get_current_caliber() -> CaliberResource:
	if not current_weapon_data or current_weapon_data.calibers.is_empty():
		return null
	return current_weapon_data.calibers[current_caliber_index]


func cycle_fire_mode() -> void:
	if not current_weapon_data:
		return
	current_fire_mode_index = (current_fire_mode_index + 1) % current_weapon_data.fire_modes.size()
	fire_mode_changed.emit(get_current_fire_mode())


func cycle_ammo() -> void:
	if not current_weapon_data or current_weapon_data.calibers.size() <= 1:
		return
	current_caliber_index = (current_caliber_index + 1) % current_weapon_data.calibers.size()
	caliber_changed.emit(get_current_caliber())
	_is_reloading = true
	_reload_timer = current_weapon_data.reload_time
	reload_started.emit()


func start_reload() -> void:
	if not current_weapon_data or _is_reloading:
		return
	if current_ammo >= current_weapon_data.magazine_size:
		return
	_is_reloading = true
	_reload_timer = current_weapon_data.reload_time
	reload_started.emit()


# -- decals --------------------------------------------------------------------

func _init_decal_resources() -> void:
	_decal_mesh = QuadMesh.new()
	_decal_mesh.size = Vector2(0.04, 0.04)

	_decal_mat = StandardMaterial3D.new()
	_decal_mat.albedo_color = Color(0.05, 0.05, 0.05, 0.85)
	_decal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_decal_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_decal_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_decal_mat.render_priority = 1

	_decal_mat_incen = StandardMaterial3D.new()
	_decal_mat_incen.albedo_color = Color(0.18, 0.08, 0.0, 0.9)
	_decal_mat_incen.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_decal_mat_incen.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_decal_mat_incen.cull_mode = BaseMaterial3D.CULL_DISABLED
	_decal_mat_incen.render_priority = 1


func _spawn_decal(hit_pos: Vector3, normal: Vector3, is_incen: bool) -> void:
	var decal := MeshInstance3D.new()
	decal.mesh = _decal_mesh
	decal.set_surface_override_material(0, _decal_mat_incen if is_incen else _decal_mat)

	var scale_f := randf_range(0.8, 1.3)
	decal.scale = Vector3(scale_f, scale_f, 1.0)

	player.get_parent().add_child(decal)
	decal.global_position = hit_pos + normal * 0.002

	var up_hint := Vector3.FORWARD if normal.abs().is_equal_approx(Vector3.UP) else Vector3.UP
	decal.look_at(decal.global_position + normal, up_hint)
	decal.rotate_object_local(Vector3.FORWARD, randf() * TAU)

	_decals.append(decal)
	while _decals.size() > MAX_DECALS:
		var old: MeshInstance3D = _decals.pop_front()
		if is_instance_valid(old):
			old.queue_free()


# -- internals -----------------------------------------------------------------

func _handle_input() -> void:
	if Input.is_action_just_pressed("next_weapon"):
		equip_weapon((current_weapon_index + 1) % weapons.size())

	if Input.is_action_just_pressed("prev_weapon"):
		equip_weapon((current_weapon_index - 1 + weapons.size()) % weapons.size())

	if Input.is_action_just_pressed("switch_fire_mode"):
		cycle_fire_mode()

	if Input.is_action_just_pressed("switch_ammo"):
		cycle_ammo()

	if _is_reloading or ammo_wheel_open:
		return

	if Input.is_action_just_pressed("fire"):
		_try_fire()
	elif Input.is_action_pressed("fire") and get_current_fire_mode() == WeaponResource.FireMode.AUTO:
		_try_fire()


func feed_wheel_mouse(delta: Vector2) -> void:
	_wheel_cursor += delta


func _process_ammo_wheel(delta: float) -> void:
	if Input.is_action_just_pressed("reload"):
		_reload_key_held = true
		_reload_hold_time = 0.0
		_wheel_cursor = Vector2.ZERO

	if _reload_key_held:
		_reload_hold_time += delta
		var has_options := current_weapon_data and current_weapon_data.calibers.size() > 1
		if _reload_hold_time >= WHEEL_HOLD_THRESHOLD and has_options:
			ammo_wheel_open = true
			_update_wheel_selection()

	if Input.is_action_just_released("reload"):
		_reload_key_held = false
		if ammo_wheel_open:
			ammo_wheel_open = false
			current_caliber_index = ammo_wheel_index
			caliber_changed.emit(get_current_caliber())
			_is_reloading = true
			_reload_timer = current_weapon_data.reload_time
			reload_started.emit()
		elif _is_reloading:
			_is_reloading = false
			ammo_changed.emit(current_ammo, current_weapon_data.magazine_size)
		else:
			start_reload()


func _update_wheel_selection() -> void:
	if not current_weapon_data:
		return
	var count := current_weapon_data.calibers.size()
	if count <= 1:
		ammo_wheel_index = 0
		return
	if _wheel_cursor.length() < WHEEL_DEADZONE:
		ammo_wheel_index = current_caliber_index
		return
	var angle := atan2(_wheel_cursor.x, -_wheel_cursor.y)
	var adjusted := fmod(angle + TAU, TAU)
	ammo_wheel_index = int(adjusted / (TAU / float(count))) % count


func _try_fire() -> void:
	if not current_weapon_data or current_ammo <= 0:
		return
	if _time_since_last_shot < current_weapon_data.get_seconds_between_shots():
		return
	if _burst_remaining > 0:
		return

	var mode := get_current_fire_mode()
	if mode == WeaponResource.FireMode.BURST:
		_burst_remaining = current_weapon_data.burst_count - 1
		_burst_timer = 0.0
	_fire_single_round()


func _fire_single_round() -> void:
	if current_ammo <= 0:
		return
	current_ammo -= 1
	_time_since_last_shot = 0.0

	var caliber := get_current_caliber()
	if not caliber:
		return

	var cam: Camera3D = player.get_node("Head/Camera3D")
	var origin := cam.global_position
	var forward := -cam.global_basis.z
	var up := cam.global_basis.y

	var ads_mult := lerpf(1.0, 0.35, player._ads_progress)
	var sprint_mult := lerpf(1.0, 2.5, player._sprint_spread)
	var effective_spread := current_spread * ads_mult * sprint_mult
	var effective_pellet_spread := caliber.pellet_spread_deg * lerpf(1.0, 0.7, player._ads_progress)

	var directions := Ballistics.calculate_spread_directions(
		forward, up, caliber.pellet_count, effective_pellet_spread, effective_spread
	)

	_perform_hitscan(origin, directions, caliber)

	var v_recoil := current_weapon_data.get_effective_recoil_vertical()
	var h_recoil := randf_range(
		-current_weapon_data.get_effective_recoil_horizontal(),
		current_weapon_data.get_effective_recoil_horizontal()
	)
	player.apply_recoil(v_recoil, h_recoil)

	current_spread = minf(
		current_spread + current_weapon_data.spread_increase_per_shot,
		current_weapon_data.max_spread
	)

	ammo_changed.emit(current_ammo, current_weapon_data.magazine_size)
	weapon_fired.emit(caliber, directions, origin)


func _perform_hitscan(origin: Vector3, directions: Array[Vector3], caliber: CaliberResource) -> void:
	var space_state := player.get_world_3d().direct_space_state
	var is_incen := caliber.incendiary_damage > 0.0

	for dir in directions:
		var end := origin + dir * caliber.max_range
		var query := PhysicsRayQueryParameters3D.create(origin, end)
		query.collision_mask = 0b1101
		query.collide_with_bodies = true

		var remaining_pen := caliber.penetration_power
		var damage_mult := 1.0
		var ray_origin := origin
		var excluded: Array[RID] = []

		for _pass in 3:
			query.from = ray_origin
			query.to = end
			query.exclude = excluded
			var result := space_state.intersect_ray(query)

			if result.is_empty():
				break

			var hit_pos: Vector3 = result.position
			var hit_normal: Vector3 = result.normal
			var hit_dist := origin.distance_to(hit_pos)
			var hit_obj: Object = result.collider
			excluded.append(result.rid)

			_spawn_decal(hit_pos, hit_normal, is_incen)

			if hit_obj.has_method("take_damage"):
				var raw_dmg := caliber.get_damage_at_distance(hit_dist) * damage_mult
				var final_dmg := raw_dmg * caliber.flesh_damage_mult + caliber.incendiary_damage
				hit_obj.take_damage(final_dmg, hit_pos, dir)
				hit_registered.emit(hit_dist, final_dmg, hit_obj.name)

			var material := "default"
			if hit_obj.has_meta("material_type"):
				material = hit_obj.get_meta("material_type")

			if Ballistics.can_penetrate(remaining_pen, material):
				var pen_mult := Ballistics.get_penetration_damage_mult(remaining_pen, material)
				damage_mult *= pen_mult
				remaining_pen *= pen_mult
				ray_origin = hit_pos + dir * 0.05
			else:
				break


func _process_burst(delta: float) -> void:
	if _burst_remaining <= 0:
		return
	_burst_timer += delta
	var interval := current_weapon_data.get_seconds_between_shots()
	if _burst_timer >= interval:
		_burst_timer -= interval
		_burst_remaining -= 1
		_fire_single_round()


func _update_spread(delta: float) -> void:
	if not current_weapon_data:
		return
	if _time_since_last_shot > 0.1:
		current_spread = move_toward(
			current_spread,
			current_weapon_data.base_spread,
			current_weapon_data.spread_recovery_rate * delta
		)


func _process_reload(delta: float) -> void:
	if not _is_reloading:
		return
	_reload_timer -= delta
	if _reload_timer <= 0.0:
		_is_reloading = false
		current_ammo = current_weapon_data.magazine_size
		ammo_changed.emit(current_ammo, current_weapon_data.magazine_size)
