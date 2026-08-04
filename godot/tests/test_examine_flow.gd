extends SceneTree

## Functional playtest in code: spawn the real game, place the detective on a clue hotspot,
## let physics register the Area2D overlap, fire interact, and assert the clue is discovered
## and the prompt reports "Examined". This exercises the full Plan A loop without a human.

var _main
var _det
var _hotspot
var _phase := 0
var _wait := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		var inv0 = root.get_node_or_null("Investigation")
		if inv0 != null:
			inv0.reset()  # idempotent: clear any persisted discoveries from a prior run
		var hall = _main.get_node("LocationHost/CrestwoodHall")
		_det = hall.detective
		for ch in hall.get_children():
			if ch is ClueHotspot:
				_hotspot = ch
				break
		if _det == null or _hotspot == null:
			print("FAIL: detective or hotspot missing"); quit(1); return true
		_det.global_position = _hotspot.global_position  # stand on the clue
		_phase = 1
		return false

	# give physics several frames to register the area overlap
	_wait += 1
	if _wait < 15:
		return false

	var interactor = _det.get_node("Interactor")
	var inv = root.get_node("Investigation")
	# Several clues share a room and overlap, so assert against whichever hotspot the
	# interactor actually selected (not the specific one we positioned onto).
	var current = interactor.clue_target
	if current == null:
		print("FAIL: interactor did not detect any hotspot in reach")
		quit(1)
		return true

	var failures := 0
	if current.get_prompt() != "Examine":
		failures += 1; print("FAIL: prompt should be 'Examine' before examining")

	interactor.try_examine()  # the same call the E key triggers

	if inv.is_discovered(current.clue_id) != true:
		failures += 1; print("FAIL: examine did not record the clue")
	if current.get_prompt() != "Examined":
		failures += 1; print("FAIL: prompt should be 'Examined' after examining")

	if failures == 0:
		print("PASS: test_examine_flow — detected hotspot, examined, clue recorded, prompt updated")
	quit(failures)
	return true
