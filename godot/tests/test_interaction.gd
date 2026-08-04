extends SceneTree

func _initialize() -> void:
	var interactor_script := preload("res://scripts/player/interactor.gd")
	var clue_script := preload("res://scripts/player/clue_hotspot.gd")
	var failures := 0

	# _pick_nearest(want_clue=true) returns the closest ClueHotspot.
	var a = clue_script.new(); a.position = Vector2(100, 0)
	var b = clue_script.new(); b.position = Vector2(10, 0)
	var nearest = interactor_script._pick_nearest([a, b], Vector2.ZERO, true)
	if nearest != b:
		failures += 1; print("FAIL: nearest clue should be b (closest)")
	# Clues must NOT match the NPC filter.
	if interactor_script._pick_nearest([a, b], Vector2.ZERO, false) != null:
		failures += 1; print("FAIL: clues should not match want_clue=false")
	if interactor_script._pick_nearest([], Vector2.ZERO, true) != null:
		failures += 1; print("FAIL: empty list should give null")
	a.free(); b.free()

	# ClueHotspot.examine discovers its clue via an injected store.
	var inv = preload("res://autoload/investigation.gd").new()
	inv.set("persist_enabled", false)
	var clue = clue_script.new()
	clue.clue_id = "clue_test"
	clue.clue_title = "Test Clue"
	clue.examine(inv)
	if inv.is_discovered("clue_test") != true:
		failures += 1; print("FAIL: examine should discover the clue")
	clue.free(); inv.free()

	if failures == 0:
		print("PASS: test_interaction")
	quit(failures)
