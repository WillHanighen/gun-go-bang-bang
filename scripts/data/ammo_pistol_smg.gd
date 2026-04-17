class_name AmmoPistolSmg
extends RefCounted
## Pistol and SMG cartridges: .45 ACP, 9x19mm, etc.


static func register(out_calibers: Dictionary) -> void:
	# ---- .45 ACP family ----
	out_calibers["45_fmj"] = WeaponDataHelpers.make_caliber(
		".45 ACP FMJ", CaliberResource.AmmoType.FMJ,
		45.0, 253.0, 0.30, 25.0, 100.0, 0.15)
	out_calibers["45_ap"] = WeaponDataHelpers.make_caliber(
		".45 ACP AP", CaliberResource.AmmoType.AP,
		36.0, 260.0, 0.58, 25.0, 100.0, 0.12, 1, 0.0, 0.82)
	out_calibers["45_hp"] = WeaponDataHelpers.make_caliber(
		".45 ACP JHP", CaliberResource.AmmoType.HP,
		57.0, 245.0, 0.08, 20.0, 80.0, 0.1, 1, 0.0, 1.45)
	out_calibers["45_incen"] = WeaponDataHelpers.make_caliber(
		".45 ACP Incendiary", CaliberResource.AmmoType.INCENDIARY,
		40.0, 250.0, 0.25, 22.0, 90.0, 0.12, 1, 0.0, 1.0, 10.0)

	# ---- 9x19mm family ----
	out_calibers["9_fmj"] = WeaponDataHelpers.make_caliber(
		"9x19mm FMJ", CaliberResource.AmmoType.FMJ,
		35.0, 360.0, 0.25, 30.0, 120.0, 0.10)
	out_calibers["9_ap"] = WeaponDataHelpers.make_caliber(
		"9x19mm AP", CaliberResource.AmmoType.AP,
		28.0, 375.0, 0.5, 30.0, 120.0, 0.08, 1, 0.0, 0.8)
	out_calibers["9_hp"] = WeaponDataHelpers.make_caliber(
		"9x19mm JHP", CaliberResource.AmmoType.HP,
		46.0, 340.0, 0.06, 25.0, 90.0, 0.08, 1, 0.0, 1.48)
	out_calibers["9_subsonic"] = WeaponDataHelpers.make_caliber(
		"9x19mm Subsonic", CaliberResource.AmmoType.SUBSONIC,
		32.0, 300.0, 0.22, 20.0, 80.0, 0.12)
