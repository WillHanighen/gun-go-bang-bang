extends Node

const WeaponSpreadHelperScript := preload("res://scripts/player/weapon_spread_helper.gd")
const WeaponDecalPoolScript := preload("res://scripts/player/weapon_decal_pool.gd")
const WeaponShotResolverScript := preload("res://scripts/player/weapon_shot_resolver.gd")

signal weapon_fired(caliber: CaliberResource, directions: Array[Vector3], origin: Vector3)
signal weapon_changed(weapon: WeaponResource)
signal ammo_changed(current: int, max_ammo: int)
signal fire_mode_changed(mode: WeaponResource.FireMode)
signal caliber_changed(caliber: CaliberResource)
signal hit_registered(distance: float, damage: float, target_name: String)
signal reload_started()

const MAX_DECALS := 200
const WHEEL_HOLD_THRESHOLD := 0.15
const WHEEL_DEADZONE := 15.0

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
var _burst_volley_shot_index: int = 0
var _burst_delayed_recoil_id: int = 0
var _is_reloading: bool = false
var _reload_timer: float = 0.0
## True while loading shells one at a time (per_shell_reload_time > 0).
var _reload_incremental: bool = false
## True when a caliber swap delay should hand off into shell-by-shell loading.
var _reload_continue_incremental: bool = false
## Per-weapon-index snapshots so switching away keeps fire mode, ammo type, rounds, spread, reload progress.
var _weapon_snapshots: Dictionary = {}

var ammo_wheel_open := false
var ammo_wheel_index := 0
var _wheel_cursor := Vector2.ZERO
var _reload_key_held := false
var _reload_hold_time := 0.0
## Consecutive empty fire clicks (LMB); second click starts reload.
var _empty_dry_fire_streak := 0

@onready var player: CharacterBody3D = get_parent() as CharacterBody3D

var _camera: Camera3D
var _decal_pool
var _shot_resolver


func _ready() -> void:
	_camera = _resolve_camera()
	var decal_parent := player.get_parent() if player and player.get_parent() else player
	var decal_pool_script: Script = WeaponDecalPoolScript
	_decal_pool = decal_pool_script.new()
	_decal_pool.setup(decal_parent, MAX_DECALS)
	if player:
		var shot_resolver_script: Script = WeaponShotResolverScript
		_shot_resolver = shot_resolver_script.new()
		_shot_resolver.setup(player.get_world_3d(), _decal_pool)


func _process(delta: float) -> void:
	_time_since_last_shot += delta
	_update_spread(delta)
	_process_reload(delta)
	_process_ammo_wheel(delta)
	_handle_input()
	_process_burst(delta)


func get_player_camera() -> Camera3D:
	if not _camera:
		_camera = _resolve_camera()
	return _camera


func get_crosshair_spread_degrees() -> float:
	if not current_weapon_data:
		return 0.0
	var profile := WeaponSpreadHelperScript.build_profile(
		player,
		current_weapon_data,
		get_current_caliber(),
		current_spread,
		_is_burst_compensation_active()
	)
	return float(profile.get("crosshair_spread_deg", 0.0))


func get_crosshair_pixels(viewport_size: Vector2) -> float:
	return WeaponSpreadHelperScript.get_crosshair_pixels(
		get_player_camera(),
		viewport_size,
		get_crosshair_spread_degrees()
	)


func equip_weapon(index: int) -> void:
	if index < 0 or index >= weapons.size():
		return
	if index == current_weapon_index and current_weapon_data != null:
		return

	_persist_current_weapon_if_any()
	current_weapon_index = index
	current_weapon_data = weapons[index]
	if _weapon_snapshots.has(index):
		_restore_weapon_snapshot(_weapon_snapshots[index] as Dictionary)
	else:
		_apply_default_weapon_state()

	_burst_remaining = 0
	_burst_volley_shot_index = 0
	_burst_timer = 0.0
	_burst_delayed_recoil_id += 1
	ammo_wheel_open = false
	ammo_wheel_index = current_caliber_index
	_reload_key_held = false
	_empty_dry_fire_streak = 0

	weapon_changed.emit(current_weapon_data)
	fire_mode_changed.emit(get_current_fire_mode())
	ammo_changed.emit(current_ammo, current_weapon_data.magazine_size)
	if current_weapon_data.calibers.size() > 0:
		caliber_changed.emit(get_current_caliber())


