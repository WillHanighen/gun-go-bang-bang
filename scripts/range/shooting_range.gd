extends Node3D

const PlayerScene := preload("res://scenes/player/player.tscn")
const TargetScript := preload("res://scripts/range/target.gd")
const MovingTargetScript := preload("res://scripts/range/moving_target.gd")
const HUDScript := preload("res://scripts/ui/hud.gd")

var player: CharacterBody3D


func _ready() -> void:
	_create_environment()
	_create_ground()
	_create_targets()
	_create_moving_targets()
	_create_distance_markers()
	_create_penetration_panels()
	_spawn_player()
	_create_hud()
	_equip_player()


# -- environment ---------------------------------------------------------------

func _create_environment() -> void:
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
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)


# -- ground --------------------------------------------------------------------

func _create_ground() -> void:
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

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 0.1, 250)
	col.shape = box
	col.position = Vector3(0, -0.05, -25.0)

	ground.add_child(mesh_inst)
	ground.add_child(col)
	add_child(ground)

	# Lane markings
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.9, 0.9, 0.9)
	for i in range(-2, 3):
		var line := MeshInstance3D.new()
		var line_mesh := BoxMesh.new()
		line_mesh.size = Vector3(0.05, 0.005, 150)
		line.mesh = line_mesh
		line.position = Vector3(i * 3.0, 0.005, -50.0)
		line.set_surface_override_material(0, line_mat)
		add_child(line)


# -- targets -------------------------------------------------------------------

func _create_targets() -> void:
	# Steel plates at 10 m and 25 m
	for x in [-2.0, 0.0, 2.0]:
		_make_target(Vector3(x, 1.0, -10.0), Vector3(0.4, 0.4, 0.05), true, Color(0.6, 0.6, 0.6))
		_make_target(Vector3(x, 1.0, -25.0), Vector3(0.4, 0.4, 0.05), true, Color(0.6, 0.6, 0.6))

	# Paper silhouettes at 50 m and 100 m
	for x in [-2.0, 0.0, 2.0]:
		_make_target(Vector3(x, 1.0, -50.0), Vector3(0.5, 1.5, 0.02), false, Color(0.9, 0.85, 0.7))
		_make_target(Vector3(x, 1.0, -100.0), Vector3(0.5, 1.5, 0.02), false, Color(0.9, 0.85, 0.7))


func _create_moving_targets() -> void:
	# Side lanes so they do not overlap the static grid (x ∈ {-2,0,2}).
	_make_moving_target(Vector3(4.0, 1.0, -10.0), Vector3(0.4, 0.4, 0.05), true, Color(0.65, 0.62, 0.62), 1.15, 1.0)
	_make_moving_target(Vector3(-4.0, 1.0, -10.0), Vector3(0.4, 0.4, 0.05), true, Color(0.62, 0.65, 0.7), 1.45, 0.65)
	_make_moving_target(Vector3(4.0, 1.0, -25.0), Vector3(0.4, 0.4, 0.05), true, Color(0.65, 0.62, 0.62), 2.0, 1.15)
	_make_moving_target(Vector3(-4.0, 1.0, -25.0), Vector3(0.4, 0.4, 0.05), true, Color(0.62, 0.65, 0.7), 1.75, 0.85)
	_make_moving_target(Vector3(4.0, 1.0, -50.0), Vector3(0.5, 1.5, 0.02), false, Color(0.92, 0.86, 0.72), 0.85, 0.45)


func _make_target(pos: Vector3, sz: Vector3, steel: bool, color: Color) -> void:
	_spawn_target(self, pos, sz, steel, color, "Target_%dm" % int(absf(pos.z)))


func _make_moving_target(center_pos: Vector3, sz: Vector3, steel: bool, color: Color, move_speed: float, amp: float) -> void:
	var mover := Node3D.new()
	mover.name = "MovingTarget_%dm_%s" % [int(absf(center_pos.z)), "L" if center_pos.x < 0.0 else "R"]
	mover.position = center_pos
	mover.set_script(MovingTargetScript)
	mover.set("speed", move_speed)
	mover.set("amplitude", amp)
	add_child(mover)
	_spawn_target(
		mover,
		Vector3.ZERO,
		sz,
		steel,
		color,
		"Target_%dm_moving" % int(absf(center_pos.z))
	)


func _spawn_target(parent: Node3D, local_pos: Vector3, sz: Vector3, steel: bool, color: Color, node_name: String) -> void:
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
	box_mesh.size = sz
	mesh_inst.mesh = box_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_inst.set_surface_override_material(0, mat)

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var box_shape := BoxShape3D.new()
	box_shape.size = sz
	col.shape = box_shape

	target.add_child(mesh_inst)
	target.add_child(col)
	parent.add_child(target)


# -- distance markers ----------------------------------------------------------

func _create_distance_markers() -> void:
	for dist in [10, 25, 50, 100]:
		var label := Label3D.new()
		label.text = "%d m / %d yd" % [dist, int(dist / 0.9144)]
		label.position = Vector3(5.5, 0.6, -float(dist))
		label.font_size = 48
		label.modulate = Color.WHITE
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)


# -- penetration test panels ---------------------------------------------------

func _create_penetration_panels() -> void:
	_make_panel(
		"WoodPanel", Vector3(-5.0, 1.0, -15.0),
		Vector3(1.5, 1.5, 0.1), Color(0.55, 0.35, 0.15), "wood"
	)
	_add_label("WOOD", Vector3(-5.0, 2.1, -15.0))

	_make_panel(
		"MetalPanel", Vector3(-7.5, 1.0, -15.0),
		Vector3(1.5, 1.5, 0.05), Color(0.5, 0.5, 0.55), "thin_metal"
	)
	_add_label("THIN METAL", Vector3(-7.5, 2.1, -15.0))

	# Targets behind panels to validate penetration
	_make_target(Vector3(-5.0, 1.0, -16.0), Vector3(0.4, 0.4, 0.05), true, Color(0.6, 0.6, 0.6))
	_make_target(Vector3(-7.5, 1.0, -16.0), Vector3(0.4, 0.4, 0.05), true, Color(0.6, 0.6, 0.6))


func _make_panel(n: String, pos: Vector3, sz: Vector3, color: Color, mat_type: String) -> void:
	var body := StaticBody3D.new()
	body.name = n
	body.position = pos
	body.collision_layer = 8
	body.collision_mask = 0
	body.set_meta("material_type", mat_type)

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = sz
	mesh_inst.mesh = box_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if mat_type == "thin_metal":
		mat.metallic = 0.8
	mesh_inst.set_surface_override_material(0, mat)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = sz
	col.shape = shape

	body.add_child(mesh_inst)
	body.add_child(col)
	add_child(body)


func _add_label(txt: String, pos: Vector3) -> void:
	var label := Label3D.new()
	label.text = txt
	label.position = pos
	label.font_size = 32
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)


# -- player + equip ------------------------------------------------------------

func _spawn_player() -> void:
	player = PlayerScene.instantiate()
	player.position = Vector3(0, 1.0, 2.0)
	add_child(player)


func _create_hud() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "HUD"
	var hud_ctrl := Control.new()
	hud_ctrl.name = "HUDControl"
	hud_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_ctrl.set_script(HUDScript)
	hud_layer.add_child(hud_ctrl)
	add_child(hud_layer)


func _equip_player() -> void:
	var wm: Node = player.get_node("WeaponManager")
	wm.weapons = WeaponDatabase.weapons
	wm.equip_weapon(0)
