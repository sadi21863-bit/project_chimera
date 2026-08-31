extends Node

## Tracks strikes toward getting fired, and the case deadline. Reads Difficulty for the specific
## thresholds; GameFlow ends the run via ending_content's game-over endings.

signal strike_added(reason: String, count: int)

const DANGER_HOUR := 5.0  # deep night — the scripted, signposted danger window for Extreme

var strikes := 0
var _case_start_day := -1


func _ready() -> void:
	GameFlow.phase_changed.connect(_on_phase_changed)
	Scheduler.time_changed.connect(_on_time_changed)


func record_catch(hour: float) -> void:
	if GameFlow.phase != GameFlow.Phase.INVESTIGATION:
		return
	if str(Difficulty.get_value("consequence_ceiling", "standing")) == "death" and hour < DANGER_HOUR:
		GameFlow.trigger_ending("ending_death")
		return
	_add_strike("caught trespassing")


## A risky search action performed restricted or witnessed strikes; performed safely, it doesn't —
## matches RiskAssessor.assess()'s own classification (restricted-or-witnessed is never "safe").
func record_risky_search(restricted: bool, witnessed: bool) -> void:
	if GameFlow.phase != GameFlow.Phase.INVESTIGATION:
		return
	if not restricted and not witnessed:
		return
	_add_strike("botched intrusive search")


func trigger_walk_away() -> void:
	if GameFlow.phase != GameFlow.Phase.INVESTIGATION:
		return
	GameFlow.trigger_ending("ending_walk_away")


func trigger_sacrifice() -> void:
	if GameFlow.phase != GameFlow.Phase.INVESTIGATION:
		return
	GameFlow.trigger_ending("ending_sacrifice")


func reset() -> void:
	strikes = 0
	_case_start_day = -1


func get_save_data() -> Dictionary:
	return {"strikes": strikes, "case_start_day": _case_start_day}


func load_save_data(data: Dictionary) -> void:
	strikes = int(data.get("strikes", 0))
	_case_start_day = int(data.get("case_start_day", -1))


func _on_phase_changed(phase: int) -> void:
	if phase == GameFlow.Phase.INVESTIGATION and _case_start_day < 0:
		_case_start_day = Scheduler.game_day


func _on_time_changed(_hour: float, _minute: int, day: int) -> void:
	if GameFlow.phase != GameFlow.Phase.INVESTIGATION:
		return
	if not Difficulty.has_deadline() or _case_start_day < 0:
		return
	var deadline_day: int = _case_start_day + int(Difficulty.get_value("deadline_days", -1))
	if day > deadline_day:
		GameFlow.trigger_ending("ending_fired_deadline")


func _add_strike(reason: String) -> void:
	strikes += 1
	strike_added.emit(reason, strikes)
	EventLog.log_action("Strike (%s): %d" % [reason, strikes], "consequence")
	var threshold: int = int(Difficulty.get_value("strikes_to_fired", -1))
	if threshold > 0 and strikes >= threshold:
		GameFlow.trigger_ending("ending_fired_strikes")
