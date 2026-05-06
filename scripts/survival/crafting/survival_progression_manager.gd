class_name SurvivalProgressionManager
extends Node

const GROUP := "survival_progression_manager"

var unlocked_recipes := {"field_bandage": true, "camp_snack": true}
var skills := {
	"crafting": 0.0,
	"cooking": 0.0,
	"gunsmith": 0.0,
	"research": 0.0,
}
var research_samples := {}
var in_progress_crafts: Array[Dictionary] = []

var recipes := {
	"field_bandage": {
		"name": "Field Bandage",
		"station": "field",
		"inputs": {"cloth": 2},
		"output": {"item_id": "bandage", "display_name": "Bandage", "category": "medicine", "count": 1, "max_stack": 5, "weight": 0.05, "size": Vector2i(1, 1)},
	},
	"camp_snack": {
		"name": "Camp Snack",
		"station": "field",
		"inputs": {"food_scraps": 2},
		"output": {"item_id": "camp_snack", "display_name": "Camp Snack", "category": "food", "count": 1, "max_stack": 8, "weight": 0.12, "size": Vector2i(1, 1)},
	},
	"pistol_ammo_bundle": {
		"name": ".45 Ammo Bundle",
		"station": "gunsmith",
		"inputs": {"scrap": 3, "powder": 1},
		"output": {"item_id": "ammo:45_acp_fmj", "display_name": ".45 ACP FMJ rounds", "category": "ammo", "caliber_name": ".45 ACP FMJ", "count": 12, "max_stack": 120, "weight": 0.025, "size": Vector2i(1, 1)},
	},
}


func _ready() -> void:
	add_to_group(GROUP)


func research_item(item_id: String, sample_count: int = 1) -> void:
	research_samples[item_id] = int(research_samples.get(item_id, 0)) + sample_count
	skills["research"] = float(skills.get("research", 0.0)) + sample_count * 1.0
	if item_id == "ammo:45_acp_fmj" and int(research_samples[item_id]) >= 2:
		unlocked_recipes["pistol_ammo_bundle"] = true


func can_craft(recipe_id: String, inventory: PlayerInventory, station: String = "field") -> bool:
	if not bool(unlocked_recipes.get(recipe_id, false)):
		return false
	if not recipes.has(recipe_id):
		return false
	var recipe := recipes[recipe_id] as Dictionary
	if str(recipe.get("station", "field")) != station:
		return false
	var inputs := recipe.get("inputs", {}) as Dictionary
	for item_id in inputs.keys():
		if inventory.get_stack_count(str(item_id)) < int(inputs[item_id]):
			return false
	return true


func craft(recipe_id: String, inventory: PlayerInventory, station: String = "field") -> bool:
	if not can_craft(recipe_id, inventory, station):
		return false
	var recipe := recipes[recipe_id] as Dictionary
	var inputs := recipe.get("inputs", {}) as Dictionary
	for item_id in inputs.keys():
		inventory.consume_stack(str(item_id), int(inputs[item_id]))
	inventory.add_stack(recipe.get("output", {}) as Dictionary)
	skills["crafting"] = float(skills.get("crafting", 0.0)) + 1.0
	return true


func serialize_progression(previous: Dictionary = {}) -> Dictionary:
	var data := previous.duplicate(true)
	data["unlocked_recipes"] = unlocked_recipes.duplicate(true)
	data["skills"] = skills.duplicate(true)
	data["research_samples"] = research_samples.duplicate(true)
	data["in_progress_crafts"] = in_progress_crafts.duplicate(true)
	return data


func restore_from_save(data: Dictionary) -> void:
	unlocked_recipes = (data.get("unlocked_recipes", unlocked_recipes) as Dictionary).duplicate(true)
	skills = (data.get("skills", skills) as Dictionary).duplicate(true)
	research_samples = (data.get("research_samples", {}) as Dictionary).duplicate(true)
	in_progress_crafts.clear()
	for craft_data in data.get("in_progress_crafts", []):
		if typeof(craft_data) == TYPE_DICTIONARY:
			in_progress_crafts.append((craft_data as Dictionary).duplicate(true))

