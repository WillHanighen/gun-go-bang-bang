extends CharacterBody3D

const SPEED := 5.0
const SPRINT_SPEED := 8.0
const CROUCH_SPEED_MULT := 0.5
const ADS_SPEED := 3.0
const STANDING_HEAD_Y := 0.7
const CROUCH_HEAD_Y := 0.38
const STANDING_CAPSULE_CYLINDER_H := 1.8
const CROUCH_CAPSULE_CYLINDER_H := 0.45
const JUMP_VELOCITY := 4.5
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

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var wants_crouch := Input.is_action_pressed("crouch") and is_on_floor()
	var crouch_rate := 12.0
	if wants_crouch:
		_crouch_progress = minf(_crouch_progress + crouch_rate * delta, 1.0)
	else:
		_crouch_progress = maxf(_crouch_progress - crouch_rate * delta, 0.0)

	var air_target := 0.0 if is_on_floor() else 1.0
	_air_spread = lerpf(_air_spread, air_target, 10.0 * delta)

	_apply_crouch_capsule()

	var can_sprint := _crouch_progress < 0.25
	is_sprinting = (
		can_sprint
		and Input.is_action_pressed("sprint")
		and direction.length() > 0.1
	)
	var base_speed := SPRINT_SPEED if is_sprinting else SPEED
	base_speed *= lerpf(1.0, CROUCH_SPEED_MULT, _crouch_progress)
	var current_speed := lerpf(base_speed, ADS_SPEED, _ads_progress)

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * delta * 10.0)
		velocity.z = move_toward(velocity.z, 0, current_speed * delta * 10.0)

	move_and_slide()

	head.position.y = lerpf(STANDING_HEAD_Y, CROUCH_HEAD_Y, _crouch_progress)

	var sprint_target := 1.0 if is_sprinting else 0.0
	_sprint_spread = lerpf(_sprint_spread, sprint_target, 6.0 * delta)

	var walk_target := 0.0
	if is_on_floor() and direction.length() > 0.1 and not is_sprinting:
		walk_target = 1.0
	_walk_spread = lerpf(_walk_spread, walk_target, 6.0 * delta)

	_recover_recoil(delta)


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
