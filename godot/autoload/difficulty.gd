extends Node

## The difficulty spine: a preset table that parameterizes deadline, catch model, consequences,
## risk hints, and search risk. Every other system (deadline, sneaking, consequences, examination)
## reads from here. The player picks a preset or overrides individual fields in Settings.

signal changed()

const PRESETS := {
	"easy":    {"deadline_days": -1, "catch_model": "off",    "consequence_ceiling": "standing", "risk_hints": "explicit", "strikes_to_fired": -1, "careless_search_risk": "none"},
	"medium":  {"deadline_days": 14, "catch_model": "meter",  "consequence_ceiling": "fired",    "risk_hints": "shown",    "strikes_to_fired": 5,  "careless_search_risk": "minor"},
	"hard":    {"deadline_days": 10, "catch_model": "vision", "consequence_ceiling": "fired",    "risk_hints": "subtle",   "strikes_to_fired": 3,  "careless_search_risk": "risky"},
	"extreme": {"deadline_days": 7,  "catch_model": "vision", "consequence_ceiling": "death",    "risk_hints": "hidden",   "strikes_to_fired": 2,  "careless_search_risk": "risky"},
}

const SAVE_PATH := "user://difficulty.json"

var persist_enabled := true
var preset := "medium"
var settings: Dictionary = {}


func _ready() -> void:
	if persist_enabled:
		_load()
	if settings.is_empty():
		set_preset("medium")


func set_preset(name: String) -> void:
	if not PRESETS.has(name):
		return
	preset = name
	settings = PRESETS[name].duplicate(true)
	if persist_enabled:
		_save()
	changed.emit()


func override(field: String, value: Variant) -> void:
	settings[field] = value
	preset = "custom"
	if persist_enabled:
		_save()
	changed.emit()


func get_value(field: String, default_value: Variant = null) -> Variant:
	return settings.get(field, default_value)


func has_deadline() -> bool:
	return int(settings.get("deadline_days", -1)) > 0


func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"preset": preset, "settings": settings}))


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		preset = str(parsed.get("preset", "medium"))
		var s: Variant = parsed.get("settings", {})
		if s is Dictionary:
			settings = s
