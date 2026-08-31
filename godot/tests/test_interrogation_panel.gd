extends SceneTree

var _phase := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var inv = preload("res://autoload/investigation.gd").new(); inv.set("persist_enabled", false)
		var st = preload("res://autoload/standing.gd").new(); st.set("persist_enabled", false)
		var panel = load("res://scenes/ui/interrogation_panel.tscn").instantiate()
		root.add_child(panel)
		var failures := 0

		panel.open("riley", inv, st)
		var topic_count: int = panel.get_node("Panel/VBox/Topics").get_child_count()
		if topic_count < 1:
			failures += 1; print("FAIL: riley should have >=1 base topic button, got %d" % topic_count)

		panel.select_topic("the_pills")
		if inv.is_discovered("clue_medbook"):
			failures += 1; print("FAIL: clue should stay hidden at low trust")

		st.adjust("riley", 0.9)
		panel.select_topic("the_pills")
		if not inv.is_discovered("clue_medbook"):
			failures += 1; print("FAIL: high-trust topic should reveal clue_medbook")

		var captured := {"text": ""}
		panel.free_text_submitted.connect(func(_sid, t): captured["text"] = t)
		panel.submit_free_text("did you hate him?")
		if captured["text"] != "did you hate him?":
			failures += 1; print("FAIL: free-text submit should emit the text")

		if failures == 0:
			print("PASS: test_interrogation_panel")
		quit(failures)
		return true
	return false
