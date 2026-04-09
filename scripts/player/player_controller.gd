extends CharacterBody3D

const SPEED := 5.5
const SPRINT_SPEED := 9.5
const CROUCH_SPEED_MULT := 0.5
## Full ADS: closer to walk speed; penalty is milder than before.
const ADS_SPEED := 5.25
const STANDING_HEAD_Y := 0.7
const CROUCH_HEAD_Y := 0.38
const STANDING_CAPSULE_CYLINDER_H := 1.8
const CROUCH_CAPSULE_CYLINDER_H := 0.45
const JUMP_VELOCITY := 4.5
## Krunker-style slide: crouch at speed to boost and coast (hold crouch to ride it).
const SLIDE_ENTER_MIN_SPEED := 4.75
const SLIDE_MAX_SPEED := 15.0
const SLIDE_BOOST_MULT := 1.32
const SLIDE_FRICTION := 3.25
const SLIDE_STEER := 6.0
const SLIDE_END_SPEED := 2.4
## When horizontal speed exceeds walk/sprint/ADS cap, decay toward cap instead of snapping.
const OVERSPEED_STEER := 8.5
const MOMENTUM_DECAY_TO_CAP := 3.8
## No movement keys: bleed speed (stronger than decay-to-cap so you still stop).
const MOMENTUM_COAST_FRICTION := 11.0
## Push off the wall (horizontal) and up; away from wall normal.
const WALL_JUMP_UP := 3.5
const WALL_JUMP_OUT := 5.5
const WALL_PROBE_LEN := 0.58
const WALL_PROBE_HEIGHT := 0.65
## Source-style air accel (wish direction); stationary jump + W gains speed over a few frames.
const AIR_ACCEL := 42.0
const MOUSE_SENSITIVITY := 0.002
const ADS_SENSITIVITY_MULT := 0.7
## At full ADS, recoil is multiplied by this (hip fire = 1.0). 
## Matches spread tightening tier.
## Note: revamp later when grips and whatnot are customizable.
const ADS_RECOIL_MULT := 0.65

const DEFAULT_FOV := 75.0
const ADS_FOV := 50.0

const RECOIL_RECOVERY_FRACTION := 0.55
## Applied to kick from WeaponResource (degrees → camera). Tune global feel here.
const RECOIL_IMPACT_MULT := 1.75

## Hip-fire spread mult when walking (previous sprint tier).
const MOVE_SPREAD_WALK_MAX := 1.32
## Hip-fire spread mult when sprinting
const MOVE_SPREAD_SPRINT_MAX := 1.52

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var weapon_manager: Node = $WeaponManager
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var is_aiming := false
var is_sprinting := false
var _ads_progress := 0.0
var _sprint_spread := 0.0
## Smoothed 0 = still, 1 = walking (not sprinting).
var _walk_spread := 0.0
## Smoothed 0 = on ground, 1 = airborne (hurts accuracy while jumping / falling).
var _air_spread := 0.0
## Smoothed 0 = standing, 1 = full crouch (tighter spread, lower capsule).
var _crouch_progress := 0.0
var _foot_capsule_offset := 0.0
var _capsule_radius := 0.3
var _recoil_v_recover := 0.0
var _recoil_h_recover := 0.0

var is_sliding := false
var _slide_skip_friction := false
## Wall contact from previous physics tick (valid for wall jump after move_and_slide).
var _was_on_wall := false
var _wall_normal := Vector3.UP


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var cap: CapsuleShape3D = collision_shape.shape as CapsuleShape3D
	if cap:
		_capsule_radius = cap.radius
		var total := cap.height + 2.0 * _capsule_radius
		_foot_capsule_offset = collision_shape.position.y - total * 0.5


