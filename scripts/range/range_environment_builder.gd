class_name RangeEnvironmentBuilder
extends RefCounted


static func build(parent: Node3D) -> void:
	_create_environment(parent)
	_create_ground(parent)
	_create_distance_markers(parent)


static func _create_environment(parent: Node3D) -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.35, 0.55, 0.85)
	sky_mat.sky_horizon_color = Color(0.65, 0.75, 0.85)
	sky_mat.ground_bottom_color = Color(0.2, 0.17, 0.13)
	sky_mat.ground_horizon_color = Color(0.65, 0.75, 0.85)

	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	parent.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	parent.add_child(sun)


static func _create_ground(parent: Node3D) -> void:
	var ground := StaticBody3D.new()
	ground.name = "Ground"

	var mesh_inst := MeshInstance3D.new()
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(100, 250)
	mesh_inst.mesh = plane_mesh
	mesh_inst.position.z = -25.0

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.4, 0.3)
	mesh_inst.set_surface_override_material(0, mat)

	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 0.1, 250)
	collision.shape = box
	collision.position = Vector3(0, -0.05, -25.0)

	ground.add_child(mesh_inst)
	ground.add_child(collision)
	parent.add_child(ground)

	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.9, 0.9, 0.9)
	for i in range(-2, 3):
		var line := MeshInstance3D.new()
		var line_mesh := BoxMesh.new()
		line_mesh.size = Vector3(0.05, 0.005, 150)
		line.mesh = line_mesh
		line.position = Vector3(i * 3.0, 0.005, -50.0)
		line.set_surface_override_material(0, line_mat)
		parent.add_child(line)


static func _create_distance_markers(parent: Node3D) -> void:
	for dist in [10, 25, 50, 100]:
		var label := Label3D.new()
		label.text = "%d m / %d yd" % [dist, int(dist / 0.9144)]
		label.position = Vector3(5.5, 0.6, -float(dist))
		label.font_size = 48
		label.modulate = Color.WHITE
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		parent.add_child(label)
