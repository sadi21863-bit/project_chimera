extends "res://scripts/player/interactable.gd"
class_name NpcInteractable

## Talking to an NPC now opens interrogation (Plan C). This emits a request; main.gd opens the
## InterrogationPanel for the matching suspect.

signal talk_requested(suspect_id: String)

@export var npc_name := "Someone"
@export var npc_id := ""


func get_prompt() -> String:
	return "Talk to %s" % npc_name


func interact() -> void:
	talk_requested.emit(npc_id)
