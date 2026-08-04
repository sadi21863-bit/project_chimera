extends SceneTree

func _initialize() -> void:
	var ew := preload("res://scenes/eavesdrop_watcher.gd")
	var failures := 0
	var convos := [
		{"id": "c1", "npc_a": "morgan", "npc_b": "casey", "reveal_clue": "x", "lines": []},
	]
	var pos := {"morgan": Vector2(100, 100), "casey": Vector2(120, 100)}

	var far: Array = ew.check(convos, pos, Vector2(900, 900), {}, 60.0, 120.0)
	if not far.is_empty():
		failures += 1; print("FAIL: should not fire when detective is far")
	var apart := {"morgan": Vector2(100, 100), "casey": Vector2(900, 100)}
	var sep: Array = ew.check(convos, apart, Vector2(110, 100), {}, 60.0, 120.0)
	if not sep.is_empty():
		failures += 1; print("FAIL: should not fire when speakers are apart")
	var near: Array = ew.check(convos, pos, Vector2(130, 100), {}, 60.0, 120.0)
	if near != ["c1"]:
		failures += 1; print("FAIL: should fire c1 when overheard")
	var again: Array = ew.check(convos, pos, Vector2(130, 100), {"c1": true}, 60.0, 120.0)
	if not again.is_empty():
		failures += 1; print("FAIL: should not re-fire")

	if failures == 0:
		print("PASS: test_eavesdrop")
	quit(failures)
