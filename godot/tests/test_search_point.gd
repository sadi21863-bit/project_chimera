extends SceneTree

func _initialize() -> void:
	var interactor_script := preload("res://scripts/player/interactor.gd")
	var search_script := preload("res://scripts/player/search_point.gd")
	var npc_script := preload("res://scripts/player/npc_interactable.gd")
	var failures := 0

	# A SearchPoint is an examine target (want_clue=true), an NPC is not.
	var sp = search_script.new(); sp.position = Vector2(10, 0)
	var npc = npc_script.new(); npc.position = Vector2(20, 0)
	var examine = interactor_script._pick_nearest([sp, npc], Vector2.ZERO, true)
	if examine != sp:
		failures += 1; print("FAIL: SearchPoint should be the examine target")
	var talk = interactor_script._pick_nearest([sp, npc], Vector2.ZERO, false)
	if talk != npc:
		failures += 1; print("FAIL: NPC should be the talk target")

	# interact() emits search_requested with the point id.
	var captured := {"id": ""}
	sp.point_id = "common_couch"
	sp.search_requested.connect(func(pid): captured["id"] = pid)
	sp.interact()
	if captured["id"] != "common_couch":
		failures += 1; print("FAIL: interact should emit search_requested(point_id)")

	sp.free(); npc.free()
	if failures == 0:
		print("PASS: test_search_point")
	quit(failures)
