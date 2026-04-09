extends Node3D
## Oscillates along local X (lateral strafe) for gun-range movers.

@export var speed: float = 1.2
@export var amplitude: float = 0.8

var _phase: float = 0.0
var _base_x: float = 0.0


func _ready() -> void:
	_base_x = position.x
	_phase = randf() * TAU


func _physics_process(delta: float) -> void:
	_phase += speed * delta
	position.x = _base_x + sin(_phase) * amplitude
