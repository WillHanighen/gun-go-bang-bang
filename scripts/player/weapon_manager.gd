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
signal loadout_changed(loadout: Dictionary)

const MAX_DECALS := 200
const WHEEL_HOLD_THRESHOLD := 0.15
const WHEEL_DEADZONE := 15.0
const HAND_1 := &"hand_1"
const HAND_2 := &"hand_2"
const HAND_ORDER := [HAND_1, HAND_2]
const HAND_2_MODIFIER_KEY := KEY_ALT

var current_weapon_data: WeaponResource
var current_caliber_index := 0
var current_ammo := 0
var current_fire_mode_index := 0
var current_spread := 0.0

var active_loadout: Dictionary = {}
var _hand_states := {
	HAND_1: {},
	HAND_2: {},
}
## Per-item snapshots so akimbo duplicates keep separate state.
var _item_snapshots: Dictionary = {}

var ammo_wheel_open := false
var ammo_wheel_index := 0
var _ammo_wheel_hand: StringName = HAND_1
var _wheel_cursor := Vector2.ZERO
var _reload_key_held := false
var _reload_hold_time := 0.0
var _last_fired_hand: StringName = HAND_1

@onready var player: CharacterBody3D = get_parent() as CharacterBody3D
@onready var inventory: PlayerInventory = player.get_node_or_null("PlayerInventory") as PlayerInventory

var _camera: Camera3D
var _decal_pool
var _shot_resolver


func _ready() -> void:
	for hand in HAND_ORDER:
		_hand_states[hand] = _make_empty_hand_state()

	_camera = _resolve_camera()
	var decal_parent := player.get_parent() if player and player.get_parent() else player
	var decal_pool_script: Script = WeaponDecalPoolScript
	_decal_pool = decal_pool_script.new()
	_decal_pool.setup(decal_parent, MAX_DECALS)
	if player:
		var shot_resolver_script: Script = WeaponShotResolverScript
		_shot_resolver = shot_resolver_script.new()
		_shot_resolver.setup(player.get_world_3d(), _decal_pool)

	if inventory:
		inventory.active_loadout_changed.connect(_on_active_loadout_changed)
		_on_active_loadout_changed(inventory.get_active_loadout())


func _process(delta: float) -> void:
	_update_spread(delta)
	_process_reload(delta)
	_process_ammo_wheel(delta)
	_handle_input()
	_process_burst(delta)


func get_player_camera() -> Camera3D:
	if not _camera:
		_camera = _resolve_camera()
	return _camera


func get_loadout() -> Dictionary:
	return active_loadout.duplicate(true)


func get_hand_weapon(hand: StringName) -> WeaponResource:
	var state := _get_hand_state(hand)
	return state.get("weapon") as WeaponResource


func get_hand_ammo(hand: StringName) -> int:
	var state := _get_hand_state(hand)
	return int(state.get("ammo", 0))


func is_hand_reloading(hand: StringName) -> bool:
	var state := _get_hand_state(hand)
	return bool(state.get("is_reloading", false))


func get_hand_max_ammo(hand: StringName) -> int:
	var weapon := get_hand_weapon(hand)
	return weapon.magazine_size if weapon else 0


func get_hand_fire_mode(hand: StringName) -> WeaponResource.FireMode:
	var state := _get_hand_state(hand)
	var weapon := state.get("weapon") as WeaponResource
	if not weapon or weapon.fire_modes.is_empty():
		return WeaponResource.FireMode.SEMI
	var mode_index := clampi(int(state.get("fire_mode_index", 0)), 0, weapon.fire_modes.size() - 1)
	return weapon.fire_modes[mode_index]


func get_hand_caliber(hand: StringName) -> CaliberResource:
	var state := _get_hand_state(hand)
	var weapon := state.get("weapon") as WeaponResource
	if not weapon or weapon.calibers.is_empty():
		return null
	var caliber_index := clampi(int(state.get("caliber_index", 0)), 0, weapon.calibers.size() - 1)
	return weapon.calibers[caliber_index]


func get_hand_caliber_index(hand: StringName) -> int:
	var state := _get_hand_state(hand)
	return int(state.get("caliber_index", 0))


func get_ads_weapon() -> WeaponResource:
	return get_hand_weapon(HAND_1)


func can_aim() -> bool:
	if not get_hand_weapon(HAND_1):
		return false
	return _get_hand_entry(HAND_2).is_empty()


