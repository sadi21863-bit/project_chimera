extends SceneTree

func _initialize() -> void:
	var gf = preload("res://autoload/game_flow.gd").new()
	var failures := 0
	if gf.phase != 0:  # CHOICE
		failures += 1; print("FAIL: should start in CHOICE")
	gf.choose_murder()
	if gf.phase != 1:  # INVESTIGATION
		failures += 1; print("FAIL: choose_murder should go INVESTIGATION")
	gf.trigger_ending("ending_sam")
	if gf.phase != 2 or gf.current_ending_id != "ending_sam":  # ENDING
		failures += 1; print("FAIL: trigger_ending should set ENDING + id")
	var gf2 = preload("res://autoload/game_flow.gd").new()
	gf2.choose_accident()
	if gf2.phase != 2 or gf2.current_ending_id != "ending_accident":
		failures += 1; print("FAIL: choose_accident should set ENDING + accident id")
	gf.free(); gf2.free()
	if failures == 0:
		print("PASS: test_game_flow")
	quit(failures)
