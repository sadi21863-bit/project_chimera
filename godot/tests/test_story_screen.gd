extends SceneTree

var _phase := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var screen = load("res://scenes/ui/story_screen.tscn").instantiate()
		root.add_child(screen)
		var failures := 0

		var captured := {"is_murder": null}
		screen.choice_made.connect(func(m): captured["is_murder"] = m)
		screen.show_choice()
		screen.get_node("Center/VBox/Buttons/MurderButton").pressed.emit()
		if captured["is_murder"] != true:
			failures += 1; print("FAIL: murder button should emit choice_made(true)")

		screen.show_ending("ending_riley", ["clue_pills"])
		var text: String = screen.get_node("Center/VBox/Body").text
		if not ("First, Do No Harm" in text or "Riley" in text):
			failures += 1; print("FAIL: ending body should mention riley's ending")
		if not ("harmless sleep aid" in text):
			failures += 1; print("FAIL: flashback should reveal the clue truth")

		if failures == 0:
			print("PASS: test_story_screen")
		quit(failures)
		return true
	return false
