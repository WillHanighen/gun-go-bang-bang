extends CharacterBody3D

const SPEED := 5.5
const SPRINT_SPEED := 8.75
const CROUCH_SPEED_MULT := 0.65
const ADS_SPEED := 3.15
const JUMP_VELOCITY := 5.0

const GROUND_ACCEL := 22.0
const GROUND_DECEL := 26.0
const AIR_ACCEL := 6.0
const AIR_DECEL := 14.0

const STANDING_HEAD_Y := 0.7
const CROUCH_HEAD_Y := 0.38
const STANDING_CAPSULE_CYLINDER_H := 1.8
const CROUCH_CAPSULE_CYLINDER_H := 0.45
const CROUCH_TRANSITION_SPEED := 10.0

const MOUSE_SENSITIVITY := 0.002
const ADS_SENSITIVITY_MULT := 0.7
const ADS_RECOIL_MULT := 0.65

const DEFAULT_FOV := 75.0
const ADS_FOV := 50.0
const ADS_FOV_RATIO := ADS_FOV / DEFAULT_FOV

const RECOIL_RECOVERY_FRACTION := 0.55
const RECOIL_IMPACT_MULT := 1.75

const MOVE_SPREAD_WALK_MAX := 1.32
const MOVE_SPREAD_SPRINT_MAX := 1.52
const INTERACTION_RAY_LENGTH := 6.0
const INTERACTION_COLLISION_MASK := 16
const PlayerVitalsScript := preload("res://scripts/player/player_vitals.gd")

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var weapon_manager: Node = $WeaponManager
@onready var inventory: PlayerInventory = $PlayerInventory
@onready var collision_shape: CollisionShape3D = _resolve_collision_shape()

signal interaction_prompt_changed(prompt: String)
signal player_died(reason: String)

var is_aiming := false
var is_sprinting := false
var _ads_progress := 0.0
var _sprint_spread := 0.0
var _walk_spread := 0.0
var _air_spread := 0.0
var _crouch_progress := 0.0
var _foot_capsule_offset := 0.0
var _capsule_radius := 0.3
var _recoil_v_recover := 0.0
var _recoil_h_recover := 0.0
var _interaction_target: Node
var _interaction_prompt := ""
var vitals


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_ensure_vitals()
	floor_snap_length = 0.25
	var cap := _get_capsule_shape()
	if cap:
		_capsule_radius = cap.radius
		var total := cap.height + 2.0 * _capsule_radius
		_foot_capsule_offset = collision_shape.position.y - total * 0.5


func _process(delta: float) -> void:
	if vitals and vitals.dead:
		_set_interaction_target(null)
		return
	var inventory_open := inventory != null and inventory.inventory_open
	is_aiming = (
		not inventory_open
		and Input.is_action_pressed("aim")
		and weapon_manager
		and weapon_manager.can_aim()
		and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)

	var ads_time := 0.25
	var ads_weapon: WeaponResource = weapon_manager.get_ads_weapon() if weapon_manager else null
	if ads_weapon:
		ads_time = ads_weapon.ads_time
	var ads_speed := (1.0 / ads_time) if ads_time > 0.0 else 20.0

	if is_aiming:
		_ads_progress = minf(_ads_progress + ads_speed * delta, 1.0)
	else:
		_ads_progress = maxf(_ads_progress - ads_speed * delta, 0.0)

	var t := _ads_progress * _ads_progress * (3.0 - 2.0 * _ads_progress)
	var hip_fov: float = GameSettings.field_of_view
	var ads_fov: float = hip_fov * ADS_FOV_RATIO
	camera.fov = lerpf(hip_fov, ads_fov, t)
	if inventory_open:
		_set_interaction_target(null)
	else:
		_update_interaction_target()

	if (
		not inventory_open
		and Input.is_action_just_pressed("interact")
		and _interaction_target
		and _interaction_target.has_method("pick_up")
	):
		if bool(_interaction_target.call("pick_up", self)):
			_set_interaction_target(null)


func _unhandled_input(event: InputEvent) -> void:
	if vitals and vitals.dead:
		return
	if event.is_action_pressed("toggleInventory") and inventory:
		if event is InputEventKey and event.is_echo():
			return
		var next_open := not inventory.inventory_open
		inventory.set_inventory_open(next_open)
		Input.set_mouse_mode(
			Input.MOUSE_MODE_VISIBLE if next_open else Input.MOUSE_MODE_CAPTURED
		)
		if next_open:
			_set_interaction_target(null)
		return

	if inventory and inventory.inventory_open:
		if event.is_action_pressed("ui_cancel"):
			inventory.set_inventory_open(false)
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if weapon_manager.ammo_wheel_open:
			weapon_manager.feed_wheel_mouse(event.relative)
			return
		var sens: float = (
			MOUSE_SENSITIVITY
			* GameSettings.mouse_sensitivity_mult
			* lerpf(1.0, ADS_SENSITIVITY_MULT, _ads_progress)
		)
		var pitch_invert := -1.0 if GameSettings.invert_mouse_y else 1.0
		rotate_y(-event.relative.x * sens)
		head.rotate_x(-event.relative.y * sens * pitch_invert)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			var pause_menu: Node = get_tree().get_first_node_in_group("pause_menu")
			if pause_menu and pause_menu.has_method("request_pause"):
				pause_menu.call("request_pause")
		return


