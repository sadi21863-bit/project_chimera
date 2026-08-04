extends SceneTree

## Accusations stay locked until evidence exists on EVERY suspect (no rushing to convict).

func _initialize() -> void:
	var inv = preload("res://autoload/investigation.gd").new()
	inv.set("persist_enabled", false)
	var cf = preload("res://autoload/case_file.gd").new()
	cf.set("_investigation", inv)
	var failures := 0

	if cf.accusations_unlocked() != false:
		failures += 1; print("FAIL: should be locked with no evidence")

	# both of sam's clues alone must NOT unlock accusations.
	inv.discover_clue("clue_wiring"); inv.discover_clue("clue_camera")
	if cf.accusations_unlocked() != false:
		failures += 1; print("FAIL: still locked when only sam is investigated")

	# one clue for each remaining suspect unlocks it.
	for cid in ["clue_keys", "clue_rehearsal", "clue_pills", "clue_moved_object", "clue_sketch"]:
		inv.discover_clue(cid)
	if cf.accusations_unlocked() != true:
		failures += 1; print("FAIL: should unlock with one clue per suspect")

	inv.free(); cf.free()
	if failures == 0:
		print("PASS: test_accusations")
	quit(failures)
