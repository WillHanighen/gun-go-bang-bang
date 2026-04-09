class_name Ballistics

const MATERIAL_RESISTANCE := {
	"wood": 0.2,
	"thin_metal": 0.5,
	"concrete": 0.8,
	"steel": 0.95,
}


static func can_penetrate(penetration_power: float, material: String) -> bool:
	var resistance: float = MATERIAL_RESISTANCE.get(material, 1.0)
	return penetration_power > resistance


static func get_penetration_damage_mult(penetration_power: float, material: String) -> float:
	var resistance: float = MATERIAL_RESISTANCE.get(material, 1.0)
	if penetration_power <= resistance:
		return 0.0
	return clampf((penetration_power - resistance) / (1.0 - resistance), 0.1, 0.9)


static func calculate_spread_directions(
	forward: Vector3,
	up: Vector3,
	pellet_count: int,
	spread_deg: float,
	base_spread_deg: float = 0.0
) -> Array[Vector3]:
	var directions: Array[Vector3] = []
	var right := forward.cross(up).normalized()
	var actual_up := right.cross(forward).normalized()

	if pellet_count <= 1:
		if base_spread_deg > 0.0:
			var spread_rad := deg_to_rad(base_spread_deg)
			var angle := randf() * TAU
			var deflection := randf() * spread_rad
			var dir := forward.rotated(actual_up, cos(angle) * deflection)
			dir = dir.rotated(right, sin(angle) * deflection)
			directions.append(dir.normalized())
		else:
			directions.append(forward)
		return directions

	# Pellets: uniform disk in tangent plane so every shot stays inside a cone of
	# half-angle (spread_deg + base_spread_deg), matching the circular crosshair.
	var cone_half_deg := spread_deg + base_spread_deg
	var cone_half_rad := deg_to_rad(cone_half_deg)
	cone_half_rad = minf(cone_half_rad, deg_to_rad(89.0))
	var tan_half := tan(cone_half_rad)
	for _i in pellet_count:
		var phi := randf() * TAU
		var disk_r := sqrt(randf()) * tan_half
		var offset := right * (cos(phi) * disk_r) + actual_up * (sin(phi) * disk_r)
		var dir := forward + offset
		if dir.length_squared() < 1e-10:
			directions.append(forward)
		else:
			directions.append(dir.normalized())

	return directions