func get_current_fire_mode() -> WeaponResource.FireMode:
	if not current_weapon_data or current_weapon_data.fire_modes.is_empty():
		return WeaponResource.FireMode.SEMI
	return current_weapon_data.fire_modes[current_fire_mode_index]


func get_current_caliber() -> CaliberResource:
	if not current_weapon_data or current_weapon_data.calibers.is_empty():
		return null
	return current_weapon_data.calibers[current_caliber_index]


func cycle_fire_mode() -> void:
	if not current_weapon_data or current_weapon_data.fire_modes.is_empty():
		return
	current_fire_mode_index = (current_fire_mode_index + 1) % current_weapon_data.fire_modes.size()
	fire_mode_changed.emit(get_current_fire_mode())


func cycle_ammo() -> void:
	if not current_weapon_data or current_weapon_data.calibers.size() <= 1:
		return
	current_caliber_index = (current_caliber_index + 1) % current_weapon_data.calibers.size()
	ammo_wheel_index = current_caliber_index
	caliber_changed.emit(get_current_caliber())
	_start_caliber_swap_reload()


func start_reload() -> void:
	if not current_weapon_data or _is_reloading:
		return
	if current_ammo >= current_weapon_data.magazine_size:
		return
	var is_incremental := current_weapon_data.per_shell_reload_time > 0.0
	var reload_time := (
		current_weapon_data.per_shell_reload_time
		if is_incremental
		else current_weapon_data.reload_time
	)
	_start_reload_timer(reload_time, is_incremental)


func feed_wheel_mouse(delta: Vector2) -> void:
	_wheel_cursor += delta


func _handle_input() -> void:
	if weapons.is_empty():
		return

	if Input.is_action_just_pressed("next_weapon"):
		equip_weapon((current_weapon_index + 1) % weapons.size())

	if Input.is_action_just_pressed("prev_weapon"):
		equip_weapon((current_weapon_index - 1 + weapons.size()) % weapons.size())

	if Input.is_action_just_pressed("switch_fire_mode"):
		cycle_fire_mode()

	if Input.is_action_just_pressed("switch_ammo"):
		cycle_ammo()

	if ammo_wheel_open:
		return

	if Input.is_action_just_pressed("fire"):
		_try_cancel_shotgun_reload_for_fire()
		if _is_reloading:
			return
		if current_weapon_data:
			if current_ammo > 0:
				_empty_dry_fire_streak = 0
			else:
				_empty_dry_fire_streak += 1
				if _empty_dry_fire_streak >= 2:
					_empty_dry_fire_streak = 0
					start_reload()
				return
		_try_fire()
	elif Input.is_action_pressed("fire") and get_current_fire_mode() == WeaponResource.FireMode.AUTO:
		_try_cancel_shotgun_reload_for_fire()
		if _is_reloading:
			return
		_try_fire()


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
		_burst_volley_shot_index = 0
	_fire_single_round()


