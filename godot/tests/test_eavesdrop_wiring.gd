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
		for npc in _hall.npcs:
			if npc.npc_id == "morgan":
				npc.global_position = Vector2(400, 400)
			elif npc.npc_id == "casey":
				npc.global_position = Vector2(420, 400)
		_hall.detective.global_position = Vector2(430, 400)
		return false
	_frames += 1
	if _frames < 5:
		return false
	var inv = root.get_node("Investigation")
	if inv.is_discovered("clue_moved_object"):
		print("PASS: test_eavesdrop_wiring — overheard morgan+casey, revealed clue_moved_object")
		quit(0)
	else:
		print("FAIL: overhearing morgan+casey should reveal clue_moved_object")
		quit(1)
	return true
