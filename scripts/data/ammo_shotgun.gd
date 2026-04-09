class_name AmmoShotgun
extends RefCounted
## 12 gauge and other shotgun shells.


static func register(out_calibers: Dictionary) -> void:
	# Pellet cone half-angle (deg): ~cylinder/IC buckshot vs ~25–40 yd pattern tests (not game-wide cones).
	out_calibers["12_00buck"] = WeaponDataHelpers.make_caliber(
		"12ga 00 Buck", CaliberResource.AmmoType.BUCKSHOT,
		12.0, 396.0, 0.20, 18.0, 37.0, 0.05, 9, 1.35)
	out_calibers["12_4buck"] = WeaponDataHelpers.make_caliber(
		"12ga #4 Buck", CaliberResource.AmmoType.BUCKSHOT,
		6.0, 381.0, 0.12, 14.0, 28.0, 0.03, 27, 1.95)
	out_calibers["12_slug"] = WeaponDataHelpers.make_caliber(
		"12ga Slug", CaliberResource.AmmoType.SLUG,
		80.0, 457.0, 0.60, 50.0, 100.0, 0.30)
	out_calibers["12_ap_slug"] = WeaponDataHelpers.make_caliber(
		"12ga AP Slug", CaliberResource.AmmoType.AP,
		70.0, 480.0, 0.75, 45.0, 95.0, 0.25, 1, 0.0, 0.85)
