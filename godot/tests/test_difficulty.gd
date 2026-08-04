extends SceneTree

func _initialize() -> void:
	var d = preload("res://autoload/difficulty.gd").new()
	d.set("persist_enabled", false)
	var failures := 0

	d.set_preset("easy")
	if d.has_deadline() != false:
		failures += 1; print("FAIL: easy should have no deadline")
	if d.get_value("catch_model") != "off":
		failures += 1; print("FAIL: easy catch_model should be off")

	d.set_preset("extreme")
	if d.get_value("deadline_days") != 7:
		failures += 1; print("FAIL: extreme deadline should be 7")
	if d.has_deadline() != true:
		failures += 1; print("FAIL: extreme should have a deadline")
	if d.get_value("consequence_ceiling") != "death":
		failures += 1; print("FAIL: extreme ceiling should be death")

	d.override("deadline_days", 20)
	if d.get_value("deadline_days") != 20:
		failures += 1; print("FAIL: override should set the field")
	if d.preset != "custom":
		failures += 1; print("FAIL: override should mark preset custom")

	if failures == 0:
		print("PASS: test_difficulty")
	d.free()
	quit(failures)
