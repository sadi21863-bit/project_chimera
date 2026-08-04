extends Node

## Minimal discovered-clue store for the exploration slice.
## Plan B's CaseFile will build on this (case strength, accusation gating).

signal clue_discovered(clue_id: String)

const SAVE_PATH := "user://investigation.json"

var persist_enabled := true
var _discovered: Dictionary = {}  # clue_id -> true


func _ready() -> void:
	if persist_enabled:
		_load()


func discover_clue(clue_id: String) -> bool:
	if clue_id.is_empty() or _discovered.has(clue_id):
		return false
	_discovered[clue_id] = true
	clue_discovered.emit(clue_id)
	if persist_enabled:
		_save()
	return true


func is_discovered(clue_id: String) -> bool:
	return _discovered.has(clue_id)


func discovered_count() -> int:
	return _discovered.size()


func reset() -> void:
	_discovered.clear()
	if persist_enabled:
		_save()


func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_discovered))


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_discovered = parsed