func _process(delta: float) -> void:
	is_aiming = Input.is_action_pressed("aim") and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED

	var ads_time := 0.25
	if weapon_manager and weapon_manager.current_weapon_data:
		ads_time = weapon_manager.current_weapon_data.ads_time
	var ads_speed := (1.0 / ads_time) if ads_time > 0.0 else 20.0

	if is_aiming:
		_ads_progress = minf(_ads_progress + ads_speed * delta, 1.0)
	else:
		_ads_progress = maxf(_ads_progress - ads_speed * delta, 0.0)

	var t := _ads_progress * _ads_progress * (3.0 - 2.0 * _ads_progress)
	camera.fov = lerpf(DEFAULT_FOV, ADS_FOV, t)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if weapon_manager.ammo_wheel_open:
			weapon_manager.feed_wheel_mouse(event.relative)
			return
		var sens := MOUSE_SENSITIVITY * lerpf(1.0, ADS_SENSITIVITY_MULT, _ads_progress)
		rotate_y(-event.relative.x * sens)
		head.rotate_x(-event.relative.y * sens)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		else:
			var away := _get_wall_jump_away()
			if away.length_squared() > 0.0001:
				velocity.x = away.x * WALL_JUMP_OUT
				velocity.z = away.z * WALL_JUMP_OUT
				velocity.y = WALL_JUMP_UP
				_was_on_wall = false

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var hz_speed := Vector3(velocity.x, 0.0, velocity.z).length()

	_try_start_slide(hz_speed, direction)

	var crouch_rate := 12.0
	if is_sliding:
		_crouch_progress = 1.0
	else:
		var wants_crouch := Input.is_action_pressed("crouch") and is_on_floor()
		if wants_crouch:
			_crouch_progress = minf(_crouch_progress + crouch_rate * delta, 1.0)
		else:
			_crouch_progress = maxf(_crouch_progress - crouch_rate * delta, 0.0)

	var air_target := 0.0 if is_on_floor() else 1.0
	_air_spread = lerpf(_air_spread, air_target, 10.0 * delta)

	_apply_crouch_capsule()

	var can_sprint := _crouch_progress < 0.25 and not is_sliding
	is_sprinting = (
		can_sprint
		and Input.is_action_pressed("sprint")
		and direction.length() > 0.1
	)
	var base_speed := SPRINT_SPEED if is_sprinting else SPEED
	base_speed *= lerpf(1.0, CROUCH_SPEED_MULT, _crouch_progress)
	var current_speed := lerpf(base_speed, ADS_SPEED, _ads_progress)

	if is_sliding:
		_apply_slide(delta, direction)
	elif is_on_floor():
		_apply_ground_horizontal_move(delta, direction, current_speed)
	else:
		_apply_air_horizontal_move(delta, direction, current_speed)

	move_and_slide()

	if is_on_wall():
		_was_on_wall = true
		_wall_normal = get_wall_normal()
	else:
		var probed := _probe_nearest_wall_normal()
		if probed.length_squared() > 0.0001:
			_was_on_wall = true
			_wall_normal = probed
		else:
			_was_on_wall = false

	head.position.y = lerpf(STANDING_HEAD_Y, CROUCH_HEAD_Y, _crouch_progress)

	var sprint_target := 1.0 if (is_sprinting or is_sliding) else 0.0
	_sprint_spread = lerpf(_sprint_spread, sprint_target, 6.0 * delta)

	var walk_target := 0.0
	if is_on_floor() and direction.length() > 0.1 and not is_sprinting and not is_sliding:
		walk_target = 1.0
	_walk_spread = lerpf(_walk_spread, walk_target, 6.0 * delta)

	_recover_recoil(delta)


func _try_start_slide(hz_speed: float, direction: Vector3) -> void:
	if is_sliding:
		if not is_on_floor() or not Input.is_action_pressed("crouch"):
			is_sliding = false
			_slide_skip_friction = false
		else:
			hz_speed = Vector3(velocity.x, 0.0, velocity.z).length()
			if hz_speed < SLIDE_END_SPEED:
				is_sliding = false
				_slide_skip_friction = false
		return
	if not is_on_floor():
		return
	if not Input.is_action_just_pressed("crouch"):
		return
	if not Input.is_action_pressed("sprint"):
		return
	if hz_speed < SLIDE_ENTER_MIN_SPEED:
		return
	if direction.length_squared() < 0.0025:
		return
	is_sliding = true
	_slide_skip_friction = true
	var d := direction.normalized()
	var boosted := minf(maxf(hz_speed * SLIDE_BOOST_MULT, SLIDE_ENTER_MIN_SPEED * SLIDE_BOOST_MULT), SLIDE_MAX_SPEED)
	velocity.x = d.x * boosted
	velocity.z = d.z * boosted


func _apply_slide(delta: float, direction: Vector3) -> void:
	var hv := Vector3(velocity.x, 0.0, velocity.z)
	var spd := hv.length()
	var forward := hv / spd if spd > 0.08 else Vector3.ZERO
	if direction.length_squared() > 0.0025:
		var target := direction.normalized()
		if forward.length_squared() > 0.0001:
			forward = (forward + target * (SLIDE_STEER * delta)).normalized()
		else:
			forward = target
	if not _slide_skip_friction:
		var fric := SLIDE_FRICTION * delta
		spd = maxf(0.0, spd - fric * maxf(1.0, spd * 0.08))
	else:
		_slide_skip_friction = false
	spd = minf(spd, SLIDE_MAX_SPEED)
	velocity.x = forward.x * spd
	velocity.z = forward.z * spd