func get_ammo_wheel_hand() -> StringName:
	return _ammo_wheel_hand


func get_last_fired_hand() -> StringName:
	return _last_fired_hand


func get_crosshair_spread_degrees() -> float:
	var max_spread := 0.0
	for hand in HAND_ORDER:
		max_spread = maxf(max_spread, get_hand_crosshair_spread_degrees(hand))
	return max_spread


func get_hand_crosshair_spread_degrees(hand: StringName) -> float:
	var state := _get_hand_state(hand)
	var weapon := state.get("weapon") as WeaponResource
	if not weapon:
		return 0.0
	var profile := WeaponSpreadHelperScript.build_profile(
		player,
		weapon,
		get_hand_caliber(hand),
		float(state.get("spread", weapon.base_spread)),
		_is_burst_compensation_active(hand),
		_get_hand_spread_multiplier(hand)
	)
	return float(profile.get("crosshair_spread_deg", 0.0))


func get_crosshair_pixels(viewport_size: Vector2) -> float:
	return WeaponSpreadHelperScript.get_crosshair_pixels(
		get_player_camera(),
		viewport_size,
		get_crosshair_spread_degrees()
	)


func add_weapon(weapon: WeaponResource, auto_equip: bool = true) -> int:
	if not inventory:
		return -1
	return inventory.add_weapon(weapon, auto_equip)


func equip_weapon(index: int) -> void:
	if not inventory:
		return
	var slot_order := inventory.get_slot_order()
	if index < 0 or index >= slot_order.size():
		return
	inventory.set_active_slot(StringName(slot_order[index]))


func get_current_fire_mode() -> WeaponResource.FireMode:
	return get_hand_fire_mode(HAND_1)


func get_current_caliber() -> CaliberResource:
	return get_hand_caliber(HAND_1)


func cycle_fire_mode(hand: StringName = HAND_1) -> void:
	var state := _get_hand_state(hand)
	var weapon := state.get("weapon") as WeaponResource
	if not weapon or weapon.fire_modes.is_empty():
		return
	state["fire_mode_index"] = (int(state.get("fire_mode_index", 0)) + 1) % weapon.fire_modes.size()
	_store_hand_state(hand, state)
	if hand == HAND_1:
		fire_mode_changed.emit(get_current_fire_mode())
	_emit_loadout_changed()


func cycle_ammo(hand: StringName = HAND_1) -> void:
	var state := _get_hand_state(hand)
	var weapon := state.get("weapon") as WeaponResource
	if not weapon or weapon.calibers.size() <= 1:
		return
	state["caliber_index"] = (int(state.get("caliber_index", 0)) + 1) % weapon.calibers.size()
	_store_hand_state(hand, state)
	if hand == HAND_1:
		ammo_wheel_index = int(state.get("caliber_index", 0))
		caliber_changed.emit(get_current_caliber())
	_emit_loadout_changed()
	_start_caliber_swap_reload(hand)


func start_reload(hand: StringName = HAND_1) -> void:
	var state := _get_hand_state(hand)
	var weapon := state.get("weapon") as WeaponResource
	if not weapon or bool(state.get("is_reloading", false)):
		return
	if int(state.get("ammo", 0)) >= weapon.magazine_size:
		return
	var is_incremental := weapon.per_shell_reload_time > 0.0
	var reload_time := (
		weapon.per_shell_reload_time
		if is_incremental
		else weapon.reload_time
	)
	_start_reload_timer(hand, reload_time, is_incremental)


func feed_wheel_mouse(delta: Vector2) -> void:
	_wheel_cursor += delta


