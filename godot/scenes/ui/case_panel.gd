extends CanvasLayer

## The detective's case board: each suspect with case strength and an evidence-gated Accuse button.

signal accuse_requested(suspect_id: String)

@onready var _rows: VBoxContainer = $Panel/VBox/Rows
@onready var _title: Label = $Panel/VBox/Title

var _accuse_buttons: Dictionary = {}  # suspect_id -> Button


func set_open(open: bool) -> void:
	visible = open


func find_accuse_button(suspect_id: String) -> Button:
	return _accuse_buttons.get(suspect_id, null)


func refresh(case_file: Node) -> void:
	for child in _rows.get_children():
		child.queue_free()
	_accuse_buttons.clear()
	var unlocked: bool = case_file.accusations_unlocked()
	_title.text = "CASE FILE" if unlocked else "CASE FILE — investigate every resident before you can accuse"
	for suspect_id in CaseData.SUSPECTS:
		var info: Dictionary = CaseData.SUSPECTS[suspect_id]
		var strength: int = case_file.case_strength(suspect_id)
		var threshold: int = info["threshold"]
		var can: bool = case_file.can_accuse(suspect_id)

		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = "%s — evidence %d/%d" % [str(info["name"]), strength, threshold]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var btn := Button.new()
		btn.text = "Accuse"
		btn.disabled = not (can and unlocked)
		btn.pressed.connect(_on_accuse_pressed.bind(suspect_id))
		row.add_child(btn)

		_rows.add_child(row)
		_accuse_buttons[suspect_id] = btn


func _on_accuse_pressed(suspect_id: String) -> void:
	accuse_requested.emit(suspect_id)
