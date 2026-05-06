class_name ItemResource
extends Resource

enum ItemCategory { WEAPON, AMMO, RESOURCE, FOOD, MEDICINE, TOOL, DEPLOYABLE }

@export var item_id := ""
@export var display_name := ""
@export var category := ItemCategory.RESOURCE
@export var inventory_width := 1
@export var inventory_height := 1
@export var max_stack := 1
@export var weight := 0.1
@export var tags: Array[String] = []

@export_group("Optional Links")
@export var weapon: WeaponResource
@export var caliber: CaliberResource
@export var ammo_quality := "standard"


func get_inventory_size() -> Vector2i:
	return Vector2i(maxi(inventory_width, 1), maxi(inventory_height, 1))


func get_display_name() -> String:
	if not display_name.is_empty():
		return display_name
	if weapon:
		return weapon.weapon_name
	if caliber:
		return "%s rounds" % caliber.caliber_name
	return item_id

