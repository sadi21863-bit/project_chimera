extends SceneTree

func _initialize() -> void:
	var id := preload("res://scripts/interrogation/interrogation_data.gd")
	var failures := 0
	var case_data := preload("res://scripts/case/case_data.gd")
	for sid in case_data.get_suspect_ids():
		if not id.SUSPECTS.has(sid):
			failures += 1; print("FAIL: no interrogation data for %s" % sid)
		elif id.topics_for(sid).is_empty():
			failures += 1; print("FAIL: %s has no topics" % sid)
	var low: Dictionary = id.respond_to_topic("riley", "the_pills", 0.0)
	if low["reveal_clue"] != "":
		failures += 1; print("FAIL: low trust should not reveal a clue")
	var high: Dictionary = id.respond_to_topic("riley", "the_pills", 0.9)
	if high["reveal_clue"] != "clue_medbook":
		failures += 1; print("FAIL: high trust should reveal clue_medbook, got '%s'" % high["reveal_clue"])
	if id.respond_to_evidence("riley", "clue_pills").is_empty():
		failures += 1; print("FAIL: riley should react to clue_pills")
	if failures == 0:
		print("PASS: test_interrogation_data")
	quit(failures)
