extends Node

## Save/load manager using JSON files (Locker-compatible API stub).

const SAVE_DIR := "user://chimera_saves/"
const DEFAULT_SLOT := "slot_1"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func save_game(slot: String, data: Dictionary) -> bool:
	var path := SAVE_DIR + slot + ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to save: %s" % path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	EventLog.log_action("Game saved to %s" % slot, "system")
	return true


func load_game(slot: String) -> Dictionary:
	var path := SAVE_DIR + slot + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		EventLog.log_action("Game loaded from %s" % slot, "system")
		return parsed
	return {}


func list_slots() -> Array[String]:
	var slots: Array[String] = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var name := dir.get_next()
		while name != "":
			if name.ends_with(".json"):
				slots.append(name.trim_suffix(".json"))
			name = dir.get_next()
	return slots
