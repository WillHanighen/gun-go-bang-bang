extends CharacterBody3D

const SPEED := 5.0
const SPRINT_SPEED := 8.0
const ADS_SPEED := 3.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENSITIVITY := 0.002
const ADS_SENSITIVITY_MULT := 0.7

const DEFAULT_FOV := 75.0
const ADS_FOV := 50.0

const RECOIL_RECOVERY_FRACTION := 0.55

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var weapon_manager: Node = $WeaponManager

var is_aiming := false
var is_sprinting := false
var _ads_progress := 0.0
var _sprint_spread := 0.0
var _recoil_v_recover := 0.0
var _recoil_h_recover := 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


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
	is_sprinting = Input.is_action_pressed("sprint") and direction.length() > 0.1
	var base_speed := SPRINT_SPEED if is_sprinting else SPEED
	var current_speed := lerpf(base_speed, ADS_SPEED, _ads_progress)

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * delta * 10.0)
		velocity.z = move_toward(velocity.z, 0, current_speed * delta * 10.0)

	move_and_slide()

	var sprint_target := 1.0 if is_sprinting else 0.0
	_sprint_spread = lerpf(_sprint_spread, sprint_target, 6.0 * delta)

	_recover_recoil(delta)


func apply_recoil(vertical_deg: float, horizontal_deg: float) -> void:
	head.rotation.x += deg_to_rad(vertical_deg)
	head.rotation.x = clampf(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	rotation.y += deg_to_rad(horizontal_deg)

	_recoil_v_recover += vertical_deg * RECOIL_RECOVERY_FRACTION
	_recoil_h_recover += horizontal_deg * RECOIL_RECOVERY_FRACTION


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
