extends SceneTree

func _initialize() -> void:
	var ec := preload("res://scripts/case/ending_content.gd")
	var failures := 0
	if not ec.ACCIDENT.has("body"):
		failures += 1; print("FAIL: accident ending missing body")
	if ec.WRONG.size() != 6:
		failures += 1; print("FAIL: expected 6 wrong endings, got %d" % ec.WRONG.size())
	if ec.ending_for("ending_accident") != ec.ACCIDENT:
		failures += 1; print("FAIL: ending_for(accident) wrong")
	var riley_end: Dictionary = ec.ending_for("ending_riley")
	if not riley_end.has("title"):
		failures += 1; print("FAIL: ending_for(ending_riley) should return riley's ending")
	if ec.ending_for("nonsense").size() != 0:
		failures += 1; print("FAIL: unknown ending should be empty")
	for game_over_id in ["ending_fired_strikes", "ending_fired_deadline", "ending_death"]:
		var go_end: Dictionary = ec.ending_for(game_over_id)
		if not go_end.has("title") or not go_end.has("body"):
			failures += 1; print("FAIL: ending_for(%s) should return a title + body" % game_over_id)
	var fb: Array = ec.build_flashback(["clue_pills", "clue_keys"])
	if fb.size() != 2:
		failures += 1; print("FAIL: flashback should have 2 entries, got %d" % fb.size())
	else:
		var truths: Array = []
		for e in fb:
			truths.append(e["truth"])
		if not ("Riley gave the victim a harmless sleep aid." in truths):
			failures += 1; print("FAIL: flashback should include riley's clue truth")
	if failures == 0:
		print("PASS: test_ending_content")
	quit(failures)
