class_name WeaponResource
extends Resource

enum FireMode { SEMI, BURST, AUTO, PUMP }
enum InventoryKind { FIREARM, MELEE }
enum CarryClass { SMALL, MEDIUM, LARGE, VERY_LARGE, MELEE }

@export var weapon_name: String = ""
@export var calibers: Array[CaliberResource] = []
@export var fire_modes: Array[FireMode] = [FireMode.SEMI]
@export var burst_count: int = 2
@export var fire_rate: float = 600.0
@export var magazine_size: int = 30
@export var reload_time: float = 2.0
## 0 = one timer fills the mag (uses reload_time). Above 0 = one shell per tick (shotguns); reload_time is for caliber swap / ammo wheel only.
@export var per_shell_reload_time: float = 0.0

@export_group("Accuracy")
@export var base_spread: float = 1.0
@export var spread_increase_per_shot: float = 0.5
@export var max_spread: float = 5.0
@export var spread_recovery_rate: float = 8.0

@export_group("Handling")
## Seconds to reach full ADS. Pistols ~0.15, SMGs ~0.2, rifles ~0.3, shotguns ~0.35
@export var ads_time: float = 0.25

@export_group("Inventory")
@export var inventory_kind: InventoryKind = InventoryKind.FIREARM
@export var carry_class: CarryClass = CarryClass.MEDIUM
@export var inventory_width: int = 3
@export var inventory_height: int = 2

@export_group("Hand Space")
## 1 = can share a loadout slot with another one-handed item, 2 = needs the whole loadout.
@export_range(1, 2, 1) var hand_space: int = 2
## Extra spread when firing a one-handed item without support from the other hand.
@export_range(1.0, 3.0, 0.01) var single_hand_spread_mult: float = 1.25
## Extra recoil when firing a one-handed item without support from the other hand.
@export_range(1.0, 3.0, 0.01) var single_hand_recoil_mult: float = 1.3
## Additional penalty for the off-hand item in a dual-wield setup.
@export_range(1.0, 3.0, 0.01) var offhand_spread_mult: float = 1.12
@export_range(1.0, 3.0, 0.01) var offhand_recoil_mult: float = 1.18
## Bonus when the free hand supports the weapon instead of holding another item.
@export_range(0.3, 1.0, 0.01) var supported_spread_mult: float = 0.82
@export_range(0.3, 1.0, 0.01) var supported_recoil_mult: float = 0.78

@export_group("Recoil")
@export var recoil_vertical: float = 2.0
@export var recoil_horizontal_range: float = 0.5
@export var recoil_recovery_rate: float = 6.0
@export var recoil_mitigation: float = 0.0
## 1.0 = normal upward kick, -1.0 = downward (Super V / Vector)
@export var recoil_direction: float = 1.0

@export_group("Burst compensation")
## In BURST fire mode only: first N rounds use reduced recoil/spread (e.g. Kriss Super V 2-shot pair).
## 0 = disabled. A hypothetical 3rd round in a burst would use full recoil — hence 2-round burst IRL.
@export var burst_compensation_shots: int = 0
@export_range(0.05, 1.0, 0.01) var burst_compensation_recoil_mult: float = 0.22
@export_range(0.05, 1.0, 0.01) var burst_compensation_spread_mult: float = 0.32
## After the last round of a compensated burst: delayed impulse (bolt / mass catches up). 0 = off.
@export_range(0.0, 0.35, 0.005) var burst_delayed_recoil_delay_sec: float = 0.0
## Scales the delayed vertical + horizontal kick (roughly 2-round equivalent × this).
@export_range(0.0, 1.25, 0.01) var burst_delayed_recoil_impulse_strength: float = 0.0
@export_range(0.0, 1.0, 0.01) var burst_delayed_recoil_horizontal_factor: float = 0.55


func get_seconds_between_shots() -> float:
	if fire_rate <= 0.0:
		return 1.0
	return 60.0 / fire_rate


func get_effective_recoil_vertical() -> float:
	return recoil_vertical * (1.0 - recoil_mitigation) * recoil_direction


func get_effective_recoil_horizontal() -> float:
	return recoil_horizontal_range * (1.0 - recoil_mitigation)


func get_inventory_size() -> Vector2i:
	return Vector2i(maxi(inventory_width, 1), maxi(inventory_height, 1))


func is_one_handed() -> bool:
	return hand_space <= 1


func requires_full_hands() -> bool:
	return not is_one_handed()


func get_spread_multiplier(is_offhand: bool, has_support_hand: bool) -> float:
	if not is_one_handed():
		return 1.0
	if has_support_hand:
		return supported_spread_mult
	var mult := single_hand_spread_mult
	if is_offhand:
		mult *= offhand_spread_mult
	return mult


func get_recoil_multiplier(is_offhand: bool, has_support_hand: bool) -> float:
	if not is_one_handed():
		return 1.0
	if has_support_hand:
		return supported_recoil_mult
	var mult := single_hand_recoil_mult
	if is_offhand:
		mult *= offhand_recoil_mult
	return mult


func fits_equipment_slot(slot_name: StringName) -> bool:
	match slot_name:
		&"primary":
			return inventory_kind == InventoryKind.FIREARM or inventory_kind == InventoryKind.MELEE
		&"secondary":
			if inventory_kind == InventoryKind.MELEE:
				return true
			return carry_class == CarryClass.SMALL or carry_class == CarryClass.MEDIUM
		&"melee":
			return inventory_kind == InventoryKind.MELEE
		_:
			return true
