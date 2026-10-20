extends CanvasLayer

## Difficulty/settings screen: pick a preset (Easy/Medium/Hard/Extreme), adjust audio
## volumes, and see the active rules.

signal closed()

const ModelCatalog := preload("res://scripts/ai/model_catalog.gd")
const ModelDownloadScript := preload("res://autoload/model_download.gd")

@onready var _current: Label = $Panel/VBox/Current
@onready var _presets: VBoxContainer = $Panel/VBox/Presets

var _music_slider: HSlider = null
var _ambience_slider: HSlider = null
var _music_label: Label = null
var _ambience_label: Label = null

var _manager = null
var _local_choice: OptionButton = null
var _local_download: Button = null
var _local_pause: Button = null
var _local_resume: Button = null
var _local_cancel: Button = null
var _local_delete: Button = null
var _local_enable: Button = null
var _local_progress: ProgressBar = null
var _local_status: Label = null
var _local_attr: Label = null
var _choice_keys: Array = []
var _selected_key: String = ""
var _cancel_armed := false
var _delete_armed := false


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

	_build_local_ai_section()

	$Panel/VBox/CloseButton.pressed.connect(_on_close)
	visible = false


func _build_local_ai_section() -> void:
	var sep := HSeparator.new()
	$Panel/VBox.add_child(sep)

	var title := Label.new()
	title.text = "Local AI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$Panel/VBox.add_child(title)

	_local_status = Label.new()
	_local_status.name = "LocalStatus"
	_local_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	$Panel/VBox.add_child(_local_status)

	_choice_keys = ModelCatalog.REQUIREMENTS.keys()
	if _choice_keys.size() > 1:
		_local_choice = OptionButton.new()
		_local_choice.name = "LocalChoice"
		for k in _choice_keys:
			var entry: Dictionary = ModelCatalog.REQUIREMENTS[k]
			_local_choice.add_item("%s (%s)" % [str(k), ModelCatalog.human_size(int(entry.get("size_bytes", 0)))])
		_selected_key = str(_choice_keys[_local_choice.selected]) if _local_choice.selected >= 0 else ""
		_local_choice.item_selected.connect(_on_local_choice)
		$Panel/VBox.add_child(_local_choice)
	if _selected_key.is_empty() and not _choice_keys.is_empty():
		_selected_key = str(_choice_keys[0])

	_local_download = Button.new()
	_local_download.name = "LocalDownload"
	_local_download.pressed.connect(_on_local_download)
	$Panel/VBox.add_child(_local_download)

	var row := HBoxContainer.new()
	row.name = "LocalRow"
	$Panel/VBox.add_child(row)

	_local_pause = Button.new()
	_local_pause.name = "LocalPause"
	_local_pause.text = "Pause"
	_local_pause.pressed.connect(_on_local_pause)
	row.add_child(_local_pause)

	_local_resume = Button.new()
	_local_resume.name = "LocalResume"
	_local_resume.text = "Resume"
	_local_resume.pressed.connect(_on_local_resume)
	row.add_child(_local_resume)

	_local_cancel = Button.new()
	_local_cancel.name = "LocalCancel"
	_local_cancel.text = "Cancel"
	_local_cancel.pressed.connect(_on_local_cancel)
	row.add_child(_local_cancel)

	_local_delete = Button.new()
	_local_delete.name = "LocalDelete"
	_local_delete.text = "Delete model"
	_local_delete.pressed.connect(_on_local_delete)
	row.add_child(_local_delete)

	_local_enable = Button.new()
	_local_enable.name = "LocalEnable"
	_local_enable.text = "Enable Local AI"
	_local_enable.pressed.connect(_on_local_enable)
	$Panel/VBox.add_child(_local_enable)

	_local_progress = ProgressBar.new()
	_local_progress.name = "LocalProgress"
	_local_progress.min_value = 0.0
	_local_progress.max_value = 1.0
	$Panel/VBox.add_child(_local_progress)

	_local_attr = Label.new()
	_local_attr.name = "LocalAttribution"
	_local_attr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	$Panel/VBox.add_child(_local_attr)

	_manager = get_node_or_null("/root/ModelDownload")
	_connect_manager()


func bind_manager(manager) -> void:
	if _manager != null:
		_unbind_signals(_manager)
	_manager = manager
	_connect_manager()
	_refresh_local_ai()


func _connect_manager() -> void:
	if _manager == null:
		return
	_manager.state_changed.connect(_on_local_state)
	_manager.progress_changed.connect(_on_local_progress)
	_manager.finished.connect(_on_local_finished)


func _unbind_signals(manager) -> void:
	if manager.state_changed.is_connected(_on_local_state):
		manager.state_changed.disconnect(_on_local_state)
	if manager.progress_changed.is_connected(_on_local_progress):
		manager.progress_changed.disconnect(_on_local_progress)
	if manager.finished.is_connected(_on_local_finished):
		manager.finished.disconnect(_on_local_finished)


func open() -> void:
	visible = true
	_refresh()
	_sync_volume_sliders()
	_refresh_local_ai()


func _on_local_choice(idx: int) -> void:
	if idx >= 0 and idx < _choice_keys.size():
		_selected_key = str(_choice_keys[idx])
	_refresh_local_ai()


func _on_local_download() -> void:
	if _selected_key.is_empty():
		return
	if _manager != null:
		_manager.start(_selected_key)
	_refresh_local_ai()


func _on_local_pause() -> void:
	if _manager != null:
		_manager.pause()
	_refresh_local_ai()


func _on_local_resume() -> void:
	if _manager != null:
		_manager.resume()
	_refresh_local_ai()


