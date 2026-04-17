class_name AmmoShotgun
extends RefCounted
## 12 gauge and other shotgun shells.


static func register(out_calibers: Dictionary) -> void:
	# Internal shotgun pellet spread uses cone half-angle.
	# A ~2.5 deg total buckshot pattern ends up around 0.85 deg here once the weapon's own handling spread is added.
	out_calibers["12_000buck"] = WeaponDataHelpers.make_caliber(
		"12ga 000 Buck", CaliberResource.AmmoType.BUCKSHOT,
		14.0, 405.0, 0.24, 24.0, 45.0, 0.06, 8, 0.8)
	out_calibers["12_00buck"] = WeaponDataHelpers.make_caliber(
		"12ga 00 Buck", CaliberResource.AmmoType.BUCKSHOT,
		12.0, 396.0, 0.20, 18.0, 37.0, 0.05, 9, 0.85)
	out_calibers["12_4buck"] = WeaponDataHelpers.make_caliber(
		"12ga #4 Buck", CaliberResource.AmmoType.BUCKSHOT,
		6.0, 381.0, 0.12, 14.0, 28.0, 0.03, 27, 0.85)
	out_calibers["12_slug"] = WeaponDataHelpers.make_caliber(
		"12ga Slug", CaliberResource.AmmoType.SLUG,
		80.0, 457.0, 0.60, 50.0, 100.0, 0.30)
	out_calibers["12_ap_slug"] = WeaponDataHelpers.make_caliber(
		"12ga AP Slug", CaliberResource.AmmoType.AP,
		70.0, 480.0, 0.75, 45.0, 95.0, 0.25, 1, 0.0, 0.85)
