extends SceneTree

var _phase := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var inv = preload("res://autoload/investigation.gd").new(); inv.set("persist_enabled", false)
		var panel = load("res://scenes/ui/search_panel.tscn").instantiate()
		root.add_child(panel)
		var failures := 0

		panel.open("common_couch", inv)
		var btns: int = panel.get_node("Panel/VBox/Actions").get_child_count()
		if btns != 2:
			failures += 1; print("FAIL: couch should have 2 action buttons, got %d" % btns)

		panel.select_action("look_under")
		if not inv.is_discovered("clue_logbook"):
			failures += 1; print("FAIL: look_under should reveal clue_logbook")
		if panel.get_node("Panel/VBox/Response").text.is_empty():
			failures += 1; print("FAIL: select_action should show flavor text")

		if failures == 0:
			print("PASS: test_search_panel")
		quit(failures)
		return true
	return false
