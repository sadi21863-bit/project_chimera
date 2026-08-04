extends SceneTree

## Integration probe: instantiate the real main scene and verify set_mode flips
## camera / detective control / observer visibility. (main.gd references autoloads, so it
## must be loaded at runtime, not preloaded.)

var _done := false

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var hall = main.get_node("LocationHost/CrestwoodHall")
	var det = hall.detective
	var observer = main.get_node("UI/ObserverPanel")
	var cam = main.get_node("Camera2D")
	var failures := 0

	var det_cam = det.get_node("Camera2D")

	main.set_mode(0)  # PLAY
	if det.control_enabled != true:
		failures += 1; print("FAIL: PLAY should enable detective control")
	if cam.enabled != false:
		failures += 1; print("FAIL: PLAY should disable observer camera")
	if det_cam.is_current() != true:
		failures += 1; print("FAIL: PLAY should make the detective camera current")
	if observer.visible != false:
		failures += 1; print("FAIL: PLAY should hide observer panel")

	main.set_mode(1)  # OBSERVER
	if det.control_enabled != false:
		failures += 1; print("FAIL: OBSERVER should disable detective control")
	if cam.is_current() != true:
		failures += 1; print("FAIL: OBSERVER should make the observer camera current")
	if observer.visible != true:
		failures += 1; print("FAIL: OBSERVER should show observer panel")

	if failures == 0:
		print("PASS: test_mode_toggle")
	quit(failures)
	return true
