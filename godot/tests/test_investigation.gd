extends SceneTree

func _initialize() -> void:
	var script := preload("res://autoload/investigation.gd")
	var inv = script.new()
	inv.set("persist_enabled", false)  # don't write user:// during tests
	var failures := 0

	if inv.discover_clue("clue_keys") != true:
		failures += 1; print("FAIL: first discover should return true")
	if inv.discover_clue("clue_keys") != false:
		failures += 1; print("FAIL: duplicate discover should return false")
	if inv.is_discovered("clue_keys") != true:
		failures += 1; print("FAIL: is_discovered should be true")
	if inv.discover_clue("") != false:
		failures += 1; print("FAIL: empty id should be rejected")
	if inv.discovered_count() != 1:
		failures += 1; print("FAIL: discovered_count should be 1")
	inv.reset()
	if inv.discovered_count() != 0:
		failures += 1; print("FAIL: reset should clear")

	if failures == 0:
		print("PASS: test_investigation")
	inv.free()
	quit(failures)