func _handle_input() -> void:
	if inventory and inventory.inventory_open:
		return

	if inventory:
		if Input.is_action_just_pressed("next_weapon"):
			inventory.cycle_active_slot(1)
		if Input.is_action_just_pressed("prev_weapon"):
			inventory.cycle_active_slot(-1)
		if Input.is_action_just_pressed("equip_slot_1"):
			equip_weapon(0)
		if Input.is_action_just_pressed("equip_slot_2"):
			equip_weapon(1)
		if Input.is_action_just_pressed("equip_slot_3"):
			equip_weapon(2)

	if Input.is_action_just_pressed("switch_fire_mode"):
		cycle_fire_mode(_get_modified_hand())

	if Input.is_action_just_pressed("switch_ammo"):
		cycle_ammo(_get_modified_hand())

	if ammo_wheel_open:
		return

	if Input.is_action_just_pressed("fire"):
		_try_cancel_shotgun_reload_for_fire(HAND_1)
		_try_fire(HAND_1)
	elif Input.is_action_pressed("fire") and get_hand_fire_mode(HAND_1) == WeaponResource.FireMode.AUTO:
		_try_cancel_shotgun_reload_for_fire(HAND_1)
		_try_fire(HAND_1)

	if Input.is_action_just_pressed("fire_hand_2"):
		_try_cancel_shotgun_reload_for_fire(HAND_2)
		_try_fire(HAND_2)
	elif Input.is_action_pressed("fire_hand_2") and get_hand_fire_mode(HAND_2) == WeaponResource.FireMode.AUTO:
		_try_cancel_shotgun_reload_for_fire(HAND_2)
		_try_fire(HAND_2)


func _try_fire(hand: StringName) -> void:
	var state := _get_hand_state(hand)
	var weapon := state.get("weapon") as WeaponResource
	if not weapon:
		return
	if bool(state.get("is_reloading", false)):
		return
	if int(state.get("ammo", 0)) <= 0:
		state["empty_dry_fire_streak"] = int(state.get("empty_dry_fire_streak", 0)) + 1
		if int(state.get("empty_dry_fire_streak", 0)) >= 2:
			state["empty_dry_fire_streak"] = 0
			_store_hand_state(hand, state)
			start_reload(hand)
		else:
			_store_hand_state(hand, state)
		return
	state["empty_dry_fire_streak"] = 0
	if float(state.get("time_since_last_shot", 999.0)) < weapon.get_seconds_between_shots():
		return
	if int(state.get("burst_remaining", 0)) > 0:
		return

	var mode := get_hand_fire_mode(hand)
	if mode == WeaponResource.FireMode.BURST:
		state["burst_remaining"] = weapon.burst_count - 1
		state["burst_timer"] = 0.0
		state["burst_volley_shot_index"] = 0
	_store_hand_state(hand, state)
	_fire_single_round(hand)


func _fire_single_round(hand: StringName) -> void:
	var state := _get_hand_state(hand)
	var weapon := state.get("weapon") as WeaponResource
	var ammo := int(state.get("ammo", 0))
	if ammo <= 0 or not weapon:
		return

	var caliber := get_hand_caliber(hand)
	var camera := get_player_camera()
	if not caliber or not camera or not _shot_resolver:
		return

	var burst_pair_tight := _is_burst_compensation_active(hand)
	var spread_multiplier := _get_hand_spread_multiplier(hand)
	var spread_profile := WeaponSpreadHelperScript.build_profile(
		player,
		weapon,
		caliber,
		float(state.get("spread", weapon.base_spread)),
		burst_pair_tight,
		spread_multiplier
	)
	var bullet_spread := float(spread_profile.get("bullet_spread_deg", float(state.get("spread", weapon.base_spread))))
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

	_last_fired_hand = hand
	state["ammo"] = ammo - 1
	state["time_since_last_shot"] = 0.0

	for hit in _shot_resolver.perform_hitscan(origin, directions, caliber):
		hit_registered.emit(
			float(hit.get("distance", 0.0)),
			float(hit.get("damage", 0.0)),
			str(hit.get("target_name", ""))
		)

	var recoil_multiplier := _get_hand_recoil_multiplier(hand)
	var v_recoil := weapon.get_effective_recoil_vertical()
	var h_recoil := randf_range(
		-weapon.get_effective_recoil_horizontal(),
		weapon.get_effective_recoil_horizontal()
	)
	if burst_pair_tight:
		v_recoil *= weapon.burst_compensation_recoil_mult
		h_recoil *= weapon.burst_compensation_recoil_mult
	player.apply_recoil(v_recoil * recoil_multiplier, h_recoil * recoil_multiplier)

	var spread_add := weapon.spread_increase_per_shot * spread_multiplier
	if burst_pair_tight:
		spread_add *= weapon.burst_compensation_spread_mult
	state["spread"] = minf(float(state.get("spread", weapon.base_spread)) + spread_add, weapon.max_spread)

	var schedule_delayed := false
	if get_hand_fire_mode(hand) == WeaponResource.FireMode.BURST:
		if (
			weapon.burst_compensation_shots > 0
			and weapon.burst_delayed_recoil_delay_sec > 0.0
			and weapon.burst_delayed_recoil_impulse_strength > 0.0
			and int(state.get("burst_volley_shot_index", 0)) == weapon.burst_count - 1
		):
			schedule_delayed = true
		state["burst_volley_shot_index"] = int(state.get("burst_volley_shot_index", 0)) + 1

	_store_hand_state(hand, state)
	if hand == HAND_1:
		ammo_changed.emit(get_hand_ammo(HAND_1), weapon.magazine_size)
	_emit_loadout_changed()
	weapon_fired.emit(caliber, directions, origin)

	if schedule_delayed:
		_schedule_burst_delayed_recoil(hand)


