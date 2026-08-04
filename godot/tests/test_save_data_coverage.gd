extends SceneTree

## Round-trips get_save_data() -> load_save_data() for the four autoloads that were missing
## persistence entirely (GameFlow, Consequences, LocationManager, CaseFile).

var _done := false

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true

	var game_flow = root.get_node("GameFlow")
	var consequences = root.get_node("Consequences")
	var location_manager = root.get_node("LocationManager")
	var case_file = root.get_node("CaseFile")
	var failures := 0

	# GameFlow
	game_flow.phase = game_flow.Phase.ENDING
	game_flow.current_ending_id = "ending_riley"
	var gf_data: Dictionary = game_flow.get_save_data()
	game_flow.phase = game_flow.Phase.CHOICE
	game_flow.current_ending_id = ""
	game_flow.load_save_data(gf_data)
	if game_flow.phase != game_flow.Phase.ENDING or game_flow.current_ending_id != "ending_riley":
		failures += 1; print("FAIL: GameFlow save/load round trip")

	# Consequences
	consequences.strikes = 3
	consequences.set("_case_start_day", 7)
	var c_data: Dictionary = consequences.get_save_data()
	consequences.reset()
	consequences.load_save_data(c_data)
	if consequences.strikes != 3 or consequences.get("_case_start_day") != 7:
		failures += 1; print("FAIL: Consequences save/load round trip")

	# LocationManager
	location_manager.current_id = "police_station"
	var captured := {"dest": ""}
	location_manager.location_changing.connect(func(d): captured["dest"] = d)
	var lm_data: Dictionary = location_manager.get_save_data()
	location_manager.current_id = "dorm"
	location_manager.load_save_data(lm_data)
	if location_manager.current_id != "police_station":
		failures += 1; print("FAIL: LocationManager save/load round trip")
	if captured["dest"] != "police_station":
		failures += 1; print("FAIL: LocationManager.load_save_data should re-emit location_changing")

	# CaseFile
	case_file.resolved = true
	case_file.accused_id = "sam"
	var cf_data: Dictionary = case_file.get_save_data()
	case_file.resolved = false
	case_file.accused_id = ""
	case_file.load_save_data(cf_data)
	if case_file.resolved != true or case_file.accused_id != "sam":
		failures += 1; print("FAIL: CaseFile save/load round trip")

	if failures == 0:
		print("PASS: test_save_data_coverage")
	quit(failures)
	return true