func _physics_process(delta: float) -> void:
	if vitals and vitals.dead:
		velocity.x = 0.0
		velocity.z = 0.0
		velocity += get_gravity() * delta
		move_and_slide()
		return
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var move_dir := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var jump_pressed := Input.is_action_just_pressed("jump")
	if inventory and inventory.inventory_open:
		input_dir = Vector2.ZERO
		move_dir = Vector3.ZERO
		jump_pressed = false
	var on_floor := is_on_floor()

	_update_crouch(delta, Input.is_action_pressed("crouch"))

	is_sprinting = (
		on_floor
		and _crouch_progress < 0.2
		and input_dir.length_squared() > 0.01
		and Input.is_action_pressed("sprint")
		and (not vitals or vitals.can_sprint())
	)
	if vitals:
		vitals.update_movement(delta, is_sprinting, input_dir.length())
	var current_speed := _get_current_speed()

	if on_floor:
		if jump_pressed:
			velocity.y = JUMP_VELOCITY
		_apply_ground_horizontal_move(delta, move_dir, current_speed)
	else:
		velocity += get_gravity() * delta
		_apply_air_horizontal_move(delta, move_dir, current_speed)

	move_and_slide()

	head.position.y = lerpf(STANDING_HEAD_Y, CROUCH_HEAD_Y, _crouch_progress)
	var on_floor_now := is_on_floor()
	_air_spread = lerpf(_air_spread, 0.0 if on_floor_now else 1.0, 10.0 * delta)
	_sprint_spread = lerpf(_sprint_spread, 1.0 if is_sprinting else 0.0, 6.0 * delta)

	var walk_target := 0.0
	if on_floor_now and move_dir.length_squared() > 0.01 and not is_sprinting:
		walk_target = 1.0
	_walk_spread = lerpf(_walk_spread, walk_target, 6.0 * delta)

	_recover_recoil(delta)


func _get_current_speed() -> float:
	var base_speed := SPRINT_SPEED if is_sprinting else SPEED
	base_speed *= lerpf(1.0, CROUCH_SPEED_MULT, _crouch_progress)
	return lerpf(base_speed, ADS_SPEED, _ads_progress)


func _update_crouch(delta: float, wants_crouch: bool) -> void:
	var crouch_target := 1.0 if wants_crouch else 0.0
	if crouch_target < 0.5 and not _can_stand():
		crouch_target = 1.0
	_crouch_progress = move_toward(_crouch_progress, crouch_target, CROUCH_TRANSITION_SPEED * delta)
	_apply_crouch_capsule()


