extends StaticBody3D

var max_health: float = 100.0
var is_steel: bool = false
var current_health: float = 100.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var col: CollisionShape3D = $CollisionShape3D

var _original_material: Material


func _ready() -> void:
	current_health = max_health
	if mesh:
		_original_material = mesh.get_surface_override_material(0)


func take_damage(amount: float, hit_position: Vector3, direction: Vector3) -> void:
	current_health -= amount
	_flash_hit()
	if is_steel:
		current_health = max_health
	elif current_health <= 0.0:
		_on_destroyed()


func _flash_hit() -> void:
	if not mesh:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	mesh.set_surface_override_material(0, mat)
	get_tree().create_timer(0.1).timeout.connect(_restore_material)


func _restore_material() -> void:
	if mesh:
		mesh.set_surface_override_material(0, _original_material)


func _on_destroyed() -> void:
	visible = false
	col.set_deferred("disabled", true)
	get_tree().create_timer(2.0).timeout.connect(_respawn)


func _respawn() -> void:
	current_health = max_health
	visible = true
	col.set_deferred("disabled", false)
