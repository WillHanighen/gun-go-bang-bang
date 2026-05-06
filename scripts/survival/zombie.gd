extends CharacterBody3D

signal died(zombie: Node)

const MOVE_SPEED := 4.0
const HEALTH_MAX := 55.0
const ATTACK_RANGE := 1.35
const ATTACK_DAMAGE := 12.0
const ATTACK_COOLDOWN := 1.0

@onready var _mesh: MeshInstance3D = $Pill

var _health: float = HEALTH_MAX
var _original_mat: Material
var _attack_cooldown := 0.0


func _ready() -> void:
	set_meta("material_type", "flesh")
	add_to_group("enemies")
	if _mesh:
		_original_mat = _mesh.get_surface_override_material(0)
		if _original_mat == null:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.35, 0.52, 0.38)
			_mesh.set_surface_override_material(0, mat)
			_original_mat = mat


func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	var target := _choose_target()
	if target == null:
		return

	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var distance_sq := to_target.length_squared()
	if distance_sq > 0.04:
		var dir := to_target.normalized()
		var can_attack := distance_sq <= ATTACK_RANGE * ATTACK_RANGE
		velocity.x = 0.0 if can_attack else dir.x * MOVE_SPEED
		velocity.z = 0.0 if can_attack else dir.z * MOVE_SPEED
		look_at(global_position + dir, Vector3.UP)
		if can_attack:
			_try_attack_target(target)

	velocity += get_gravity() * delta
	move_and_slide()


func take_damage(amount: float, _hit_position: Vector3, _direction: Vector3) -> void:
	_health -= amount
	_flash_hit()
	if _health <= 0.0:
		died.emit(self)
		queue_free()


func _choose_target() -> Node3D:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var heat_director := get_tree().get_first_node_in_group("survival_heat_director")
	if heat_director and heat_director.has_method("get_hottest_target"):
		var heat_target := heat_director.call("get_hottest_target") as Node3D
		if heat_target and (not player or global_position.distance_to(heat_target.global_position) < global_position.distance_to(player.global_position) + 18.0):
			return heat_target
	return player


func _try_attack_target(target: Node3D) -> void:
	if _attack_cooldown > 0.0:
		return
	_attack_cooldown = ATTACK_COOLDOWN
	if target.has_method("take_damage"):
		target.call("take_damage", ATTACK_DAMAGE, global_position, (target.global_position - global_position).normalized())
	if target.is_in_group("player") and randf() < 0.08 and target.has_method("apply_infection"):
		target.call("apply_infection", 8.0)


func _flash_hit() -> void:
	if not _mesh:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.2, 0.25)
	_mesh.set_surface_override_material(0, mat)
	get_tree().create_timer(0.08).timeout.connect(_restore_mesh_material)


func _restore_mesh_material() -> void:
	if not is_instance_valid(self) or _mesh == null:
		return
	_mesh.set_surface_override_material(0, _original_mat)
