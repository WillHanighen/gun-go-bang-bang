extends CharacterBody3D

const MOVE_SPEED := 4.0
const HEALTH_MAX := 55.0

@onready var _mesh: MeshInstance3D = $Pill

var _health: float = HEALTH_MAX
var _original_mat: Material


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
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return

	var to_player := player.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() > 0.04:
		var dir := to_player.normalized()
		velocity.x = dir.x * MOVE_SPEED
		velocity.z = dir.z * MOVE_SPEED
		look_at(global_position + dir, Vector3.UP)

	velocity += get_gravity() * delta
	move_and_slide()


func take_damage(amount: float, _hit_position: Vector3, _direction: Vector3) -> void:
	_health -= amount
	_flash_hit()
	if _health <= 0.0:
		queue_free()


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
