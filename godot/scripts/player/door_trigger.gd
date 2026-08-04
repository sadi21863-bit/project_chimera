extends "res://scripts/player/interactable.gd"
class_name DoorTrigger

## A walk-through-door travel connection between two locations — an alternative to the fast-travel
## map for a specific pair of adjacent/thematically-linked places. Reuses LocationManager.travel(),
## so time still advances and the destination scene loads exactly like the fast-travel map does.

signal door_triggered(dest_id: String)

@export var dest_id := ""
@export var dest_label := "through the door"


func get_prompt() -> String:
	return "Go to %s" % dest_label


func interact() -> void:
	door_triggered.emit(dest_id)
