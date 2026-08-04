extends SceneTree

var _phase := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		var gf = root.get_node("GameFlow")
		var inv = root.get_node("Investigation"); inv.reset()
		var failures := 0

		if gf.phase != 0:
			failures += 1; print("FAIL: should start at CHOICE")
		main._on_choice_made(true)
		if gf.phase != 1:
			failures += 1; print("FAIL: choosing murder should go INVESTIGATION")
		main._on_accuse_requested("sam")
		if gf.phase != 1:
			failures += 1; print("FAIL: baseless accusation should not end the game")
		inv.discover_clue("clue_wiring"); inv.discover_clue("clue_camera")
		main._on_accuse_requested("sam")
		if gf.phase != 2 or gf.current_ending_id != "ending_sam":
			failures += 1; print("FAIL: built accusation should trigger ending_sam")

		if failures == 0:
			print("PASS: test_flow_wiring")
		quit(failures)
		return true
	return false
