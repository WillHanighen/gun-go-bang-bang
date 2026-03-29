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

	for i in pellet_count:
		var total_spread := deg_to_rad(spread_deg + base_spread_deg)
		var angle := randf() * TAU
		var deflection := randf() * total_spread
		var dir := forward.rotated(actual_up, cos(angle) * deflection)
		dir = dir.rotated(right, sin(angle) * deflection)
		directions.append(dir.normalized())

	return directions
