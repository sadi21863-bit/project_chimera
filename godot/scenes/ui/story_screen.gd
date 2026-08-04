extends CanvasLayer

## The framing screens: the First Choice (accident vs murder) and the ending + flashback.

signal choice_made(is_murder: bool)
signal settings_requested()

@onready var _title: Label = $Center/VBox/Title
@onready var _body: Label = $Center/VBox/Body
@onready var _buttons: HBoxContainer = $Center/VBox/Buttons


func _ready() -> void:
	$Center/VBox/Buttons/AccidentButton.pressed.connect(func(): choice_made.emit(false))
	$Center/VBox/Buttons/MurderButton.pressed.connect(func(): choice_made.emit(true))
	$Center/VBox/Buttons/SettingsButton.pressed.connect(func(): settings_requested.emit())
	hide_screen()


func show_choice() -> void:
	visible = true
	_buttons.visible = true
	_title.text = "Crestwood Hall — A Death"
	_body.text = ("The police called it an accident, and the dorm has already begun to move on. "
		+ "But the Crestwood family — whose name is on the building — wants a murderer found, "
		+ "and they've brought in you.\n\nWhat is your finding?")


func show_ending(ending_id: String, discovered_clue_ids: Array) -> void:
	visible = true
	_buttons.visible = false
	var ending: Dictionary = EndingContent.ending_for(ending_id)
	_title.text = str(ending.get("title", "The End"))
	var text: String = str(ending.get("body", ""))
	if ending_id != "ending_accident":
		text += "\n\n— THE TRUTH —\n"
		text += "It was an accident. Every sign you read as guilt was something innocent:\n"
		for entry in EndingContent.build_flashback(discovered_clue_ids):
			text += "\n• %s: %s" % [str(entry["title"]), str(entry["truth"])]
		text += "\n\nYou were the only thing that turned a tragedy into a crime."
	_body.text = text


func hide_screen() -> void:
	visible = false
