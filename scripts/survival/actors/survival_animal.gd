class_name SurvivalAnimal
extends CharacterBody3D

@export var animal_id := ""
@export var display_name := "Snack Deer"
@export var move_speed := 2.0
@export var health := 30.0

var _wander_dir := Vector3.FORWARD
var _wander_timer := 0.0


func _ready() -> void:
	add_to_group("survival_animal")
	set_meta("material_type", "flesh")
	_build_visual()


func _physics_process(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(1.5, 4.0)
		var angle := randf() * TAU
		_wander_dir = Vector3(cos(angle), 0.0, sin(angle))
	velocity.x = _wander_dir.x * move_speed
	velocity.z = _wander_dir.z * move_speed
	velocity += get_gravity() * delta
	move_and_slide()


func take_damage(amount: float, _hit_position: Vector3 = global_position, _direction: Vector3 = Vector3.ZERO) -> void:
	health -= amount
	if health <= 0.0:
		queue_free()


func _build_visual() -> void:
	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.7, 0.45, 1.0)
	mesh_i.mesh = box
	mesh_i.position.y = 0.45
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.52, 0.38, 0.22)
	mesh_i.set_surface_override_material(0, mat)
	add_child(mesh_i)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	col.shape = shape
	col.position = mesh_i.position
	add_child(col)

