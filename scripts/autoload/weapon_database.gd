extends Node

var calibers: Dictionary = {}
var weapons: Array[WeaponResource] = []


func _ready() -> void:
	_init_calibers()
	_init_weapons()


func _init_calibers() -> void:
	AmmoPistolSmg.register(calibers)
	AmmoRevolver.register(calibers)
	AmmoRifle.register(calibers)
	AmmoShotgun.register(calibers)


func _init_weapons() -> void:
	WeaponsPistolSmg.register(calibers, weapons)
	WeaponsShotgun.register(calibers, weapons)
	WeaponsRifle.register(calibers, weapons)


func get_weapon_by_name(weapon_name: String) -> WeaponResource:
	for weapon in weapons:
		if weapon.weapon_name == weapon_name:
			return weapon
	return null
