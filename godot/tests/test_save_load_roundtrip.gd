extends SceneTree

## Two-part check via the real ObserverPanel save/load handlers:
## 1) saving while in the dorm bundles the dorm's NPCs (the CrestwoodHall path that stopped
##    existing when World Expansion W1 moved the dorm under LocationHost).
## 2) driving state forward (a strike, a phase change, a travel), saving, mutating everything
##    back to defaults, then loading actually restores it.

var _main
var _phase := 0
var _wait := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		_phase = 1
		return false

	_wait += 1
	if _wait < 3:
		return false

	if _phase == 1:
		# still in the dorm here — save and confirm the CrestwoodHall path bug is fixed
		var observer = _main.get_node("UI/ObserverPanel")
		observer._on_save_pressed()
		var save_manager = root.get_node("SaveManager")
		var saved: Dictionary = save_manager.load_game(save_manager.DEFAULT_SLOT)
		if not saved.has("hall"):
			print("FAIL: save should bundle the dorm's NPCs (the CrestwoodHall path bug)")
			quit(1)
			return true

		var consequences = root.get_node("Consequences")
		consequences.reset()
		var game_flow = root.get_node("GameFlow")
		var location_manager = root.get_node("LocationManager")
		consequences.strikes = 2
		game_flow.choose_murder()  # -> Phase.INVESTIGATION
		location_manager.travel("detective_room")

		_wait = 0
		_phase = 2
		return false

	if _phase == 2:
		if _wait < 3:
			return false

		var observer = _main.get_node("UI/ObserverPanel")
		observer._on_save_pressed()

		var save_manager = root.get_node("SaveManager")
		var saved: Dictionary = save_manager.load_game(save_manager.DEFAULT_SLOT)
		var failures := 0
		for key in ["game_flow", "consequences", "location_manager", "case_file"]:
			if not saved.has(key):
				failures += 1; print("FAIL: save should bundle '%s'" % key)

		# mutate everything back to defaults to prove load actually restores it
		var consequences2 = root.get_node("Consequences")
		consequences2.reset()
		var game_flow2 = root.get_node("GameFlow")
		game_flow2.phase = game_flow2.Phase.CHOICE
		var location_manager2 = root.get_node("LocationManager")
		location_manager2.current_id = "dorm"

		observer._on_load_pressed()

		if game_flow2.phase != game_flow2.Phase.INVESTIGATION:
			failures += 1; print("FAIL: GameFlow.phase should be restored to INVESTIGATION")
		if consequences2.strikes != 2:
			failures += 1; print("FAIL: Consequences.strikes should be restored to 2")
		if location_manager2.current_id != "detective_room":
			failures += 1; print("FAIL: LocationManager.current_id should be restored to detective_room")

		if failures == 0:
			print("PASS: test_save_load_roundtrip")
		quit(failures)
		return true

	return false
