extends Node

var calibers: Dictionary = {}
var weapons: Array[WeaponResource] = []


func _ready() -> void:
	_init_calibers()
	_init_weapons()


func _init_calibers() -> void:
	AmmoPistolSmg.register(calibers)
	AmmoRifle.register(calibers)
	AmmoShotgun.register(calibers)


func _init_weapons() -> void:
	WeaponsPistolSmg.register(calibers, weapons)
	WeaponsShotgun.register(calibers, weapons)
	WeaponsRifle.register(calibers, weapons)
