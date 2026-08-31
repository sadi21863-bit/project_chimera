extends CanvasLayer

## Difficulty/settings screen: pick a preset (Easy/Medium/Hard/Extreme), adjust audio
## volumes, and see the active rules.

signal closed()

@onready var _current: Label = $Panel/VBox/Current
@onready var _presets: VBoxContainer = $Panel/VBox/Presets

var _music_slider: HSlider = null
var _ambience_slider: HSlider = null
var _music_label: Label = null
var _ambience_label: Label = null


func _ready() -> void:
	for preset_name in ["easy", "medium", "hard", "extreme"]:
		var btn := Button.new()
		btn.text = preset_name.capitalize()
		btn.pressed.connect(_on_preset.bind(preset_name))
		_presets.add_child(btn)

	# volume section
	var sep := HSeparator.new()
	$Panel/VBox.add_child(sep)

	var vol_title := Label.new()
	vol_title.text = "Audio"
	vol_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$Panel/VBox.add_child(vol_title)

	_music_label = Label.new()
	_music_label.text = "Music: -6 dB"
	$Panel/VBox.add_child(_music_label)
	_music_slider = HSlider.new()
	_music_slider.min_value = -40.0
	_music_slider.max_value = 0.0
	_music_slider.step = 1.0
	_music_slider.value = -6.0
	_music_slider.value_changed.connect(_on_music_volume)
	$Panel/VBox.add_child(_music_slider)

	_ambience_label = Label.new()
	_ambience_label.text = "Ambience: -12 dB"
	$Panel/VBox.add_child(_ambience_label)
	_ambience_slider = HSlider.new()
	_ambience_slider.min_value = -40.0
	_ambience_slider.max_value = 0.0
	_ambience_slider.step = 1.0
	_ambience_slider.value = -12.0
	_ambience_slider.value_changed.connect(_on_ambience_volume)
	$Panel/VBox.add_child(_ambience_slider)

	$Panel/VBox/CloseButton.pressed.connect(_on_close)
	visible = false


func open() -> void:
	visible = true
	_refresh()
	_sync_volume_sliders()


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


func _sync_volume_sliders() -> void:
	var mm := get_node_or_null("/root/MusicManager")
	if mm == null:
		return
	_music_slider.value = mm.get_music_volume()
	_ambience_slider.value = mm.get_ambience_volume()
	_music_label.text = "Music: %d dB" % int(mm.get_music_volume())
	_ambience_label.text = "Ambience: %d dB" % int(mm.get_ambience_volume())


func _on_music_volume(value: float) -> void:
	_music_label.text = "Music: %d dB" % int(value)
	var mm := get_node_or_null("/root/MusicManager")
	if mm != null:
		mm.set_music_volume(value)


func _on_ambience_volume(value: float) -> void:
	_ambience_label.text = "Ambience: %d dB" % int(value)
	var mm := get_node_or_null("/root/MusicManager")
	if mm != null:
		mm.set_ambience_volume(value)


func _on_close() -> void:
	visible = false
	closed.emit()
