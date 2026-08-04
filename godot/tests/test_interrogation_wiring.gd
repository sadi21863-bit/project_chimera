extends SceneTree

var _phase := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		var inv = root.get_node("Investigation"); inv.reset()
		var st = root.get_node("Standing"); st.reset()
		var failures := 0

		main._on_talk_requested("riley")
		var panel = main.get_node("UI/InterrogationPanel")
		if not panel.visible:
			failures += 1; print("FAIL: talk should open the interrogation panel")

		st.adjust("riley", 0.9)
		panel.select_topic("the_pills")
		if not inv.is_discovered("clue_medbook"):
			failures += 1; print("FAIL: interrogation should reveal clue_medbook at high trust")

		main._on_free_text("riley", "did you do it?")
		if panel.get_node("Panel/VBox/Response").text.is_empty():
			failures += 1; print("FAIL: free-text should produce some response")

		if failures == 0:
			print("PASS: test_interrogation_wiring")
		quit(failures)
		return true
	return false
