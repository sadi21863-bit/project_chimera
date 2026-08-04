extends SceneTree

func _initialize() -> void:
	var failures := 0
	var clue_id := "test_locked_door_key_%d" % Time.get_ticks_usec()
	var investigation = root.get_node("Investigation")

	var dt = load("res://scripts/player/locked_door_trigger.gd").new()
	dt.dest_id = "daniel_room"
	dt.dest_label = "Daniel's room"
	dt.required_clue = clue_id

	if dt.get_prompt() != "Locked":
		failures += 1; print("FAIL: prompt should read Locked before the clue is discovered: %s" % dt.get_prompt())

	var captured := {"dest": ""}
	dt.door_triggered.connect(func(d): captured["dest"] = d)
	dt.interact()
	if captured["dest"] != "":
		failures += 1; print("FAIL: interact() should not emit door_triggered while locked")

	investigation.discover_clue(clue_id)

	if dt.get_prompt() != "Go to Daniel's room":
		failures += 1; print("FAIL: prompt should unlock once the clue is discovered: %s" % dt.get_prompt())

	dt.interact()
	if captured["dest"] != "daniel_room":
		failures += 1; print("FAIL: interact() should emit door_triggered once unlocked")

	dt.free()
	if failures == 0:
		print("PASS: test_locked_door_trigger")
	quit(failures)
