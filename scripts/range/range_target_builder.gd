class_name RangeTargetBuilder
extends RefCounted

const TargetScript := preload("res://scripts/range/target.gd")
const MovingTargetScript := preload("res://scripts/range/moving_target.gd")


static func build(parent: Node3D) -> void:
	_create_targets(parent)
	_create_moving_targets(parent)
	_create_penetration_panels(parent)


static func _create_targets(parent: Node3D) -> void:
	for x in [-2.0, 0.0, 2.0]:
		_make_target(parent, Vector3(x, 1.0, -10.0), Vector3(0.4, 0.4, 0.05), true, Color(0.6, 0.6, 0.6))
		_make_target(parent, Vector3(x, 1.0, -25.0), Vector3(0.4, 0.4, 0.05), true, Color(0.6, 0.6, 0.6))

	for x in [-2.0, 0.0, 2.0]:
		_make_target(parent, Vector3(x, 1.0, -50.0), Vector3(0.5, 1.5, 0.02), false, Color(0.9, 0.85, 0.7))
		_make_target(parent, Vector3(x, 1.0, -100.0), Vector3(0.5, 1.5, 0.02), false, Color(0.9, 0.85, 0.7))


static func _create_moving_targets(parent: Node3D) -> void:
	_make_moving_target(parent, Vector3(4.0, 1.0, -10.0), Vector3(0.4, 0.4, 0.05), true, Color(0.65, 0.62, 0.62), 1.15, 1.0)
	_make_moving_target(parent, Vector3(-4.0, 1.0, -10.0), Vector3(0.4, 0.4, 0.05), true, Color(0.62, 0.65, 0.7), 1.45, 0.65)
	_make_moving_target(parent, Vector3(4.0, 1.0, -25.0), Vector3(0.4, 0.4, 0.05), true, Color(0.65, 0.62, 0.62), 2.0, 1.15)
	_make_moving_target(parent, Vector3(-4.0, 1.0, -25.0), Vector3(0.4, 0.4, 0.05), true, Color(0.62, 0.65, 0.7), 1.75, 0.85)
	_make_moving_target(parent, Vector3(4.0, 1.0, -50.0), Vector3(0.5, 1.5, 0.02), false, Color(0.92, 0.86, 0.72), 0.85, 0.45)


static func _create_penetration_panels(parent: Node3D) -> void:
	_make_panel(
		parent,
		"WoodPanel",
		Vector3(-5.0, 1.0, -15.0),
		Vector3(1.5, 1.5, 0.1),
		Color(0.55, 0.35, 0.15),
		"wood"
	)
	_add_label(parent, "WOOD", Vector3(-5.0, 2.1, -15.0))

	_make_panel(
		parent,
		"MetalPanel",
		Vector3(-7.5, 1.0, -15.0),
		Vector3(1.5, 1.5, 0.05),
		Color(0.5, 0.5, 0.55),
		"thin_metal"
	)
	_add_label(parent, "THIN METAL", Vector3(-7.5, 2.1, -15.0))

	_make_target(parent, Vector3(-5.0, 1.0, -16.0), Vector3(0.4, 0.4, 0.05), true, Color(0.6, 0.6, 0.6))
	_make_target(parent, Vector3(-7.5, 1.0, -16.0), Vector3(0.4, 0.4, 0.05), true, Color(0.6, 0.6, 0.6))


static func _make_target(
	parent: Node3D,
	pos: Vector3,
	size: Vector3,
	steel: bool,
	color: Color
) -> void:
	_spawn_target(parent, pos, size, steel, color, "Target_%dm" % int(absf(pos.z)))


static func _make_moving_target(
	parent: Node3D,
	center_pos: Vector3,
	size: Vector3,
	steel: bool,
	color: Color,
	move_speed: float,
	amplitude: float
) -> void:
	var mover := Node3D.new()
	mover.name = "MovingTarget_%dm_%s" % [int(absf(center_pos.z)), "L" if center_pos.x < 0.0 else "R"]
	mover.position = center_pos
	mover.set_script(MovingTargetScript)
	mover.set("speed", move_speed)
	mover.set("amplitude", amplitude)
	parent.add_child(mover)
	_spawn_target(
		mover,
		Vector3.ZERO,
		size,
		steel,
		color,
		"Target_%dm_moving" % int(absf(center_pos.z))
	)


static func _spawn_target(
	parent: Node3D,
	local_pos: Vector3,
	size: Vector3,
	steel: bool,
	color: Color,
	node_name: String
) -> void:
	var target := StaticBody3D.new()
	target.name = node_name
	target.position = local_pos
	target.collision_layer = 4
	target.collision_mask = 0
	target.set_script(TargetScript)
	target.set("is_steel", steel)
	target.set("max_health", 100.0)

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "MeshInstance3D"
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_inst.set_surface_override_material(0, mat)

	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	collision.shape = box_shape

	target.add_child(mesh_inst)
	target.add_child(collision)
	parent.add_child(target)


static func _make_panel(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	size: Vector3,
	color: Color,
	material_type: String
) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.collision_layer = 8
	body.collision_mask = 0
	body.set_meta("material_type", material_type)

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if material_type == "thin_metal":
		mat.metallic = 0.8
	mesh_inst.set_surface_override_material(0, mat)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape

	body.add_child(mesh_inst)
	body.add_child(collision)
	parent.add_child(body)


static func _add_label(parent: Node3D, text_value: String, position: Vector3) -> void:
	var label := Label3D.new()
	label.text = text_value
	label.position = position
	label.font_size = 32
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
