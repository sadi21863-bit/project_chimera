extends SceneTree

func _initialize() -> void:
	var rp = preload("res://scripts/player/rest_point.gd").new()
	var failures := 0

	if rp.get_prompt() != "Rest (advance a day)":
		failures += 1; print("FAIL: unexpected prompt: %s" % rp.get_prompt())

	var fired := {"count": 0}
	rp.rest_requested.connect(func(): fired["count"] += 1)
	rp.interact()
	if fired["count"] != 1:
		failures += 1; print("FAIL: interact() should emit rest_requested once")

	rp.free()
	if failures == 0:
		print("PASS: test_rest_point")
	quit(failures)
