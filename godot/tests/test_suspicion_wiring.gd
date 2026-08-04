extends SceneTree

var _phase := 0
var _hall
var _frames := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		root.get_node("Investigation").reset()
		_hall = main.get_node("LocationHost/CrestwoodHall")
		var sched = root.get_node("Scheduler")
		sched.set_time(2.0)  # Sam's suspicious moment
		for npc in _hall.npcs:
			if npc.npc_id == "sam":
				npc.global_position = Vector2(300, 300)
		_hall.detective.global_position = Vector2(305, 300)
		return false
	_frames += 1
	if _frames < 5:
		return false
	var inv = root.get_node("Investigation")
	if inv.is_discovered("clue_camera"):
		print("PASS: test_suspicion_wiring — caught Sam, revealed clue_camera")
		quit(0)
	else:
		print("FAIL: catching Sam should reveal clue_camera")
		quit(1)
	return true
