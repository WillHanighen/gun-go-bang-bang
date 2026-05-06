class_name PlayerVitals
extends Node

signal vitals_changed(snapshot: Dictionary)
signal died(reason: String)

const HEALTH_MAX := 100.0
const STAMINA_MAX := 100.0
const HUNGER_MAX := 100.0
const THIRST_MAX := 100.0
const TEMPERATURE_NEUTRAL := 50.0
const FATIGUE_MAX := 100.0
const INFECTION_MAX := 100.0

var health := HEALTH_MAX
var stamina := STAMINA_MAX
var hunger := HUNGER_MAX
var thirst := THIRST_MAX
var temperature := TEMPERATURE_NEUTRAL
var fatigue := 0.0
var infection := 0.0
var injuries: Array[String] = []
var dead := false

var survival_drain_enabled := true
var _emit_timer := 0.0


func _ready() -> void:
	emit_changed()


func _process(delta: float) -> void:
	if dead or not survival_drain_enabled:
		return
	hunger = maxf(hunger - 0.012 * delta, 0.0)
	thirst = maxf(thirst - 0.018 * delta, 0.0)
	fatigue = minf(fatigue + 0.004 * delta, FATIGUE_MAX)
	if infection > 0.0:
		infection = minf(infection + 0.08 * delta, INFECTION_MAX)
		if infection >= INFECTION_MAX:
			kill("infection")

	_emit_timer -= delta
	if _emit_timer <= 0.0:
		_emit_timer = 0.25
		emit_changed()


func update_movement(delta: float, is_sprinting: bool, movement_amount: float) -> void:
	if dead:
		return
	if is_sprinting and movement_amount > 0.01:
		stamina = maxf(stamina - 18.0 * delta, 0.0)
	else:
		stamina = minf(stamina + 12.0 * delta, STAMINA_MAX)
	emit_changed()


func can_sprint() -> bool:
	return not dead and stamina > 8.0


func take_damage(amount: float, reason: String = "damage") -> void:
	if dead:
		return
	health = maxf(health - maxf(amount, 0.0), 0.0)
	if health <= 0.0:
		kill(reason)
	else:
		emit_changed()


func apply_infection(amount: float) -> void:
	if dead:
		return
	infection = minf(infection + maxf(amount, 0.0), INFECTION_MAX)
	emit_changed()


func reset_after_respawn(respawn_injury: bool = true) -> void:
	dead = false
	health = HEALTH_MAX
	stamina = STAMINA_MAX
	hunger = maxf(hunger, 35.0)
	thirst = maxf(thirst, 35.0)
	temperature = TEMPERATURE_NEUTRAL
	fatigue = minf(fatigue + 8.0, FATIGUE_MAX)
	infection = 0.0
	injuries.clear()
	if respawn_injury:
		injuries.append("respawn wobble")
	emit_changed()


func kill(reason: String = "damage") -> void:
	if dead:
		return
	dead = true
	health = 0.0
	emit_changed()
	died.emit(reason)


func get_snapshot() -> Dictionary:
	return {
		"health": health,
		"stamina": stamina,
		"hunger": hunger,
		"thirst": thirst,
		"temperature": temperature,
		"fatigue": fatigue,
		"infection": infection,
		"injuries": injuries.duplicate(),
		"dead": dead,
	}


func restore_from_save(data: Dictionary) -> void:
	health = clampf(float(data.get("health", HEALTH_MAX)), 0.0, HEALTH_MAX)
	stamina = clampf(float(data.get("stamina", STAMINA_MAX)), 0.0, STAMINA_MAX)
	hunger = clampf(float(data.get("hunger", HUNGER_MAX)), 0.0, HUNGER_MAX)
	thirst = clampf(float(data.get("thirst", THIRST_MAX)), 0.0, THIRST_MAX)
	temperature = clampf(float(data.get("temperature", TEMPERATURE_NEUTRAL)), 0.0, 100.0)
	fatigue = clampf(float(data.get("fatigue", 0.0)), 0.0, FATIGUE_MAX)
	infection = clampf(float(data.get("infection", 0.0)), 0.0, INFECTION_MAX)
	injuries.clear()
	for injury in data.get("injuries", []):
		injuries.append(str(injury))
	dead = bool(data.get("dead", false))
	emit_changed()


func emit_changed() -> void:
	vitals_changed.emit(get_snapshot())

