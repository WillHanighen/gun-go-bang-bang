extends RefCounted

const HITSCAN_MASK := 0b1101
const MAX_PENETRATION_PASSES := 3
const PENETRATION_STEP := 0.05

var _world: World3D
var _decal_pool


func setup(world: World3D, decal_pool) -> void:
	_world = world
	_decal_pool = decal_pool


func perform_hitscan(
	origin: Vector3,
	directions: Array[Vector3],
	caliber: CaliberResource
) -> Array[Dictionary]:
	var hit_events: Array[Dictionary] = []
	if not _world or not caliber:
		return hit_events

	var space_state := _world.direct_space_state
	var is_incen := caliber.incendiary_damage > 0.0

	for direction in directions:
		var end := origin + direction * caliber.max_range
		var query := PhysicsRayQueryParameters3D.create(origin, end)
		query.collision_mask = HITSCAN_MASK
		query.collide_with_bodies = true

		var remaining_pen := caliber.penetration_power
		var damage_mult := 1.0
		var ray_origin := origin
		var excluded: Array[RID] = []

		for _pass in MAX_PENETRATION_PASSES:
			query.from = ray_origin
			query.to = end
			query.exclude = excluded
			var result := space_state.intersect_ray(query)
			if result.is_empty():
				break

			var hit_pos: Vector3 = result.position
			var hit_normal: Vector3 = result.normal
			var hit_dist := origin.distance_to(hit_pos)
			var hit_obj: Object = result.collider
			excluded.append(result.rid)

			if _decal_pool:
				_decal_pool.spawn(hit_pos, hit_normal, is_incen)

			if hit_obj and hit_obj.has_method("take_damage"):
				var raw_dmg := caliber.get_damage_at_distance(hit_dist) * damage_mult
				var final_dmg := raw_dmg * caliber.flesh_damage_mult + caliber.incendiary_damage
				hit_obj.take_damage(final_dmg, hit_pos, direction)
				hit_events.append({
					"distance": hit_dist,
					"damage": final_dmg,
					"target_name": hit_obj.name,
				})

			var material := "default"
			if hit_obj and hit_obj.has_meta("material_type"):
				material = hit_obj.get_meta("material_type")

			if Ballistics.can_penetrate(remaining_pen, material):
				var pen_mult := Ballistics.get_penetration_damage_mult(remaining_pen, material)
				damage_mult *= pen_mult
				remaining_pen *= pen_mult
				ray_origin = hit_pos + direction * PENETRATION_STEP
			else:
				break

	return hit_events
