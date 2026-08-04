extends SceneTree

var _phase := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		var failures := 0
		var settings = main.get_node("UI/SettingsScreen")
		var story = main.get_node("UI/StoryScreen")
		# pressing the Difficulty button on the First Choice opens the settings screen
		story.get_node("Center/VBox/Buttons/SettingsButton").pressed.emit()
		if not settings.visible:
			failures += 1; print("FAIL: Difficulty button should open the settings screen")
		if failures == 0:
			print("PASS: test_settings_wiring")
		quit(failures)
		return true
	return false
