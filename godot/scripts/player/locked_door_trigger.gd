extends "res://scripts/player/door_trigger.gd"
class_name LockedDoorTrigger

## A DoorTrigger gated behind a discovered clue/item (reuses Investigation's persisted
## boolean-flag store as a lightweight inventory check — see the suspect-bedrooms plan doc).

@export var required_clue := ""
@export var locked_message := "The door is locked."


func _is_unlocked() -> bool:
	return required_clue.is_empty() or Investigation.is_discovered(required_clue)


func get_prompt() -> String:
	if not _is_unlocked():
		return "Locked"
	return super.get_prompt()


func interact() -> void:
	if not _is_unlocked():
		EventLog.log_action(locked_message, "system")
		return
	super.interact()