func _fire_single_round() -> void:
	if current_ammo <= 0 or not current_weapon_data:
		return

	var caliber := get_current_caliber()
	var camera := get_player_camera()
	if not caliber or not camera or not _shot_resolver:
		return

	var burst_pair_tight := _is_burst_compensation_active()
	var spread_profile := WeaponSpreadHelperScript.build_profile(
		player,
		current_weapon_data,
		caliber,
		current_spread,
		burst_pair_tight
	)
	var bullet_spread := float(spread_profile.get("bullet_spread_deg", current_spread))
	var pellet_spread := float(spread_profile.get("pellet_spread_deg", 0.0))
	var origin := camera.global_position
	var forward := -camera.global_basis.z
	var up := camera.global_basis.y
	var directions := Ballistics.calculate_spread_directions(
		forward,
		up,
		caliber.pellet_count,
		pellet_spread,
		bullet_spread
	)

	current_ammo -= 1
	_time_since_last_shot = 0.0

	for hit in _shot_resolver.perform_hitscan(origin, directions, caliber):
		hit_registered.emit(
			float(hit.get("distance", 0.0)),
			float(hit.get("damage", 0.0)),
			str(hit.get("target_name", ""))
		)

	var v_recoil := current_weapon_data.get_effective_recoil_vertical()
	var h_recoil := randf_range(
		-current_weapon_data.get_effective_recoil_horizontal(),
		current_weapon_data.get_effective_recoil_horizontal()
	)
	if burst_pair_tight:
		v_recoil *= current_weapon_data.burst_compensation_recoil_mult
		h_recoil *= current_weapon_data.burst_compensation_recoil_mult
	player.apply_recoil(v_recoil, h_recoil)

	var spread_add := current_weapon_data.spread_increase_per_shot
	if burst_pair_tight:
		spread_add *= current_weapon_data.burst_compensation_spread_mult
	current_spread = minf(current_spread + spread_add, current_weapon_data.max_spread)

	var schedule_delayed := false
	if get_current_fire_mode() == WeaponResource.FireMode.BURST:
		if (
			current_weapon_data.burst_compensation_shots > 0
			and current_weapon_data.burst_delayed_recoil_delay_sec > 0.0
			and current_weapon_data.burst_delayed_recoil_impulse_strength > 0.0
			and _burst_volley_shot_index == current_weapon_data.burst_count - 1
		):
			schedule_delayed = true
		_burst_volley_shot_index += 1

	ammo_changed.emit(current_ammo, current_weapon_data.magazine_size)
	weapon_fired.emit(caliber, directions, origin)

	if schedule_delayed:
		_schedule_burst_delayed_recoil()


func _process_burst(delta: float) -> void:
	if _burst_remaining <= 0 or not current_weapon_data:
		return
	_burst_timer += delta
	var interval := current_weapon_data.get_seconds_between_shots()
	if _burst_timer >= interval:
		_burst_timer -= interval
		_burst_remaining -= 1
		_fire_single_round()


func _process_reload(delta: float) -> void:
	if not _is_reloading or not current_weapon_data:
		return
	_reload_timer -= delta
	if _reload_timer > 0.0:
		return

	if _reload_continue_incremental and current_weapon_data.per_shell_reload_time > 0.0:
		_reload_continue_incremental = false
		if current_ammo >= current_weapon_data.magazine_size:
			_stop_reload_state()
		else:
			_reload_incremental = true
			current_ammo = mini(current_ammo + 1, current_weapon_data.magazine_size)
			ammo_changed.emit(current_ammo, current_weapon_data.magazine_size)
			if current_ammo >= current_weapon_data.magazine_size:
				_stop_reload_state()
			else:
				_reload_timer = current_weapon_data.per_shell_reload_time
		return

	if _reload_incremental and current_weapon_data.per_shell_reload_time > 0.0:
		current_ammo = mini(current_ammo + 1, current_weapon_data.magazine_size)
		ammo_changed.emit(current_ammo, current_weapon_data.magazine_size)
		if current_ammo >= current_weapon_data.magazine_size:
			_stop_reload_state()
		else:
			_reload_timer = current_weapon_data.per_shell_reload_time
	else:
		_stop_reload_state()
		current_ammo = current_weapon_data.magazine_size
		ammo_changed.emit(current_ammo, current_weapon_data.magazine_size)


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
			if ammo_wheel_index != current_caliber_index:
				current_caliber_index = ammo_wheel_index
				caliber_changed.emit(get_current_caliber())
				_start_caliber_swap_reload()
		elif _is_reloading:
			_stop_reload_state()
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


func _update_spread(delta: float) -> void:
	if not current_weapon_data:
		return
	if _time_since_last_shot > 0.1:
		current_spread = move_toward(
			current_spread,
			current_weapon_data.base_spread,
			current_weapon_data.spread_recovery_rate * delta
		)


func _snapshot_current_weapon() -> Dictionary:
	return {
		"fire_mode_index": current_fire_mode_index,
		"caliber_index": current_caliber_index,
		"ammo": current_ammo,
		"spread": current_spread,
		"is_reloading": _is_reloading,
		"reload_timer": _reload_timer,
		"reload_incremental": _reload_incremental,
		"reload_continue_incremental": _reload_continue_incremental,
	}


func _persist_current_weapon_if_any() -> void:
	if weapons.is_empty() or current_weapon_data == null:
		return
	_weapon_snapshots[current_weapon_index] = _snapshot_current_weapon()