func _apply_ground_horizontal_move(delta: float, direction: Vector3, current_speed: float) -> void:
	var hz := Vector3(velocity.x, 0.0, velocity.z)
	var spd := hz.length()
	var has_input := direction.length_squared() > 0.01
	if has_input:
		var dir := direction.normalized()
		if spd <= current_speed + 0.02:
			velocity.x = dir.x * current_speed
			velocity.z = dir.z * current_speed
		else:
			var nd := hz.normalized().lerp(dir, minf(1.0, OVERSPEED_STEER * delta)).normalized()
			var tgt := move_toward(spd, current_speed, MOMENTUM_DECAY_TO_CAP * delta)
			velocity.x = nd.x * tgt
			velocity.z = nd.z * tgt
	elif spd < 0.02:
		velocity.x = 0.0
		velocity.z = 0.0
	elif spd <= current_speed + 0.02:
		velocity.x = move_toward(velocity.x, 0.0, current_speed * delta * 10.0)
		velocity.z = move_toward(velocity.z, 0.0, current_speed * delta * 10.0)
	else:
		var nd := hz.normalized()
		var tgt := move_toward(spd, 0.0, MOMENTUM_COAST_FRICTION * delta)
		velocity.x = nd.x * tgt
		velocity.z = nd.z * tgt


func _apply_air_horizontal_move(delta: float, direction: Vector3, wish_speed: float) -> void:
	if direction.length_squared() < 0.0001:
		return
	var wish_dir := direction.normalized()
	var hz := Vector3(velocity.x, 0.0, velocity.z)
	var current_along := hz.dot(wish_dir)
	var add_speed := wish_speed - current_along
	if add_speed <= 0.0:
		return
	var accel_speed := minf(AIR_ACCEL * wish_speed * delta, add_speed)
	hz += wish_dir * accel_speed
	velocity.x = hz.x
	velocity.z = hz.z


func _probe_nearest_wall_normal() -> Vector3:
	var origin := global_position + Vector3(0.0, WALL_PROBE_HEIGHT, 0.0)
	var space := get_world_3d().direct_space_state
	var dirs: Array[Vector3] = [
		Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)
	]
	var hz_vel := Vector3(velocity.x, 0.0, velocity.z)
	if hz_vel.length_squared() > 0.01:
		var hvn := hz_vel.normalized()
		dirs.append(hvn)
		dirs.append(-hvn)
	var best_n := Vector3.ZERO
	var best_d := 1.0e12
	var mask := collision_mask
	if mask == 0:
		mask = 1
	for d in dirs:
		var dn := d.normalized()
		var q := PhysicsRayQueryParameters3D.create(origin, origin + dn * WALL_PROBE_LEN)
		q.collision_mask = mask
		q.exclude = [get_rid()]
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			continue
		var pos: Vector3 = hit["position"]
		var dist := origin.distance_to(pos)
		if dist < best_d:
			best_d = dist
			best_n = hit["normal"] as Vector3
	if best_n.length_squared() < 0.0001:
		return Vector3.ZERO
	return best_n.normalized()


func _get_wall_jump_away() -> Vector3:
	var n := _probe_nearest_wall_normal()
	if n.length_squared() > 0.0001:
		var away := Vector3(n.x, 0.0, n.z)
		if away.length_squared() > 0.0001:
			return away.normalized()
	if _was_on_wall:
		var away2 := Vector3(_wall_normal.x, 0.0, _wall_normal.z)
		if away2.length_squared() > 0.0001:
			return away2.normalized()
	return Vector3.ZERO


func apply_recoil(vertical_deg: float, horizontal_deg: float) -> void:
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
	if weapon_manager and weapon_manager.current_weapon_data:
		rate = weapon_manager.current_weapon_data.recoil_recovery_rate

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


func _collision_center_y_for_cylinder(cyl_h: float) -> float:
	return _foot_capsule_offset + (cyl_h + 2.0 * _capsule_radius) * 0.5


func _apply_crouch_capsule() -> void:
	var cap: CapsuleShape3D = collision_shape.shape as CapsuleShape3D
	if not cap:
		return
	var cyl := lerpf(STANDING_CAPSULE_CYLINDER_H, CROUCH_CAPSULE_CYLINDER_H, _crouch_progress)
	cap.height = cyl
	collision_shape.position.y = _collision_center_y_for_cylinder(cyl)
