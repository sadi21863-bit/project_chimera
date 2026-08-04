extends SceneTree

var _done := false

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true

	var scene: PackedScene = load("res://scenes/locations/university.tscn")
	var loc = scene.instantiate()
	root.add_child(loc)
	var failures := 0

	if loc.npcs.size() != 1:
		failures += 1; print("FAIL: university should spawn exactly 1 NPC (the dean), got %d" % loc.npcs.size())
	else:
		var dean = loc.npcs[0]
		if dean.npc_id != "dean":
			failures += 1; print("FAIL: the university NPC should be the dean, got %s" % dean.npc_id)
		var has_talk_area := false
		for ch in dean.get_children():
			if ch is NpcInteractable:
				has_talk_area = true
		if not has_talk_area:
			failures += 1; print("FAIL: the dean should have a talk NpcInteractable")

	var id := preload("res://scripts/interrogation/interrogation_data.gd")
	if id.topics_for("dean").is_empty():
		failures += 1; print("FAIL: the dean should have interrogation topics")
	var case_data := preload("res://scripts/case/case_data.gd")
	if case_data.SUSPECTS.has("dean"):
		failures += 1; print("FAIL: the dean should NOT be a CaseData suspect (lore-only, no accusation arc)")

	if failures == 0:
		print("PASS: test_university_npc")
	quit(failures)
	return true
