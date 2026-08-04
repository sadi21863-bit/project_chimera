extends CanvasLayer

## Simple dialog bubble overlay (self-contained).

signal dialog_closed

var _panel: PanelContainer
var _speaker: Label
var _text: Label
var _timer: Timer


func _ready() -> void:
	layer = 10
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.offset_left = -250
	_panel.offset_right = 250
	_panel.offset_top = -120
	_panel.offset_bottom = -20
	add_child(_panel)

	var vbox := VBoxContainer.new()
	_panel.add_child(vbox)

	_speaker = Label.new()
	_speaker.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_speaker)

	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_text)

	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_hide)


func show_dialogue(speaker: String, text: String, duration: float = 4.0) -> void:
	_speaker.text = speaker
	_text.text = text
	_panel.visible = true
	_timer.start(duration)


func _hide() -> void:
	_panel.visible = false
	dialog_closed.emit()
