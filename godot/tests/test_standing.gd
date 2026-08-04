extends SceneTree

func _initialize() -> void:
	var s = preload("res://autoload/standing.gd").new()
	s.set("persist_enabled", false)
	var failures := 0
	if s.get_standing("alex") != 0.0:
		failures += 1; print("FAIL: default standing should be 0.0")
	var v: float = s.adjust("alex", -0.5)
	if absf(v - (-0.5)) > 0.001:
		failures += 1; print("FAIL: adjust should return -0.5, got %f" % v)
	if absf(s.get_standing("alex") - (-0.5)) > 0.001:
		failures += 1; print("FAIL: get_standing should be -0.5")
	s.adjust("alex", -5.0)
	if s.get_standing("alex") != -1.0:
		failures += 1; print("FAIL: standing should clamp at -1.0")
	if failures == 0:
		print("PASS: test_standing")
	s.free()
	quit(failures)
