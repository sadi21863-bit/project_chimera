extends SceneTree

# Minimal fake scheduler so the manager's time-advance is testable in isolation.
class FakeScheduler:
	extends Node
	var hours := 0.0
	func advance_hours(h: float) -> void:
		hours += h

func _initialize() -> void:
	var lm = preload("res://autoload/location_manager.gd").new()
	var sched := FakeScheduler.new()
	lm.set("_scheduler", sched)
	var failures := 0

	if lm.current_id != "dorm":
		failures += 1; print("FAIL: should start at the dorm")
	if not lm.LOCATIONS.has("detective_room"):
		failures += 1; print("FAIL: detective_room should be a known location")
	if not lm.LOCATIONS.has("police_station"):
		failures += 1; print("FAIL: police_station should be a known location")
	if not lm.LOCATIONS.has("university"):
		failures += 1; print("FAIL: university should be a known location")

	var captured := {"dest": ""}
	lm.location_changing.connect(func(d): captured["dest"] = d)

	if lm.travel("nowhere") != false:
		failures += 1; print("FAIL: unknown destination should return false")
	if lm.travel("dorm") != false:
		failures += 1; print("FAIL: travelling to the current location should return false")

	if not lm.is_unvisited("detective_room"):
		failures += 1; print("FAIL: detective_room should start unvisited")
	if lm.is_unvisited("dorm"):
		failures += 1; print("FAIL: dorm should start visited (you begin there)")

	if lm.travel("detective_room") != true:
		failures += 1; print("FAIL: valid travel should return true")
	if lm.current_id != "detective_room":
		failures += 1; print("FAIL: current_id should update")
	if captured["dest"] != "detective_room":
		failures += 1; print("FAIL: location_changing should fire with dest")
	if sched.hours <= 0.0:
		failures += 1; print("FAIL: travel should advance time")
	if lm.is_unvisited("detective_room"):
		failures += 1; print("FAIL: travelling somewhere should mark it visited")

	lm.free(); sched.free()
	if failures == 0:
		print("PASS: test_location_manager")
	quit(failures)
