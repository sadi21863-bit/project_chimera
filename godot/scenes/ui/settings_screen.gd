extends CanvasLayer

## Difficulty/settings screen: pick a preset (Easy/Medium/Hard/Extreme) and see the active rules.
## Field-level overrides can be added later; presets cover the spine.

signal closed()

@onready var _current: Label = $Panel/VBox/Current
@onready var _presets: VBoxContainer = $Panel/VBox/Presets


func _ready() -> void:
	for preset_name in ["easy", "medium", "hard", "extreme"]:
		var btn := Button.new()
		btn.text = preset_name.capitalize()
		btn.pressed.connect(_on_preset.bind(preset_name))
		_presets.add_child(btn)
	$Panel/VBox/CloseButton.pressed.connect(_on_close)
	visible = false


func open() -> void:
	visible = true
	_refresh()


func _on_preset(preset_name: String) -> void:
	Difficulty.set_preset(preset_name)
	_refresh()


func _refresh() -> void:
	var dd: int = int(Difficulty.get_value("deadline_days", -1))
	var deadline_text: String = "no deadline" if dd <= 0 else "%d days" % dd
	_current.text = "Difficulty: %s\nDeadline: %s\nGetting caught: %s\nWorst consequence: %s" % [
		str(Difficulty.preset).capitalize(),
		deadline_text,
		str(Difficulty.get_value("catch_model", "off")),
		str(Difficulty.get_value("consequence_ceiling", "standing")),
	]


func _on_close() -> void:
	visible = false
	closed.emit()