func _process_burst(delta: float) -> void:
	for hand in HAND_ORDER:
		var state := _get_hand_state(hand)
		var weapon := state.get("weapon") as WeaponResource
		if not weapon or int(state.get("burst_remaining", 0)) <= 0:
			continue
		state["burst_timer"] = float(state.get("burst_timer", 0.0)) + delta
		var interval := weapon.get_seconds_between_shots()
		if float(state.get("burst_timer", 0.0)) < interval:
			_store_hand_state(hand, state)
			continue
		state["burst_timer"] = float(state.get("burst_timer", 0.0)) - interval
		state["burst_remaining"] = int(state.get("burst_remaining", 0)) - 1
		_store_hand_state(hand, state)
		_fire_single_round(hand)


func _process_reload(delta: float) -> void:
	for hand in HAND_ORDER:
		var state := _get_hand_state(hand)
		var weapon := state.get("weapon") as WeaponResource
		if not weapon or not bool(state.get("is_reloading", false)):
			continue
		state["reload_timer"] = float(state.get("reload_timer", 0.0)) - delta
		if float(state.get("reload_timer", 0.0)) > 0.0:
			_store_hand_state(hand, state)
			continue

		if bool(state.get("reload_continue_incremental", false)) and weapon.per_shell_reload_time > 0.0:
			state["reload_continue_incremental"] = false
			if int(state.get("ammo", 0)) >= weapon.magazine_size:
				_stop_reload_state(hand, state)
			else:
				state["reload_incremental"] = true
				state["ammo"] = mini(int(state.get("ammo", 0)) + 1, weapon.magazine_size)
				if int(state.get("ammo", 0)) >= weapon.magazine_size:
					_stop_reload_state(hand, state)
				else:
					state["reload_timer"] = weapon.per_shell_reload_time
			_store_hand_state(hand, state)
			_emit_ammo_refresh_for_hand(hand)
			continue

		if bool(state.get("reload_incremental", false)) and weapon.per_shell_reload_time > 0.0:
			state["ammo"] = mini(int(state.get("ammo", 0)) + 1, weapon.magazine_size)
			if int(state.get("ammo", 0)) >= weapon.magazine_size:
				_stop_reload_state(hand, state)
			else:
				state["reload_timer"] = weapon.per_shell_reload_time
		else:
			_stop_reload_state(hand, state)
			state["ammo"] = weapon.magazine_size

		_store_hand_state(hand, state)
		_emit_ammo_refresh_for_hand(hand)


func _process_ammo_wheel(delta: float) -> void:
	if inventory and inventory.inventory_open:
		ammo_wheel_open = false
		_reload_key_held = false
		return

	var wheel_state := _get_hand_state(_ammo_wheel_hand)
	var wheel_weapon := wheel_state.get("weapon") as WeaponResource
	if not wheel_weapon and ammo_wheel_open:
		ammo_wheel_open = false
	if Input.is_action_just_pressed("reload"):
		_reload_key_held = true
		_reload_hold_time = 0.0
		_wheel_cursor = Vector2.ZERO
		_ammo_wheel_hand = _get_modified_hand()
		var state := _get_hand_state(_ammo_wheel_hand)
		ammo_wheel_index = int(state.get("caliber_index", 0))

	if _reload_key_held:
		var state := _get_hand_state(_ammo_wheel_hand)
		var weapon := state.get("weapon") as WeaponResource
		if not weapon:
			_reload_key_held = false
			ammo_wheel_open = false
			return
		_reload_hold_time += delta
		var has_options := weapon.calibers.size() > 1
		if _reload_hold_time >= WHEEL_HOLD_THRESHOLD and has_options:
			ammo_wheel_open = true
			_update_wheel_selection()

	if Input.is_action_just_released("reload"):
		_reload_key_held = false
		var state := _get_hand_state(_ammo_wheel_hand)
		var weapon := state.get("weapon") as WeaponResource
		if not weapon:
			ammo_wheel_open = false
			return
		if ammo_wheel_open:
			ammo_wheel_open = false
			if ammo_wheel_index != int(state.get("caliber_index", 0)):
				state["caliber_index"] = ammo_wheel_index
				_store_hand_state(_ammo_wheel_hand, state)
				if _ammo_wheel_hand == HAND_1:
					caliber_changed.emit(get_current_caliber())
				_emit_loadout_changed()
				_start_caliber_swap_reload(_ammo_wheel_hand)
		elif bool(state.get("is_reloading", false)):
			_stop_reload_state(_ammo_wheel_hand, state)
			_store_hand_state(_ammo_wheel_hand, state)
			_emit_ammo_refresh_for_hand(_ammo_wheel_hand)
		else:
			start_reload(_ammo_wheel_hand)


