extends SceneTree

func _initialize() -> void:
	var dt = preload("res://scripts/player/door_trigger.gd").new()
	dt.dest_id = "university"
	dt.dest_label = "the campus"
	var failures := 0

	if dt.get_prompt() != "Go to the campus":
		failures += 1; print("FAIL: unexpected prompt: %s" % dt.get_prompt())

	var captured := {"dest": ""}
	dt.door_triggered.connect(func(d): captured["dest"] = d)
	dt.interact()
	if captured["dest"] != "university":
		failures += 1; print("FAIL: interact() should emit door_triggered with dest_id")

	dt.free()
	if failures == 0:
		print("PASS: test_door_trigger")
	quit(failures)
