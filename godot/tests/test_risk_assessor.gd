extends SceneTree

func _initialize() -> void:
	var ra := preload("res://scripts/access/risk_assessor.gd")
	var failures := 0

	if ra.assess(false, false, 0) != "safe":
		failures += 1; print("FAIL: not restricted, not intrusive, no witnesses -> safe")
	if ra.assess(true, false, 0) != "risky":
		failures += 1; print("FAIL: restricted, unwitnessed -> risky")
	if ra.assess(false, true, 0) != "risky":
		failures += 1; print("FAIL: intrusive, unwitnessed -> risky")
	if ra.assess(true, false, 2) != "dangerous":
		failures += 1; print("FAIL: restricted with witnesses -> dangerous")
	if ra.assess(false, true, 1) != "dangerous":
		failures += 1; print("FAIL: intrusive with a witness -> dangerous")

	if ra.hint_for("safe", "explicit") != "":
		failures += 1; print("FAIL: safe should never show a hint")
	if ra.hint_for("risky", "explicit") != "  [RISKY]":
		failures += 1; print("FAIL: explicit should spell out the level")
	if ra.hint_for("dangerous", "shown") != "  [DANGEROUS]":
		failures += 1; print("FAIL: shown should spell out the level")
	if ra.hint_for("risky", "subtle") != "  [?]":
		failures += 1; print("FAIL: subtle should show a vague marker")
	if ra.hint_for("risky", "hidden") != "":
		failures += 1; print("FAIL: hidden should show nothing")

	if failures == 0:
		print("PASS: test_risk_assessor")
	quit(failures)
