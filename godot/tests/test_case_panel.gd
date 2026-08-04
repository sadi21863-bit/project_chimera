extends SceneTree

var _phase := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		var inv = root.get_node("Investigation"); inv.reset()
		var cf = root.get_node("CaseFile")
		var panel = load("res://scenes/ui/case_panel.tscn").instantiate()
		root.add_child(panel)
		var failures := 0

		var captured := {"id": ""}
		panel.accuse_requested.connect(func(sid): captured["id"] = sid)

		panel.refresh(cf)
		var rows: int = panel.get_node("Panel/VBox/Rows").get_child_count()
		if rows != 6:
			failures += 1; print("FAIL: expected 6 suspect rows, got %d" % rows)

		# Unlock accusations: at least one clue per suspect, plus both of sam's.
		for cid in ["clue_keys", "clue_rehearsal", "clue_pills", "clue_moved_object", "clue_sketch", "clue_wiring", "clue_camera"]:
			inv.discover_clue(cid)
		panel.refresh(cf)
		var btn = panel.find_accuse_button("sam")
		if btn == null:
			failures += 1; print("FAIL: no accuse button for sam")
		elif btn.disabled != false:
			failures += 1; print("FAIL: sam's accuse button should be enabled when accusable")
		else:
			btn.pressed.emit()
			if captured["id"] != "sam":
				failures += 1; print("FAIL: pressing accuse should emit accuse_requested('sam')")

		if failures == 0:
			print("PASS: test_case_panel")
		quit(failures)
		return true
	return false
