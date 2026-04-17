class_name WeaponSpreadHelper
extends RefCounted

const ADS_SPREAD_MULT := 0.35
const ADS_PELLET_SPREAD_MULT := 0.7
const AIR_SPREAD_MULT := 2.35
const CROUCH_SPREAD_MULT := 0.88


static func build_profile(
	player: CharacterBody3D,
	weapon: WeaponResource,
	caliber: CaliberResource,
	current_spread: float,
	is_burst_compensated: bool,
	spread_multiplier: float = 1.0
) -> Dictionary:
	var state := _get_player_spread_state(player)
	var bullet_spread := current_spread
	bullet_spread *= lerpf(1.0, ADS_SPREAD_MULT, state.ads_progress)
	bullet_spread *= lerpf(1.0, state.walk_spread_mult, state.walk_progress)
	bullet_spread *= lerpf(1.0, state.sprint_spread_mult, state.sprint_progress)
	bullet_spread *= lerpf(1.0, AIR_SPREAD_MULT, state.air_progress)
	bullet_spread *= lerpf(1.0, CROUCH_SPREAD_MULT, state.crouch_progress)

	var pellet_spread := 0.0
	if caliber and caliber.pellet_count > 1:
		pellet_spread = caliber.pellet_spread_deg
		pellet_spread *= lerpf(1.0, ADS_PELLET_SPREAD_MULT, state.ads_progress)
		pellet_spread *= lerpf(1.0, state.walk_spread_mult, state.walk_progress)
		pellet_spread *= lerpf(1.0, state.sprint_spread_mult, state.sprint_progress)
		pellet_spread *= lerpf(1.0, AIR_SPREAD_MULT, state.air_progress)
		pellet_spread *= lerpf(1.0, CROUCH_SPREAD_MULT, state.crouch_progress)

	if is_burst_compensated and weapon:
		bullet_spread *= weapon.burst_compensation_spread_mult
		pellet_spread *= weapon.burst_compensation_spread_mult

	bullet_spread *= spread_multiplier
	pellet_spread *= spread_multiplier

	return {
		"bullet_spread_deg": bullet_spread,
		"pellet_spread_deg": pellet_spread,
		"crosshair_spread_deg": bullet_spread + pellet_spread,
	}


static func get_crosshair_pixels(
	camera: Camera3D,
	viewport_size: Vector2,
	spread_deg: float
) -> float:
	if not camera:
		return maxf(2.0, spread_deg * 14.0)
	var half_fov_rad := deg_to_rad(camera.fov * 0.5)
	var pixels_per_deg := (
		(viewport_size.y * 0.5) / rad_to_deg(half_fov_rad)
		if half_fov_rad > 0.0
		else 14.0
	)
	return maxf(2.0, spread_deg * pixels_per_deg)


static func _get_player_spread_state(player: CharacterBody3D) -> Dictionary:
	if player and player.has_method("get_spread_state"):
		return player.get_spread_state()
	return {
		"ads_progress": 0.0,
		"walk_progress": 0.0,
		"sprint_progress": 0.0,
		"air_progress": 0.0,
		"crouch_progress": 0.0,
		"walk_spread_mult": 1.0,
		"sprint_spread_mult": 1.0,
	}
