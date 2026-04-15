extends RefCounted

var _decal_parent: Node
var _max_decals: int
var _decals: Array[MeshInstance3D] = []
var _decal_mesh: QuadMesh
var _decal_mat: StandardMaterial3D
var _decal_mat_incen: StandardMaterial3D


func setup(decal_parent: Node, max_decals: int) -> void:
	_decal_parent = decal_parent
	_max_decals = max_decals
	_init_resources()


func spawn(hit_pos: Vector3, normal: Vector3, is_incen: bool) -> void:
	if not is_instance_valid(_decal_parent):
		return

	var decal := MeshInstance3D.new()
	decal.mesh = _decal_mesh
	decal.set_surface_override_material(0, _decal_mat_incen if is_incen else _decal_mat)

	var scale_f := randf_range(0.8, 1.3)
	decal.scale = Vector3(scale_f, scale_f, 1.0)
	_decal_parent.add_child(decal)
	decal.global_position = hit_pos + normal * 0.002

	var up_hint := Vector3.FORWARD if normal.abs().is_equal_approx(Vector3.UP) else Vector3.UP
	decal.look_at(decal.global_position + normal, up_hint)
	decal.rotate_object_local(Vector3.FORWARD, randf() * TAU)

	_decals.append(decal)
	while _decals.size() > _max_decals:
		var old: MeshInstance3D = _decals.pop_front()
		if is_instance_valid(old):
			old.queue_free()


func _init_resources() -> void:
	_decal_mesh = QuadMesh.new()
	_decal_mesh.size = Vector2(0.04, 0.04)

	_decal_mat = StandardMaterial3D.new()
	_decal_mat.albedo_color = Color(0.05, 0.05, 0.05, 0.85)
	_decal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_decal_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_decal_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_decal_mat.render_priority = 1

	_decal_mat_incen = StandardMaterial3D.new()
	_decal_mat_incen.albedo_color = Color(0.18, 0.08, 0.0, 0.9)
	_decal_mat_incen.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_decal_mat_incen.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_decal_mat_incen.cull_mode = BaseMaterial3D.CULL_DISABLED
	_decal_mat_incen.render_priority = 1