func _apply_ground_horizontal_move(delta: float, direction: Vector3, move_speed: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var target := direction * move_speed
	var accel := GROUND_ACCEL if direction.length_squared() > 0.01 else GROUND_DECEL
	horizontal = horizontal.move_toward(target, accel * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _apply_air_horizontal_move(delta: float, direction: Vector3, move_speed: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var target := direction * move_speed
	var accel := AIR_ACCEL if direction.length_squared() > 0.01 else AIR_DECEL
	horizontal = horizontal.move_toward(target, accel * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func apply_recoil(vertical_deg: float, horizontal_deg: float) -> void:
	if vitals and vitals.dead:
		return
	var ads_recoil := lerpf(1.0, ADS_RECOIL_MULT, _ads_progress)
	var v := vertical_deg * RECOIL_IMPACT_MULT * ads_recoil
	var h := horizontal_deg * RECOIL_IMPACT_MULT * ads_recoil
	head.rotation.x += deg_to_rad(v)
	head.rotation.x = clampf(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	rotation.y += deg_to_rad(h)

	_recoil_v_recover += v * RECOIL_RECOVERY_FRACTION
	_recoil_h_recover += h * RECOIL_RECOVERY_FRACTION


func _recover_recoil(delta: float) -> void:
	var rate := 4.0
	var ads_weapon: WeaponResource = weapon_manager.get_ads_weapon() if weapon_manager else null
	if ads_weapon:
		rate = ads_weapon.recoil_recovery_rate

	var decay := 1.0 - exp(-rate * 0.15 * delta)

	if absf(_recoil_v_recover) > 0.01:
		var step := _recoil_v_recover * decay
		head.rotation.x -= deg_to_rad(step)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		_recoil_v_recover -= step
	else:
		_recoil_v_recover = 0.0

	if absf(_recoil_h_recover) > 0.01:
		var step := _recoil_h_recover * decay
		rotation.y -= deg_to_rad(step)
		_recoil_h_recover -= step
	else:
		_recoil_h_recover = 0.0


func _can_stand() -> bool:
	if _crouch_progress <= 0.01:
		return true
	var cap := _get_capsule_shape()
	if not cap:
		return true

	var previous_height := cap.height
	var previous_y := collision_shape.position.y
	cap.height = STANDING_CAPSULE_CYLINDER_H
	collision_shape.position.y = _collision_center_y_for_cylinder(STANDING_CAPSULE_CYLINDER_H)
	# Ignore normal floor contact here; we only want ceiling / wall obstruction.
	var blocked := test_move(global_transform, Vector3.ZERO, null, 0.0, false)
	cap.height = previous_height
	collision_shape.position.y = previous_y
	return not blocked


func _collision_center_y_for_cylinder(cyl_h: float) -> float:
	return _foot_capsule_offset + (cyl_h + 2.0 * _capsule_radius) * 0.5


func _apply_crouch_capsule() -> void:
	var cap := _get_capsule_shape()
	if not cap:
		return
	var cyl := lerpf(STANDING_CAPSULE_CYLINDER_H, CROUCH_CAPSULE_CYLINDER_H, _crouch_progress)
	cap.height = cyl
	collision_shape.position.y = _collision_center_y_for_cylinder(cyl)


func get_camera_3d() -> Camera3D:
	return camera


func get_spread_state() -> Dictionary:
	return {
		"ads_progress": _ads_progress,
		"walk_progress": _walk_spread,
		"sprint_progress": _sprint_spread,
		"air_progress": _air_spread,
		"crouch_progress": _crouch_progress,
		"walk_spread_mult": MOVE_SPREAD_WALK_MAX,
		"sprint_spread_mult": MOVE_SPREAD_SPRINT_MAX,
	}


func get_interaction_prompt() -> String:
	return _interaction_prompt


func take_damage(amount: float, _hit_position: Vector3 = global_position, _direction: Vector3 = Vector3.ZERO) -> void:
	if not vitals:
		_ensure_vitals()
	vitals.take_damage(amount, "damage")


func apply_infection(amount: float) -> void:
	if not vitals:
		_ensure_vitals()
	vitals.apply_infection(amount)


func reset_after_respawn() -> void:
	if not vitals:
		_ensure_vitals()
	vitals.reset_after_respawn(true)
	velocity = Vector3.ZERO


func _ensure_vitals() -> void:
	vitals = get_node_or_null("PlayerVitals")
	if not vitals:
		vitals = PlayerVitalsScript.new()
		vitals.name = "PlayerVitals"
		add_child(vitals)
	if not vitals.died.is_connected(_on_vitals_died):
		vitals.died.connect(_on_vitals_died)


func _on_vitals_died(reason: String) -> void:
	player_died.emit(reason)


func _update_interaction_target() -> void:
	if not camera:
		_set_interaction_target(null)
		return

	var origin := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(
		origin,
		origin + (-camera.global_basis.z) * INTERACTION_RAY_LENGTH
	)
	query.collision_mask = INTERACTION_COLLISION_MASK
	query.collide_with_bodies = false
	query.collide_with_areas = true
	query.exclude = [get_rid()]

	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		_set_interaction_target(null)
		return

	var pickup := hit.get("collider") as Node
	if (
		pickup
		and pickup.has_method("can_player_pick_up")
		and pickup.has_method("pick_up")
		and pickup.call("can_player_pick_up", origin)
	):
		_set_interaction_target(pickup)
		return

	_set_interaction_target(null)


func _set_interaction_target(target: Node) -> void:
	var next_prompt := ""
	if target:
		if target.has_method("get_prompt_text_for"):
			next_prompt = str(target.call("get_prompt_text_for", self))
		elif target.has_method("get_prompt_text"):
			next_prompt = str(target.call("get_prompt_text"))
	if _interaction_target == target and _interaction_prompt == next_prompt:
		return

	_interaction_target = target
	_interaction_prompt = next_prompt
	interaction_prompt_changed.emit(_interaction_prompt)


func _resolve_collision_shape() -> CollisionShape3D:
	var pill_collider := get_node_or_null("PillCollider") as CollisionShape3D
	if pill_collider:
		return pill_collider
	return get_node_or_null("CollisionShape3D") as CollisionShape3D


func _get_capsule_shape() -> CapsuleShape3D:
	if not collision_shape:
		return null
	return collision_shape.shape as CapsuleShape3D
