extends SceneTree

var _phase := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		root.get_node("Investigation").reset()
		var failures := 0
		var panel = main.get_node("UI/SearchPanel")
		var hall = main.get_node("LocationHost/CrestwoodHall")

		# search points now live inside each room's own scene (bedroom_N.tscn,
		# hallway.tscn, etc.) — the dorm hub must NOT duplicate them
		var spawned := 0
		for ch in hall.get_children():
			if ch is SearchPoint:
				spawned += 1
		if spawned != 0:
			failures += 1; print("FAIL: dorm hub should not duplicate owned-room SearchPoints (%d found)" % spawned)

		# requesting a search opens the panel; an action reveals a clue
		main._on_search_requested("common_room_couch")
		if not panel.visible:
			failures += 1; print("FAIL: search request should open the panel")
		panel.select_action("check_under")
		if not root.get_node("Investigation").is_discovered("clue_logbook"):
			failures += 1; print("FAIL: searching the couch should reveal clue_logbook")

		if failures == 0:
			print("PASS: test_search_wiring")
		quit(failures)
		return true
	return false
