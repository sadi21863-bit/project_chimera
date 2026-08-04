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

		# search points were spawned into the dorm
		var spawned := 0
		for ch in hall.get_children():
			if ch is SearchPoint:
				spawned += 1
		if spawned < 1:
			failures += 1; print("FAIL: no SearchPoints spawned in the dorm")

		# requesting a search opens the panel; an action reveals a clue
		main._on_search_requested("common_couch")
		if not panel.visible:
			failures += 1; print("FAIL: search request should open the panel")
		panel.select_action("look_under")
		if not root.get_node("Investigation").is_discovered("clue_logbook"):
			failures += 1; print("FAIL: searching the couch should reveal clue_logbook")

		if failures == 0:
			print("PASS: test_search_wiring")
		quit(failures)
		return true
	return false