func _update_wheel_selection() -> void:
	var state := _get_hand_state(_ammo_wheel_hand)
	var weapon := state.get("weapon") as WeaponResource
	if not weapon:
		return
	var count := weapon.calibers.size()
	if count <= 1:
		ammo_wheel_index = 0
		return
	if _wheel_cursor.length() < WHEEL_DEADZONE:
		ammo_wheel_index = int(state.get("caliber_index", 0))
		return
	var angle := atan2(_wheel_cursor.x, -_wheel_cursor.y)
	var adjusted := fmod(angle + TAU, TAU)
	ammo_wheel_index = int(adjusted / (TAU / float(count))) % count


func _update_spread(delta: float) -> void:
	for hand in HAND_ORDER:
		var state := _get_hand_state(hand)
		var weapon := state.get("weapon") as WeaponResource
		if not weapon:
			continue
		state["time_since_last_shot"] = float(state.get("time_since_last_shot", 999.0)) + delta
		if float(state.get("time_since_last_shot", 999.0)) > 0.1:
			state["spread"] = move_toward(
				float(state.get("spread", weapon.base_spread)),
				weapon.base_spread,
				weapon.spread_recovery_rate * delta
			)
		_store_hand_state(hand, state)


func _snapshot_hand_state(state: Dictionary) -> Dictionary:
	return {
		"fire_mode_index": int(state.get("fire_mode_index", 0)),
		"caliber_index": int(state.get("caliber_index", 0)),
		"ammo": int(state.get("ammo", 0)),
		"is_reloading": bool(state.get("is_reloading", false)),
		"reload_timer": float(state.get("reload_timer", 0.0)),
		"reload_incremental": bool(state.get("reload_incremental", false)),
		"reload_continue_incremental": bool(state.get("reload_continue_incremental", false)),
	}


func _persist_hand_snapshot(hand: StringName) -> void:
	var state := _get_hand_state(hand)
	if state.is_empty():
		return
	var item_id := int(state.get("id", -1))
	if item_id < 0 or state.get("weapon") == null:
		return
	_item_snapshots[item_id] = _snapshot_hand_state(state)


func _apply_default_hand_state(hand: StringName, item_id: int, weapon: WeaponResource) -> void:
	var state := _make_empty_hand_state()
	state["id"] = item_id
	state["weapon"] = weapon
	state["ammo"] = weapon.magazine_size
	state["spread"] = weapon.base_spread
	_store_hand_state(hand, state)


func _restore_hand_snapshot(hand: StringName, item_id: int, weapon: WeaponResource, snapshot: Dictionary) -> void:
	var state := _make_empty_hand_state()
	state["id"] = item_id
	state["weapon"] = weapon
	if weapon.fire_modes.size() > 0:
		state["fire_mode_index"] = clampi(int(snapshot.get("fire_mode_index", 0)), 0, weapon.fire_modes.size() - 1)
	if weapon.calibers.size() > 0:
		state["caliber_index"] = clampi(int(snapshot.get("caliber_index", 0)), 0, weapon.calibers.size() - 1)
	state["ammo"] = clampi(int(snapshot.get("ammo", weapon.magazine_size)), 0, weapon.magazine_size)
	state["spread"] = weapon.base_spread
	state["is_reloading"] = bool(snapshot.get("is_reloading", false))
	state["reload_timer"] = maxf(float(snapshot.get("reload_timer", 0.0)), 0.0)
	state["reload_incremental"] = bool(snapshot.get("reload_incremental", false))
	state["reload_continue_incremental"] = bool(snapshot.get("reload_continue_incremental", false))
	if bool(state.get("is_reloading", false)) and float(state.get("reload_timer", 0.0)) <= 0.0:
		_stop_reload_state(hand, state)
	_store_hand_state(hand, state)


