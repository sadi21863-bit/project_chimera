extends "res://scripts/player/interactable.gd"
class_name SearchPoint

## An examinable object with detailed actions. Examining (E) opens the SearchPanel for its point.

signal search_requested(point_id: String)

@export var point_id := ""
@export var label := "something"


func get_prompt() -> String:
	return "Search %s" % label


func interact() -> void:
	search_requested.emit(point_id)
