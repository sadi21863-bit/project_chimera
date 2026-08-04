extends SceneTree

func _initialize() -> void:
	var inv = preload("res://autoload/investigation.gd").new()
	inv.set("persist_enabled", false)
	var st = preload("res://autoload/standing.gd").new()
	st.set("persist_enabled", false)
	var cf = preload("res://autoload/case_file.gd").new()
	cf.set("_investigation", inv)
	cf.set("_standing", st)
	var failures := 0

	var r1: Dictionary = cf.accuse("riley")
	if r1["accepted"] != false:
		failures += 1; print("FAIL: should reject with no evidence")
	if absf(st.get_standing("riley") - (-0.15)) > 0.001:
		failures += 1; print("FAIL: rejected accusation should drop suspect standing by 0.15")
	if cf.resolved != false:
		failures += 1; print("FAIL: rejected accusation should not resolve the case")

	inv.discover_clue("clue_pills")
	inv.discover_clue("clue_medbook")
	var r2: Dictionary = cf.accuse("riley")
	if r2["accepted"] != true:
		failures += 1; print("FAIL: should accept once case is built")
	if r2["ending_id"] != "ending_riley":
		failures += 1; print("FAIL: ending_id should be ending_riley, got %s" % r2["ending_id"])
	if cf.resolved != true or cf.accused_id != "riley":
		failures += 1; print("FAIL: case should be resolved against riley")
	if absf(st.get_standing("riley") - (-0.65)) > 0.001:
		failures += 1; print("FAIL: accused standing wrong: %f" % st.get_standing("riley"))
	if absf(st.get_standing("casey") - (-0.3)) > 0.001:
		failures += 1; print("FAIL: friend standing should drop 0.3, got %f" % st.get_standing("casey"))

	inv.free(); st.free(); cf.free()
	if failures == 0:
		print("PASS: test_accuse")
	quit(failures)
