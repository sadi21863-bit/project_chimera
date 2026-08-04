extends SceneTree

## Functional check: on Medium (suspicion meter), stand in a bedroom after its close hour while
## the owner is elsewhere. Given enough time the meter fills and the detective gets ejected + the
## owner's standing drops.

var _main
var _hall
var _det
var _sched
var _standing
var _phase := 0
var _elapsed := 0.0
var _start_standing := 0.0

func _process(delta: float) -> bool:
	if _phase == 0:
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		root.get_node("Difficulty").set_preset("medium")
		_sched = root.get_node("Scheduler")
		_sched.set_time(23.0)  # bedroom_1 closes at 22:00
		_standing = root.get_node("Standing")
		_standing.reset()
		_hall = _main.get_node("LocationHost/CrestwoodHall")
		_det = _hall.detective
		# move alex (bedroom_1's owner) out of their room so it's unoccupied
		for npc in _hall.npcs:
			if npc.npc_id == "alex":
				npc.current_room = "kitchen"
				npc.global_position = _hall.room_markers["kitchen"].global_position
		_det.global_position = _hall.room_markers["bedroom_1"].global_position
		_start_standing = _standing.get_standing("alex")
		_phase = 1
		return false

	_elapsed += delta
	if _elapsed < 3.5:  # the meter fills at 0.35/s; give it a comfortable margin
		return false

	var failures := 0
	var hallway_pos: Vector2 = _hall.room_markers["hallway"].global_position
	if _det.global_position.distance_to(hallway_pos) > 5.0:
		failures += 1; print("FAIL: detective should have been ejected to the hallway")
	if _standing.get_standing("alex") >= _start_standing:
		failures += 1; print("FAIL: standing with alex should have dropped after being caught")

	if failures == 0:
		print("PASS: test_sneaking_wiring")
	quit(failures)
	return true
