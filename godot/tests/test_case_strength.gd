extends SceneTree

func _initialize() -> void:
	var inv = preload("res://autoload/investigation.gd").new()
	inv.set("persist_enabled", false)
	var cf = preload("res://autoload/case_file.gd").new()
	cf.set("_investigation", inv)
	var failures := 0

	if cf.case_strength("riley") != 0:
		failures += 1; print("FAIL: strength should start at 0")
	if cf.can_accuse("riley") != false:
		failures += 1; print("FAIL: cannot accuse with no evidence")

	inv.discover_clue("clue_pills")
	if cf.case_strength("riley") != 1:
		failures += 1; print("FAIL: strength should be 1 after one clue")
	if cf.can_accuse("riley") != false:
		failures += 1; print("FAIL: still below threshold at 1")

	inv.discover_clue("clue_medbook")
	if cf.case_strength("riley") != 2:
		failures += 1; print("FAIL: strength should be 2")
	if cf.can_accuse("riley") != true:
		failures += 1; print("FAIL: should be accusable at threshold")

	inv.free(); cf.free()
	if failures == 0:
		print("PASS: test_case_strength")
	quit(failures)
