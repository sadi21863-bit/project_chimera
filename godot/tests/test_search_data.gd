extends SceneTree

func _initialize() -> void:
	var sd := preload("res://scripts/interrogation/search_data.gd")
	var case_data := preload("res://scripts/case/case_data.gd")
	var failures := 0

	if sd.point_ids().is_empty():
		failures += 1; print("FAIL: there should be search points")

	# every action's revealed clue (if any) is either a real case clue, a documented red-herring
	# flavor clue (Plan E's ghost-master trail — never affects case strength), or a documented
	# lore/item flag (Daniel's own secrets + the master key that unlocks his room — victim
	# backstory, not suspect-implicating evidence, so intentionally not in CaseData.CLUES)
	var red_herrings: Array = []
	var lore_and_items := ["item_master_key", "clue_daniel_double_life", "clue_daniel_scheme", "clue_daniel_selfmed"]
	for pid in sd.point_ids():
		var p: Dictionary = sd.point(pid)
		if p.get("actions", []).is_empty():
			failures += 1; print("FAIL: %s has no actions" % pid)
		for action in p["actions"]:
			var rc: String = str(action.get("reveal_clue", ""))
			if rc != "" and not case_data.CLUES.has(rc) and not red_herrings.has(rc) and not lore_and_items.has(rc):
				failures += 1; print("FAIL: %s/%s reveals unknown clue %s" % [pid, action["id"], rc])

	# resolve returns flavor + the configured clue
	var res: Dictionary = sd.resolve("common_room_couch", "check_under")
	if res["reveal_clue"] != "clue_logbook":
		failures += 1; print("FAIL: couch check_under should reveal clue_logbook")
	if res["flavor"].is_empty():
		failures += 1; print("FAIL: resolve should return flavor text")
	# a flavor-only action reveals nothing
	if sd.resolve("hall_board", "read")["reveal_clue"] != "":
		failures += 1; print("FAIL: reading notices should reveal no clue")

	# every bedroom + the bathroom is now examinable in detail
	var expected_rooms := {
		"bathroom_cabinet": "bathroom", "bedroom_1_desk": "bedroom_1", "jordan_dresser": "bedroom_2",
		"sam_nightstand": "bedroom_3", "riley_closet": "bedroom_4", "morgan_desk": "bedroom_5",
		"casey_shelf": "bedroom_6",
	}
	for pid in expected_rooms:
		if not sd.point_ids().has(pid):
			failures += 1; print("FAIL: missing search point %s" % pid)
		elif str(sd.point(pid).get("room", "")) != expected_rooms[pid]:
			failures += 1; print("FAIL: %s should be in %s" % [pid, expected_rooms[pid]])

	# Plan E: the ghost-master trail (Jordan's room) + police-station interference content
	var expected_rooms_e := {
		"jordan_costume_trunk": "bedroom_2", "case_board": "police_station",
		"evidence_log": "police_station", "detective_memo": "police_station",
	}
	for pid in expected_rooms_e:
		if not sd.point_ids().has(pid):
			failures += 1; print("FAIL: missing search point %s" % pid)
		elif str(sd.point(pid).get("room", "")) != expected_rooms_e[pid]:
			failures += 1; print("FAIL: %s should be in %s" % [pid, expected_rooms_e[pid]])

	# the ghost-master clues are now real case clues (they implicate jordan) — verify they exist
	for ghost_clue in ["clue_ghost_sighting", "clue_ghost_costume", "clue_ghost_note"]:
		if not case_data.CLUES.has(ghost_clue):
			failures += 1; print("FAIL: %s should be in CaseData.CLUES" % ghost_clue)

	if failures == 0:
		print("PASS: test_search_data")
	quit(failures)
