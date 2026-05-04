extends VBoxContainer

signal back_requested


func _on_back_pressed() -> void:
	back_requested.emit()