func _start_reload_timer(
	hand: StringName,
	reload_time: float,
	incremental: bool,
	continue_incremental: bool = false
) -> void:
	var state := _get_hand_state(hand)
	state["empty_dry_fire_streak"] = 0
	state["is_reloading"] = true
	state["reload_incremental"] = incremental
	state["reload_continue_incremental"] = continue_incremental
	state["reload_timer"] = reload_time
	_store_hand_state(hand, state)
	reload_started.emit()
	_emit_loadout_changed()


func _stop_reload_state(_hand: StringName, state: Dictionary) -> void:
	state["is_reloading"] = false
	state["reload_incremental"] = false
	state["reload_continue_incremental"] = false
	state["reload_timer"] = 0.0


func _start_caliber_swap_reload(hand: StringName) -> void:
	var state := _get_hand_state(hand)
	var weapon := state.get("weapon") as WeaponResource
	if not weapon:
		return
	if weapon.per_shell_reload_time > 0.0:
		state["ammo"] = 0
		_store_hand_state(hand, state)
		_emit_ammo_refresh_for_hand(hand)
		_start_reload_timer(hand, weapon.per_shell_reload_time, true)
		return
	_start_reload_timer(hand, weapon.reload_time, false)


func _try_cancel_shotgun_reload_for_fire(hand: StringName) -> void:
	var state := _get_hand_state(hand)
	var weapon := state.get("weapon") as WeaponResource
	if not bool(state.get("is_reloading", false)) or not bool(state.get("reload_incremental", false)):
		return
	if not weapon or weapon.per_shell_reload_time <= 0.0:
		return
	_stop_reload_state(hand, state)
	_store_hand_state(hand, state)
	_emit_ammo_refresh_for_hand(hand)


func _is_burst_compensation_active(hand: StringName) -> bool:
	var state := _get_hand_state(hand)
	var weapon := state.get("weapon") as WeaponResource
	if not weapon:
		return false
	if get_hand_fire_mode(hand) != WeaponResource.FireMode.BURST:
		return false
	if weapon.burst_compensation_shots <= 0:
		return false
	return int(state.get("burst_volley_shot_index", 0)) < weapon.burst_compensation_shots


func _schedule_burst_delayed_recoil(hand: StringName) -> void:
	var state := _get_hand_state(hand)
	var weapon := state.get("weapon") as WeaponResource
	if not weapon:
		return
	state["burst_delayed_recoil_id"] = int(state.get("burst_delayed_recoil_id", 0)) + 1
	var recoil_id := int(state.get("burst_delayed_recoil_id", 0))
	var item_id := int(state.get("id", -1))
	_store_hand_state(hand, state)
	var delay := weapon.burst_delayed_recoil_delay_sec
	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(
		func() -> void:
			if not is_instance_valid(self) or not is_instance_valid(player):
				return
			var current_state := _get_hand_state(hand)
			if int(current_state.get("burst_delayed_recoil_id", -1)) != recoil_id:
				return
			if int(current_state.get("id", -1)) != item_id:
				return
			var v := weapon.get_effective_recoil_vertical()
			var h_abs := weapon.get_effective_recoil_horizontal()
			var strength := weapon.burst_delayed_recoil_impulse_strength
			var horizontal_factor := weapon.burst_delayed_recoil_horizontal_factor
			player.apply_recoil(
				2.0 * v * strength * _get_hand_recoil_multiplier(hand),
				randf_range(-h_abs, h_abs) * 2.0 * strength * horizontal_factor * _get_hand_recoil_multiplier(hand)
			)
	,
		Object.CONNECT_ONE_SHOT
	)


