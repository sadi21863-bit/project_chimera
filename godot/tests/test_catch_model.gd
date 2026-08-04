extends SceneTree

func _initialize() -> void:
	var cm := preload("res://scripts/access/catch_model.gd")
	var failures := 0

	# meter: fills while restricted
	var meter := 0.0
	meter = cm.update_meter(meter, true, 1.0)
	if meter <= 0.0:
		failures += 1; print("FAIL: meter should rise while restricted")
	if meter > 1.0:
		failures += 1; print("FAIL: meter should clamp at 1.0")

	# meter: fills to full given enough time
	meter = 0.0
	for i in range(10):
		meter = cm.update_meter(meter, true, 1.0)
	if meter != 1.0:
		failures += 1; print("FAIL: meter should reach 1.0 (caught) given enough time restricted")

	# meter: drains while not restricted
	meter = 0.5
	meter = cm.update_meter(meter, false, 1.0)
	if meter >= 0.5:
		failures += 1; print("FAIL: meter should fall while not restricted")

	# vision: not caught if not restricted, even standing on an NPC
	if cm.check_vision(false, Vector2(10, 10), [{"position": Vector2(10, 10), "facing": Vector2.DOWN}], 140.0, 45.0, 40.0):
		failures += 1; print("FAIL: not restricted should never be caught")

	# vision: caught by close proximity regardless of facing
	var behind_npc := [{"position": Vector2(0, 0), "facing": Vector2.DOWN}]
	if not cm.check_vision(true, Vector2(10, 0), behind_npc, 140.0, 45.0, 40.0):
		failures += 1; print("FAIL: standing right next to an NPC should catch you even from behind")

	# vision: caught when inside the facing cone at range
	var facing_right := [{"position": Vector2(0, 0), "facing": Vector2.RIGHT}]
	if not cm.check_vision(true, Vector2(100, 0), facing_right, 140.0, 45.0, 40.0):
		failures += 1; print("FAIL: standing directly ahead in the cone should catch you")

	# vision: not caught when outside the facing cone and out of proximity range
	var facing_right2 := [{"position": Vector2(0, 0), "facing": Vector2.RIGHT}]
	if cm.check_vision(true, Vector2(0, 100), facing_right2, 140.0, 45.0, 40.0):
		failures += 1; print("FAIL: standing directly behind (outside cone, outside proximity) should not catch you")

	if failures == 0:
		print("PASS: test_catch_model")
	quit(failures)