func _on_local_cancel() -> void:
	if not _cancel_armed:
		_cancel_armed = true
		_local_cancel.text = "Cancel (press again)"
		return
	_cancel_armed = false
	_local_cancel.text = "Cancel"
	if _manager != null:
		_manager.cancel()
	_refresh_local_ai()


func _on_local_delete() -> void:
	if not _delete_armed:
		_delete_armed = true
		_local_delete.text = "Delete (press again)"
		return
	_delete_armed = false
	_local_delete.text = "Delete model"
	if _manager != null:
		_manager.delete_model(_selected_key)
	_refresh_local_ai()


func _on_local_enable() -> void:
	LocalAI.enable()
	_refresh_local_ai()


func _on_local_state(_state: int, _detail: String) -> void:
	_refresh_local_ai()


func _on_local_finished(_ok: bool, _detail: String) -> void:
	_refresh_local_ai()


func _on_local_progress(recvd: int, total: int) -> void:
	if _local_progress == null:
		return
	if total > 0:
		_local_progress.max_value = float(total)
		_local_progress.value = float(mini(recvd, total))


func _progress_key() -> String:
	if _manager != null and _manager.is_busy() and str(_manager.active_key) != "":
		return str(_manager.active_key)
	return _selected_key


func _refresh_local_ai() -> void:
	if _local_status == null:
		return
	var available: bool = AIClient.local_available()
	var runtime_shipped: bool = LocalAI.dll_path() != ""
	var key := _selected_key
	var entry: Dictionary = ModelCatalog.REQUIREMENTS.get(key, {})
	var size := int(entry.get("size_bytes", 0))
	var st := ModelDownloadScript.State.IDLE
	var detail_text := ""
	var prog := Vector2i(0, 0)
	var prog_size := 0
	var installed := false
	var busy_other := false
	if _manager != null:
		st = int(_manager.entry_state(key))
		detail_text = str(_manager.detail(key))
		installed = _manager.is_model_present(key)
		busy_other = _manager.is_busy() and str(_manager.active_key) != "" and str(_manager.active_key) != key
	var display_key := str(_manager.active_key) if (busy_other and _manager != null) else key
	var display_entry: Dictionary = ModelCatalog.REQUIREMENTS.get(display_key, {})
	prog_size = int(display_entry.get("size_bytes", 0))
	prog = _manager.last_progress(display_key) if _manager != null else Vector2i(0, 0)
	_local_attr.text = "%s — License: %s" % [
		str(entry.get("source", "")), str(entry.get("license", "")),
	]

	var download_visible := runtime_shipped
	var delete_visible := false
	var pause_visible := false
	var resume_visible := false
	var cancel_visible := false
	var download_enabled := true
	var progress_visible := false
	var enable_visible := false
	if not runtime_shipped:
		_local_status.text = "Local AI runtime is not included in this build."
	elif installed or st == ModelDownloadScript.State.DONE:
		if available:
			_local_status.text = "Installed. LOCAL mode active next decision."
		else:
			_local_status.text = "Model installed. Enable Local AI to run decisions locally."
			enable_visible = true
		delete_visible = not busy_other
		download_visible = false
	elif st == ModelDownloadScript.State.CHECKING or st == ModelDownloadScript.State.PROBING:
		_local_status.text = "Preparing download…"
		cancel_visible = true
		progress_visible = true
		download_visible = false
	elif st == ModelDownloadScript.State.DOWNLOADING:
		_local_status.text = "Downloading… %s / %s" % [
			ModelCatalog.human_size(prog.x), ModelCatalog.human_size(prog_size),
		]
		pause_visible = true
		cancel_visible = true
		progress_visible = true
		download_visible = false
	elif st == ModelDownloadScript.State.PAUSED:
		if detail_text == "disk_low":
			_local_status.text = "Paused — not enough free disk space (need ~%s)." % ModelCatalog.human_size(prog_size * 2)
		elif detail_text == "network_dropout" or detail_text == "paused":
			_local_status.text = "Paused — network restarted. Press resume to continue."
		else:
			_local_status.text = "Paused (%s)." % detail_text
		resume_visible = true
		cancel_visible = true
		progress_visible = true
		download_visible = false
	elif st == ModelDownloadScript.State.VERIFYING:
		_local_status.text = "Verifying integrity…"
		progress_visible = true
		download_visible = false
	elif st == ModelDownloadScript.State.PROMOTING:
		_local_status.text = "Installing model…"
		progress_visible = true
		download_visible = false
	elif st == ModelDownloadScript.State.FAILED:
		_local_status.text = "Download failed (%s)." % detail_text
		progress_visible = true
	elif busy_other:
		_local_status.text = "Downloading another model (%s)…" % display_key
		download_enabled = false
		progress_visible = true
	else:
		_local_status.text = "Not installed. Downloading needs ~%s free." % ModelCatalog.human_size(size)
	if progress_visible:
		_local_progress.max_value = float(prog_size) if prog_size > 0 else 1.0
		_local_progress.value = float(mini(prog.x, prog_size)) if prog_size > 0 else 0.0

	_set_choice_enabled(runtime_shipped and not busy_other)
	_local_download.visible = download_visible
	_local_download.disabled = not download_enabled
	_local_pause.visible = pause_visible
	_local_resume.visible = resume_visible
	_local_cancel.visible = cancel_visible
	_local_delete.visible = delete_visible
	_local_enable.visible = enable_visible
	_local_progress.visible = progress_visible


func _set_choice_enabled(enabled: bool) -> void:
	if _local_choice != null:
		_local_choice.disabled = not enabled


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
