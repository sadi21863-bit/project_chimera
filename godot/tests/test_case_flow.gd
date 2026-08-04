extends SceneTree

## End-to-end: discovering a suspect's clues (via the real Investigation autoload) raises
## CaseFile strength and unlocks the accusation, which returns the right ending.

var _phase := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var inv = root.get_node("Investigation")
		inv.reset()
		var cf = root.get_node("CaseFile")
		var failures := 0
		if cf.can_accuse("sam") != false:
			failures += 1; print("FAIL: sam not accusable initially")
		inv.discover_clue("clue_wiring")
		inv.discover_clue("clue_camera")
		if cf.case_strength("sam") != 2:
			failures += 1; print("FAIL: sam strength should be 2, got %d" % cf.case_strength("sam"))
		if cf.can_accuse("sam") != true:
			failures += 1; print("FAIL: sam should be accusable")
		var res: Dictionary = cf.accuse("sam")
		if res["accepted"] != true or res["ending_id"] != "ending_sam":
			failures += 1; print("FAIL: accuse sam should accept with ending_sam")
		if failures == 0:
			print("PASS: test_case_flow")
		quit(failures)
		return true
	return false
