extends Node

## The detective's standing (trust) with each NPC, in [-1, 1]. Starts neutral/skeptical (0).
## Accusations drop it (CaseFile applies the fallout); investigation progress can raise it later.

signal standing_changed(npc_id: String, value: float)

const SAVE_PATH := "user://standing.json"

var persist_enabled := true
var _standing: Dictionary = {}  # npc_id -> float


func _ready() -> void:
	if persist_enabled:
		_load()


func get_standing(npc_id: String) -> float:
	return float(_standing.get(npc_id, 0.0))


func adjust(npc_id: String, delta: float) -> float:
	var v: float = clampf(get_standing(npc_id) + delta, -1.0, 1.0)
	_standing[npc_id] = v
	standing_changed.emit(npc_id, v)
	if persist_enabled:
		_save()
	return v


func reset() -> void:
	_standing.clear()
	if persist_enabled:
		_save()


func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_standing))


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_standing = parsed
