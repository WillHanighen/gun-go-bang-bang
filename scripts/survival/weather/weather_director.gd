class_name WeatherDirector
extends Node

signal weather_changed(weather: String)

const GROUP := "survival_weather_director"

var elapsed_seconds := 0.0
var time_of_day := 8.0
var weather := "clear"
var temperature_modifier := 0.0
var rain_collector_mult := 1.0


func _ready() -> void:
	add_to_group(GROUP)


func _process(delta: float) -> void:
	elapsed_seconds += delta
	time_of_day = fmod(8.0 + elapsed_seconds / 60.0, 24.0)
	var next_weather := _weather_for_time()
	if next_weather != weather:
		weather = next_weather
		weather_changed.emit(weather)
	_update_modifiers()


func is_night() -> bool:
	return time_of_day >= 20.0 or time_of_day < 6.0


func serialize_weather(previous: Dictionary = {}) -> Dictionary:
	var data := previous.duplicate(true)
	data["elapsed_seconds"] = elapsed_seconds
	data["time_of_day"] = time_of_day
	data["weather"] = weather
	data["temperature_modifier"] = temperature_modifier
	data["rain_collector_mult"] = rain_collector_mult
	return data


func restore_from_save(data: Dictionary) -> void:
	elapsed_seconds = float(data.get("elapsed_seconds", 0.0))
	time_of_day = float(data.get("time_of_day", 8.0))
	weather = str(data.get("weather", "clear"))
	_update_modifiers()


func _weather_for_time() -> String:
	var cycle := int(elapsed_seconds / 90.0) % 5
	match cycle:
		1:
			return "rain"
		2:
			return "fog"
		3:
			return "cold_front"
		_:
			return "clear"


func _update_modifiers() -> void:
	match weather:
		"rain":
			temperature_modifier = -4.0
			rain_collector_mult = 2.5
		"fog":
			temperature_modifier = -1.5
			rain_collector_mult = 1.0
		"cold_front":
			temperature_modifier = -8.0
			rain_collector_mult = 1.0
		_:
			temperature_modifier = -5.0 if is_night() else 0.0
			rain_collector_mult = 1.0

