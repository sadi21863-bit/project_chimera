extends SceneTree

func _initialize() -> void:
	var cd := preload("res://scripts/case/case_data.gd")
	var failures := 0
	var ids: Array = cd.get_suspect_ids()
	if ids.size() != 6:
		failures += 1; print("FAIL: expected 6 suspects, got %d" % ids.size())
	for sid in ids:
		var clues: Array = cd.clues_for_suspect(sid)
		if clues.size() != 2:
			failures += 1; print("FAIL: suspect %s has %d clues (expected 2)" % [sid, clues.size()])
		var threshold: int = cd.SUSPECTS[sid]["threshold"]
		if threshold != 2:
			failures += 1; print("FAIL: suspect %s threshold %d (expected 2)" % [sid, threshold])
	for clue_id in cd.CLUES:
		for sid in cd.CLUES[clue_id]["implicates"]:
			if not cd.SUSPECTS.has(sid):
				failures += 1; print("FAIL: clue %s implicates unknown suspect %s" % [clue_id, sid])
	if failures == 0:
		print("PASS: test_case_data")
	quit(failures)
