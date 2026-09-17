extends CanvasLayer

## Persistent investigation HUD: location, in-world clock, evidence count and controls.
## It deliberately stays compact so the isometric play space remains dominant.

@onready var _location_label: Label = $TopBar/LocationPanel/Margin/Column/Location
@onready var _phase_label: Label = $TopBar/LocationPanel/Margin/Column/Phase
@onready var _time_label: Label = $TopBar/TimePanel/Margin/Column/Time
@onready var _day_label: Label = $TopBar/TimePanel/Margin/Column/Day
@onready var _evidence_label: Label = $EvidencePanel/Margin/Column/Evidence
@onready var _status_label: Label = $EvidencePanel/Margin/Column/Status

var _time_pulse := 0.0

func _ready() -> void:
	visible = false
	var scheduler := get_node_or_null("/root/Scheduler")
	if scheduler != null:
		scheduler.time_changed.connect(_on_time_changed)
		scheduler.paused_changed.connect(_on_paused_changed)
		_on_time_changed(scheduler.get_hour(), scheduler.get_minute_int(), scheduler.game_day)
	var location_manager := get_node_or_null("/root/LocationManager")
	if location_manager != null:
		location_manager.location_changing.connect(_on_location_changed)
		_on_location_changed(location_manager.current_id)
	var game_flow := get_node_or_null("/root/GameFlow")
	if game_flow != null:
		game_flow.phase_changed.connect(_on_phase_changed)
		_on_phase_changed(game_flow.phase)
	var investigation := get_node_or_null("/root/Investigation")
	if investigation != null:
		investigation.clue_discovered.connect(_on_clue_discovered)
		_on_clue_discovered("")
	var case_file := get_node_or_null("/root/CaseFile")
	if case_file != null and investigation != null:
		# Refresh the ready-state after clues arrive without adding another global timer.
		pass
	set_process(true)

func _process(delta: float) -> void:
	_time_pulse += delta
	if _status_label.visible and _status_label.text == "● CASE READY":
		_status_label.modulate.a = 0.86 + sin(_time_pulse * 3.0) * 0.14

func _on_phase_changed(phase: int) -> void:
	visible = phase == GameFlow.Phase.INVESTIGATION
	if phase == GameFlow.Phase.INVESTIGATION:
		_phase_label.text = "ACTIVE INVESTIGATION"

func _on_time_changed(hour: float, minute: int, day: int) -> void:
	var h := int(hour)
	var suffix := "AM" if h < 12 else "PM"
	var display_h := h % 12
	if display_h == 0:
		display_h = 12
	_time_label.text = "%d:%02d %s" % [display_h, minute, suffix]
	_day_label.text = "DAY %d  •  %s" % [day, _time_of_day(hour)]

func _on_paused_changed(paused: bool) -> void:
	if paused:
		_day_label.text += "  •  PAUSED"

func _on_location_changed(location_id: String) -> void:
	var lm := get_node_or_null("/root/LocationManager")
	if lm != null:
		_location_label.text = str(lm.location_name(location_id)).to_upper()

func _on_clue_discovered(_clue_id: String) -> void:
	var investigation := get_node_or_null("/root/Investigation")
	var case_file := get_node_or_null("/root/CaseFile")
	var found: int = investigation.discovered_count() if investigation != null else 0
	var total := CaseData.CLUES.size()
	_evidence_label.text = "EVIDENCE  %02d / %02d" % [found, total]
	var ready: bool = case_file != null and case_file.accusations_unlocked()
	_status_label.visible = ready or found > 0
	_status_label.text = "● CASE READY" if ready else "CASE DEVELOPING"
	_status_label.modulate = Color("#f2d27a") if ready else Color("#8e9aa7")

func _time_of_day(hour: float) -> String:
	if hour < 6.0:
		return "NIGHT"
	if hour < 12.0:
		return "MORNING"
	if hour < 18.0:
		return "AFTERNOON"
	return "EVENING"
