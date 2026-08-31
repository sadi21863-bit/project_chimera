extends Node

## Phase state machine for the story: the First Choice, investigation, and the ending.

enum Phase { CHOICE, INVESTIGATION, ENDING }

signal phase_changed(phase: int)

var phase: Phase = Phase.CHOICE
var current_ending_id := ""


func choose_accident() -> void:
	if phase == Phase.ENDING:
		return
	current_ending_id = "ending_accident"
	_set_phase(Phase.ENDING)


func choose_murder() -> void:
	if phase == Phase.ENDING:
		return
	_set_phase(Phase.INVESTIGATION)


func trigger_ending(ending_id: String) -> void:
	# Terminal state: once ended, nothing (scheduled events racing the deadline,
	# late UI signals, double accusations) may overwrite the outcome.
	if phase == Phase.ENDING:
		return
	current_ending_id = ending_id
	_set_phase(Phase.ENDING)


func _set_phase(p: Phase) -> void:
	phase = p
	phase_changed.emit(p)


func get_save_data() -> Dictionary:
	return {"phase": phase, "current_ending_id": current_ending_id}


func load_save_data(data: Dictionary) -> void:
	phase = int(data.get("phase", Phase.CHOICE)) as Phase
	current_ending_id = str(data.get("current_ending_id", ""))
	phase_changed.emit(phase)


func reset() -> void:
	phase = Phase.CHOICE
	current_ending_id = ""
	phase_changed.emit(phase)
