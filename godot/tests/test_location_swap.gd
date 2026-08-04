extends SceneTree

var _phase := 0
var _main
var _frames := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		# starts in the dorm
		var loc = _main.get_node("LocationHost").get_child(0)
		if loc.name != "CrestwoodHall":
			print("FAIL: should start in the dorm (got %s)" % loc.name); quit(1); return true
		# travel to the detective's room
		root.get_node("LocationManager").travel("detective_room")
		return false
	_frames += 1
	if _frames < 3:
		return false
	var host = _main.get_node("LocationHost")
	var loaded: bool = host.get_child_count() >= 1 and str(host.get_child(host.get_child_count() - 1).name) == "DetectiveRoom"
	if loaded:
		print("PASS: test_location_swap — travelled dorm -> detective room")
		quit(0)
	else:
		print("FAIL: location did not swap to the detective room")
		quit(1)
	return true