func _on_active_loadout_changed(loadout: Dictionary) -> void:
	for hand in HAND_ORDER:
		_persist_hand_snapshot(hand)

	active_loadout = loadout.duplicate(true)
	ammo_wheel_open = false
	ammo_wheel_index = 0
	_ammo_wheel_hand = HAND_1
	_reload_key_held = false
	_reload_hold_time = 0.0
	_wheel_cursor = Vector2.ZERO

	for hand in HAND_ORDER:
		var hand_entry := _get_hand_entry(hand)
		if hand_entry.is_empty():
			_store_hand_state(hand, _make_empty_hand_state())
			continue
		var item_id := int(hand_entry.get("id", -1))
		var weapon := hand_entry.get("weapon") as WeaponResource
		if item_id < 0 or not weapon:
			_store_hand_state(hand, _make_empty_hand_state())
			continue
		if _item_snapshots.has(item_id):
			_restore_hand_snapshot(hand, item_id, weapon, _item_snapshots[item_id] as Dictionary)
		else:
			_apply_default_hand_state(hand, item_id, weapon)

	_sync_primary_aliases()
	ammo_wheel_index = current_caliber_index
	weapon_changed.emit(current_weapon_data)
	fire_mode_changed.emit(get_current_fire_mode())
	ammo_changed.emit(current_ammo, current_weapon_data.magazine_size if current_weapon_data else 0)
	caliber_changed.emit(get_current_caliber())
	_emit_loadout_changed()


func _emit_loadout_changed() -> void:
	loadout_changed.emit(get_loadout())


func _emit_ammo_refresh_for_hand(hand: StringName) -> void:
	var weapon := get_hand_weapon(hand)
	if hand == HAND_1:
		ammo_changed.emit(get_hand_ammo(HAND_1), weapon.magazine_size if weapon else 0)
	_emit_loadout_changed()


func _get_hand_state(hand: StringName) -> Dictionary:
	return (_hand_states.get(hand, {}) as Dictionary).duplicate()


func _store_hand_state(hand: StringName, state: Dictionary) -> void:
	_hand_states[hand] = state.duplicate(true)
	if hand == HAND_1:
		_sync_primary_aliases()


func _sync_primary_aliases() -> void:
	var primary_state := _hand_states.get(HAND_1, {}) as Dictionary
	current_weapon_data = primary_state.get("weapon") as WeaponResource
	current_caliber_index = int(primary_state.get("caliber_index", 0))
	current_ammo = int(primary_state.get("ammo", 0))
	current_fire_mode_index = int(primary_state.get("fire_mode_index", 0))
	current_spread = float(primary_state.get("spread", 0.0))


func _get_hand_entry(hand: StringName) -> Dictionary:
	return active_loadout.get(hand, {}) as Dictionary


func _get_hand_spread_multiplier(hand: StringName) -> float:
	var hand_entry := _get_hand_entry(hand)
	if hand_entry.is_empty():
		return 1.0
	var weapon := hand_entry.get("weapon") as WeaponResource
	if not weapon:
		return 1.0
	return weapon.get_spread_multiplier(
		bool(hand_entry.get("is_offhand", false)),
		bool(hand_entry.get("has_support_hand", false))
	)


func _get_hand_recoil_multiplier(hand: StringName) -> float:
	var hand_entry := _get_hand_entry(hand)
	if hand_entry.is_empty():
		return 1.0
	var weapon := hand_entry.get("weapon") as WeaponResource
	if not weapon:
		return 1.0
	return weapon.get_recoil_multiplier(
		bool(hand_entry.get("is_offhand", false)),
		bool(hand_entry.get("has_support_hand", false))
	)


func _get_modified_hand() -> StringName:
	return HAND_2 if Input.is_key_pressed(HAND_2_MODIFIER_KEY) else HAND_1


func _make_empty_hand_state() -> Dictionary:
	return {
		"id": -1,
		"weapon": null,
		"caliber_index": 0,
		"ammo": 0,
		"fire_mode_index": 0,
		"spread": 0.0,
		"time_since_last_shot": 999.0,
		"burst_remaining": 0,
		"burst_timer": 0.0,
		"burst_volley_shot_index": 0,
		"burst_delayed_recoil_id": 0,
		"is_reloading": false,
		"reload_timer": 0.0,
		"reload_incremental": false,
		"reload_continue_incremental": false,
		"empty_dry_fire_streak": 0,
	}


func _resolve_camera() -> Camera3D:
	if player and player.has_method("get_camera_3d"):
		return player.get_camera_3d()
	return get_node_or_null("../Head/Camera3D") as Camera3D
