class_name AmmoRifle
extends RefCounted
## Intermediate rifle cartridges: 5.56 NATO, etc.


static func register(out_calibers: Dictionary) -> void:
	# ---- 5.56x45mm NATO family ----
	out_calibers["556_m855"] = WeaponDataHelpers.make_caliber(
		"5.56 M855 FMJ", CaliberResource.AmmoType.FMJ,
		40.0, 940.0, 0.50, 200.0, 500.0, 0.20)
	out_calibers["556_m855a1"] = WeaponDataHelpers.make_caliber(
		"5.56 M855A1 AP", CaliberResource.AmmoType.AP,
		35.0, 961.0, 0.70, 200.0, 500.0, 0.18, 1, 0.0, 0.85)
	out_calibers["556_mk262"] = WeaponDataHelpers.make_caliber(
		"5.56 Mk262 OTM", CaliberResource.AmmoType.HP,
		48.0, 850.0, 0.30, 180.0, 450.0, 0.15, 1, 0.0, 1.3)
	out_calibers["556_m856"] = WeaponDataHelpers.make_caliber(
		"5.56 M856 Tracer", CaliberResource.AmmoType.TRACER,
		38.0, 930.0, 0.45, 190.0, 480.0, 0.18)
