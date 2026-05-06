class_name SurvivalWorldManager
extends Node3D

const CHUNK_SIZE := 48.0
const WORLD_RADIUS := 2
const BIOMES := ["coast", "woods", "suburbs", "town"]

var world_seed := 1
var generated_chunks: Array[Dictionary] = []


func build_from_save(world_data: Dictionary) -> void:
	world_seed = int(world_data.get("seed", 1))
	generated_chunks.clear()
	for child in get_children():
		child.queue_free()
	_generate_island_shell()


func serialize_world(previous: Dictionary = {}) -> Dictionary:
	var data := previous.duplicate(true)
	data["seed"] = world_seed
	data["kind"] = "chunked_island_shell"
	data["chunk_size"] = CHUNK_SIZE
	data["generated_chunks"] = generated_chunks.duplicate(true)
	return data


func get_cell_for_position(world_position: Vector3) -> Vector2i:
	return Vector2i(floori(world_position.x / CHUNK_SIZE), floori(world_position.z / CHUNK_SIZE))


func get_biome_at_position(world_position: Vector3) -> String:
	var cell := get_cell_for_position(world_position)
	for chunk in generated_chunks:
		if int(chunk.get("x", 0)) == cell.x and int(chunk.get("z", 0)) == cell.y:
			return str(chunk.get("biome", "woods"))
	return "woods"


func _generate_island_shell() -> void:
	var root := Node3D.new()
	root.name = "GeneratedChunks"
	add_child(root)
	for z in range(-WORLD_RADIUS, WORLD_RADIUS + 1):
		for x in range(-WORLD_RADIUS, WORLD_RADIUS + 1):
			var biome := _choose_biome(x, z)
			var chunk_data := {
				"x": x,
				"z": z,
				"biome": biome,
				"poi": _choose_poi(x, z, biome),
			}
			generated_chunks.append(chunk_data)
			_spawn_chunk_visual(root, chunk_data)


func _spawn_chunk_visual(root: Node3D, chunk_data: Dictionary) -> void:
	var x := int(chunk_data.get("x", 0))
	var z := int(chunk_data.get("z", 0))
	var biome := str(chunk_data.get("biome", "woods"))
	var chunk := StaticBody3D.new()
	chunk.name = "Chunk_%d_%d_%s" % [x, z, biome]
	chunk.position = Vector3(x * CHUNK_SIZE, 0.0, z * CHUNK_SIZE)

	var mesh_i := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
	mesh_i.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _biome_color(biome)
	mesh_i.set_surface_override_material(0, mat)
	chunk.add_child(mesh_i)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(CHUNK_SIZE, 0.2, CHUNK_SIZE)
	col.shape = box
	col.position.y = -0.1
	chunk.add_child(col)

	root.add_child(chunk)
	_spawn_road_visual(root, chunk.position, x, z)
	_spawn_poi_visual(root, chunk.position, str(chunk_data.get("poi", "")), biome)


func _spawn_road_visual(root: Node3D, center: Vector3, x: int, z: int) -> void:
	if x != 0 and z != 0:
		return
	var road := MeshInstance3D.new()
	road.name = "Road_%d_%d" % [x, z]
	var box := BoxMesh.new()
	box.size = Vector3(CHUNK_SIZE, 0.035, 4.0) if z == 0 else Vector3(4.0, 0.035, CHUNK_SIZE)
	road.mesh = box
	road.position = center + Vector3(0, 0.025, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.09, 0.095, 0.09)
	road.set_surface_override_material(0, mat)
	root.add_child(road)


func _spawn_poi_visual(root: Node3D, center: Vector3, poi: String, biome: String) -> void:
	if poi.is_empty():
		return
	var poi_mesh := MeshInstance3D.new()
	poi_mesh.name = "POI_%s" % poi
	var box := BoxMesh.new()
	box.size = Vector3(8.0, 4.0, 8.0) if biome == "town" else Vector3(5.0, 2.5, 5.0)
	poi_mesh.mesh = box
	poi_mesh.position = center + Vector3(10.0, box.size.y * 0.5, -9.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.48, 0.42)
	poi_mesh.set_surface_override_material(0, mat)
	root.add_child(poi_mesh)


func _choose_biome(x: int, z: int) -> String:
	var dist: int = max(abs(x), abs(z))
	if dist == WORLD_RADIUS:
		return "coast"
	if abs(x) + abs(z) <= 1:
		return "suburbs"
	var roll: int = abs(hash("%d:%d:%d" % [world_seed, x, z])) % 100
	if roll < 45:
		return "woods"
	if roll < 80:
		return "suburbs"
	return "town"


func _choose_poi(x: int, z: int, biome: String) -> String:
	if x == 0 and z == 0:
		return "starter_shelter"
	var roll: int = abs(hash("poi:%d:%d:%d" % [world_seed, x, z])) % 100
	if biome == "town" and roll < 65:
		return "small_city_block"
	if biome == "suburbs" and roll < 45:
		return "loot_house"
	if biome == "woods" and roll < 25:
		return "camp"
	if roll > 92:
		return "hotspot"
	return ""


func _biome_color(biome: String) -> Color:
	match biome:
		"coast":
			return Color(0.55, 0.5, 0.32)
		"woods":
			return Color(0.16, 0.28, 0.15)
		"suburbs":
			return Color(0.22, 0.32, 0.22)
		"town":
			return Color(0.28, 0.29, 0.28)
		_:
			return Color(0.2, 0.28, 0.2)

