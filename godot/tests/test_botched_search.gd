extends SceneTree

## Unit-level: Consequences.record_risky_search()'s restricted-or-witnessed strike logic.
## Integration-level: selecting a risky action on a real restricted, unwatched search point (via
## the actual SearchPanel -> main.gd wiring) adds a strike end to end.

var _main
var _phase := 0
var _wait := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		var consequences = root.get_node("Consequences")
		var game_flow = root.get_node("GameFlow")

		# --- unit: Consequences.record_risky_search() ---
		consequences.reset()
		game_flow.phase = game_flow.Phase.INVESTIGATION
		consequences.record_risky_search(false, false)  # safe: not restricted, not witnessed
		var failures := 0
		if consequences.strikes != 0:
			failures += 1; print("FAIL: a risky action performed safely should not strike")
		consequences.record_risky_search(true, false)  # restricted alone
		if consequences.strikes != 1:
			failures += 1; print("FAIL: a risky action performed restricted should strike")
		consequences.record_risky_search(false, true)  # witnessed alone
		if consequences.strikes != 2:
			failures += 1; print("FAIL: a risky action performed witnessed should strike")
		if failures > 0:
			quit(failures)
			return true

		# --- integration: real SearchPanel -> main.gd -> Consequences wiring ---
		consequences.reset()
		game_flow.phase = game_flow.Phase.CHOICE
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		game_flow.choose_murder()  # -> INVESTIGATION
		var sched = root.get_node("Scheduler")
		sched.set_time(23.0, 1)  # bedroom_2 (jordan's room) closes at 22:00

		var hall = _main.get_node("LocationHost/CrestwoodHall")
		for npc in hall.npcs:
			if npc.npc_id == "jordan":
				npc.current_room = "kitchen"
				npc.global_position = hall.room_markers["kitchen"].global_position
			else:
				npc.global_position = Vector2(-2000, -2000)  # nobody witnesses

		_phase = 1
		return false

	_wait += 1
	if _wait < 3:
		return false

	var search_panel = _main.get_node("UI/SearchPanel")
	var inv = root.get_node("Investigation")
	search_panel.open("jordan_dresser", inv)
	search_panel.select_action("open_drawer")  # risky, room bedroom_2

	var consequences = root.get_node("Consequences")
	var failures := 0
	if consequences.strikes != 1:
		failures += 1; print("FAIL: a risky search in a restricted, unwatched room should strike end to end, got %d" % consequences.strikes)

	if failures == 0:
		print("PASS: test_botched_search")
	quit(failures)
	return true
