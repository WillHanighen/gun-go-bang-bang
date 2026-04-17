class_name AmmoRevolver
extends RefCounted
## Revolver cartridges (.357 Magnum, etc.).


static func register(out_calibers: Dictionary) -> void:
	out_calibers["357_fmj"] = WeaponDataHelpers.make_caliber(
		".357 Magnum FMJ", CaliberResource.AmmoType.FMJ,
		42.0, 440.0, 0.28, 35.0, 95.0, 0.12)
	out_calibers["357_hp"] = WeaponDataHelpers.make_caliber(
		".357 Magnum JHP", CaliberResource.AmmoType.HP,
		54.0, 420.0, 0.1, 28.0, 75.0, 0.08, 1, 0.0, 1.4)
	out_calibers["357_ap"] = WeaponDataHelpers.make_caliber(
		".357 Magnum AP", CaliberResource.AmmoType.AP,
		34.0, 450.0, 0.48, 32.0, 90.0, 0.1, 1, 0.0, 0.84)
	out_calibers["38_special"] = WeaponDataHelpers.make_caliber(
		".38 Special FMJ", CaliberResource.AmmoType.FMJ,
		32.0, 300.0, 0.18, 25.0, 70.0, 0.14)
