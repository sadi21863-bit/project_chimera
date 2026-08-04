extends "res://scripts/player/interactable.gd"
class_name RestPoint

## Advances the day counter. Lives in the detective's room (the sim's "rest" hub).

signal rest_requested()


func get_prompt() -> String:
	return "Rest (advance a day)"


func interact() -> void:
	rest_requested.emit()
