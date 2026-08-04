extends SceneTree

func _initialize() -> void:
	var sd := preload("res://scripts/interrogation/suspicion_data.gd")
	var sw := preload("res://scenes/suspicion_watcher.gd")
	var failures := 0
	if sd.moments().is_empty():
		failures += 1; print("FAIL: there should be suspicious moments")

	var moments := [
		{"id": "m1", "npc_id": "sam", "hour": 2.0, "description": "x", "reveal_clue": "clue_camera"},
	]
	var npc_pos := {"sam": Vector2(100, 100)}
	var early: Array = sw.check(moments, 1.0, Vector2(100, 100), npc_pos, {}, 40.0)
	if not early.is_empty():
		failures += 1; print("FAIL: should not fire before the hour")
	var far: Array = sw.check(moments, 2.0, Vector2(900, 900), npc_pos, {}, 40.0)
	if not far.is_empty():
		failures += 1; print("FAIL: should not fire when detective is far")
	var near: Array = sw.check(moments, 2.0, Vector2(110, 100), npc_pos, {}, 40.0)
	if near != ["m1"]:
		failures += 1; print("FAIL: should fire m1 when caught")
	var again: Array = sw.check(moments, 2.0, Vector2(110, 100), npc_pos, {"m1": true}, 40.0)
	if not again.is_empty():
		failures += 1; print("FAIL: should not re-fire")

	if failures == 0:
		print("PASS: test_suspicion")
	quit(failures)
