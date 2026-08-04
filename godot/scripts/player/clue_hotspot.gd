extends "res://scripts/player/interactable.gd"
class_name ClueHotspot

## An examinable clue. On first examine it records to the Investigation store + EventLog.
## Autoloads are resolved at runtime via the tree (not by global identifier) so this class
## parses safely both in-game and inside headless `-s` test scripts.

@export var clue_id: String = ""
@export var clue_title: String = ""
@export_multiline var clue_description: String = ""
@export var examined_prompt: String = "Examined"


func get_prompt() -> String:
	var store := _investigation()
	if clue_id != "" and store != null and store.is_discovered(clue_id):
		return examined_prompt
	return prompt_text


func interact() -> void:
	examine(_investigation())


## Store-injectable form so discovery logic is testable without the autoload.
func examine(store) -> void:
	if clue_id == "" or store == null:
		return
	if store.discover_clue(clue_id):
		_log("Found: %s" % clue_title)


func _investigation() -> Node:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null("Investigation")
	return null


func _log(text: String) -> void:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var node := (loop as SceneTree).root.get_node_or_null("EventLog")
		if node != null:
			node.call("log_action", text, "clue")