func _apply_default_weapon_state() -> void:
	current_caliber_index = 0
	current_fire_mode_index = 0
	current_ammo = current_weapon_data.magazine_size
	current_spread = current_weapon_data.base_spread
	_stop_reload_state()
	_empty_dry_fire_streak = 0


func _restore_weapon_snapshot(s: Dictionary) -> void:
	var weapon := current_weapon_data
	if weapon.fire_modes.size() > 0:
		current_fire_mode_index = clampi(int(s.get("fire_mode_index", 0)), 0, weapon.fire_modes.size() - 1)
	else:
		current_fire_mode_index = 0
	if weapon.calibers.size() > 0:
		current_caliber_index = clampi(int(s.get("caliber_index", 0)), 0, weapon.calibers.size() - 1)
	else:
		current_caliber_index = 0
	current_ammo = clampi(int(s.get("ammo", weapon.magazine_size)), 0, weapon.magazine_size)
	current_spread = clampf(float(s.get("spread", weapon.base_spread)), weapon.base_spread, weapon.max_spread)
	_is_reloading = bool(s.get("is_reloading", false))
	_reload_timer = maxf(float(s.get("reload_timer", 0.0)), 0.0)
	_reload_incremental = bool(s.get("reload_incremental", false))
	_reload_continue_incremental = bool(s.get("reload_continue_incremental", false))
	if _is_reloading and _reload_timer <= 0.0:
		_stop_reload_state()


func _start_reload_timer(
	reload_time: float,
	incremental: bool,
	continue_incremental: bool = false
) -> void:
	_empty_dry_fire_streak = 0
	_is_reloading = true
	_reload_incremental = incremental
	_reload_continue_incremental = continue_incremental
	_reload_timer = reload_time
	reload_started.emit()


func _stop_reload_state() -> void:
	_is_reloading = false
	_reload_incremental = false
	_reload_continue_incremental = false
	_reload_timer = 0.0


func _start_caliber_swap_reload() -> void:
	if not current_weapon_data:
		return
	if current_weapon_data.per_shell_reload_time > 0.0:
		current_ammo = 0
		ammo_changed.emit(current_ammo, current_weapon_data.magazine_size)
		_start_reload_timer(current_weapon_data.per_shell_reload_time, true)
		return
	_start_reload_timer(current_weapon_data.reload_time, false)


func _try_cancel_shotgun_reload_for_fire() -> void:
	if not _is_reloading or not _reload_incremental:
		return
	if not current_weapon_data or current_weapon_data.per_shell_reload_time <= 0.0:
		return
	_stop_reload_state()
	ammo_changed.emit(current_ammo, current_weapon_data.magazine_size)


func _is_burst_compensation_active() -> bool:
	if not current_weapon_data:
		return false
	if get_current_fire_mode() != WeaponResource.FireMode.BURST:
		return false
	if current_weapon_data.burst_compensation_shots <= 0:
		return false
	return _burst_volley_shot_index < current_weapon_data.burst_compensation_shots


func _schedule_burst_delayed_recoil() -> void:
	var weapon := current_weapon_data
	if not weapon:
		return
	_burst_delayed_recoil_id += 1
	var recoil_id := _burst_delayed_recoil_id
	var delay := weapon.burst_delayed_recoil_delay_sec
	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(
		func() -> void:
			if not is_instance_valid(self) or not is_instance_valid(player):
				return
			if recoil_id != _burst_delayed_recoil_id:
				return
			if current_weapon_data != weapon:
				return
			var v := weapon.get_effective_recoil_vertical()
			var h_abs := weapon.get_effective_recoil_horizontal()
			var strength := weapon.burst_delayed_recoil_impulse_strength
			var horizontal_factor := weapon.burst_delayed_recoil_horizontal_factor
			player.apply_recoil(
				2.0 * v * strength,
				randf_range(-h_abs, h_abs) * 2.0 * strength * horizontal_factor
			)
	,
		Object.CONNECT_ONE_SHOT
	)


func _resolve_camera() -> Camera3D:
	if player and player.has_method("get_camera_3d"):
		return player.get_camera_3d()
	return get_node_or_null("../Head/Camera3D") as Camera3D
