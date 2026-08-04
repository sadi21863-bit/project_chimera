extends SceneTree

func _initialize() -> void:
	var gd := preload("res://scripts/interrogation/gossip_data.gd")
	var case_data := preload("res://scripts/case/case_data.gd")
	var failures := 0
	if gd.conversations().is_empty():
		failures += 1; print("FAIL: there should be conversations")
	for convo in gd.conversations():
		if convo["lines"].is_empty():
			failures += 1; print("FAIL: conversation %s has no lines" % convo["id"])
		var reveal: String = str(convo["reveal_clue"])
		if reveal != "" and not case_data.CLUES.has(reveal):
			failures += 1; print("FAIL: %s reveals unknown clue %s" % [convo["id"], reveal])
	if failures == 0:
		print("PASS: test_gossip_data")
	quit(failures)
