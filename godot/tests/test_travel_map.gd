extends SceneTree

var _phase := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var map = load("res://scenes/ui/travel_map.tscn").instantiate()
		root.add_child(map)
		var lm = root.get_node("LocationManager")
		var failures := 0
		var captured := {"dest": ""}
		map.travel_requested.connect(func(d): captured["dest"] = d)
		map.open()
		var btns: int = map.get_node("Panel/VBox/List").get_child_count()
		if btns != lm.LOCATIONS.size():
			failures += 1; print("FAIL: one button per location expected")
		# find the detective_room button (unvisited -> marked) and press it
		var found_marker := false
		for b in map.get_node("Panel/VBox/List").get_children():
			if b.text.ends_with(lm.location_name("detective_room")):
				if b.text.begins_with("! "):
					found_marker = true
				b.pressed.emit()
		if not found_marker:
			failures += 1; print("FAIL: an unvisited location should be marked with '! '")
		if captured["dest"] != "detective_room":
			failures += 1; print("FAIL: picking a location should emit travel_requested")
		if failures == 0:
			print("PASS: test_travel_map")
		quit(failures)
		return true
	return false
