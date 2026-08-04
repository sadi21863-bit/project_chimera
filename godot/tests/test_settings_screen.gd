extends SceneTree

var _phase := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var screen = load("res://scenes/ui/settings_screen.tscn").instantiate()
		root.add_child(screen)
		var diff = root.get_node("Difficulty")
		var failures := 0

		screen.open()
		var preset_btns: int = screen.get_node("Panel/VBox/Presets").get_child_count()
		if preset_btns != 4:
			failures += 1; print("FAIL: expected 4 preset buttons, got %d" % preset_btns)

		# index 2 = hard (easy, medium, hard, extreme)
		var hard_btn = screen.get_node("Panel/VBox/Presets").get_child(2)
		hard_btn.pressed.emit()
		if diff.preset != "hard":
			failures += 1; print("FAIL: pressing hard should set difficulty (got %s)" % diff.preset)
		if int(diff.get_value("deadline_days")) != 10:
			failures += 1; print("FAIL: hard deadline should be 10")

		if failures == 0:
			print("PASS: test_settings_screen")
		quit(failures)
		return true
	return false
