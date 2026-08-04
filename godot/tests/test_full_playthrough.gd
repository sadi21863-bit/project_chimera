extends SceneTree

## A single full case, start to finish, exercising every major system together: First Choice ->
## travel -> clue discovery -> interrogation -> a sneaking catch -> a botched search -> an
## accusation -> the ending screen + flashback. Complements (doesn't replace) the many focused
## per-system tests already covering each piece's edge cases and exact timing.

var _main
var _phase := 0
var _wait := 0

func _process(_delta: float) -> bool:
	_wait += 1
	match _phase:
		0:
			root.get_node("Investigation").reset()
			root.get_node("Standing").reset()
			root.get_node("Consequences").reset()
			root.get_node("Difficulty").set_preset("medium")
			var game_flow = root.get_node("GameFlow")
			game_flow.phase = game_flow.Phase.CHOICE
			game_flow.current_ending_id = ""
			root.get_node("LocationManager").current_id = "dorm"
			root.get_node("LocationManager").visited = {"dorm": true}

			_main = load("res://scenes/main.tscn").instantiate()
			root.add_child(_main)
			_wait = 0
			_phase = 1
			return false
		1:
			if _wait < 5: return false
			# the First Choice
			root.get_node("GameFlow").choose_murder()
			# travel out and back — exercises LocationManager + the scene-swap host
			root.get_node("LocationManager").travel("detective_room")
			_wait = 0
			_phase = 2
			return false
		2:
			if _wait < 5: return false
			root.get_node("LocationManager").travel("dorm")
			_wait = 0
			_phase = 3
			return false
		3:
			if _wait < 5: return false
			_finish()
			return true
	return false


func _finish() -> void:
	var failures := 0
	var inv = root.get_node("Investigation")
	var case_file = root.get_node("CaseFile")
	var standing = root.get_node("Standing")
	var consequences = root.get_node("Consequences")
	var game_flow = root.get_node("GameFlow")
	var id := preload("res://scripts/interrogation/interrogation_data.gd")
	var ending_content := preload("res://scripts/case/ending_content.gd")
	var case_data := preload("res://scripts/case/case_data.gd")

	# clue discovery builds sam's case strength
	inv.discover_clue("clue_wiring")
	inv.discover_clue("clue_camera")
	if case_file.case_strength("sam") < 2:
		failures += 1; print("FAIL: sam's case strength should be 2 after discovering both clues")

	# a high-trust interrogation topic reveals a clue
	standing.adjust("sam", 1.0)
	var resp: Dictionary = id.respond_to_topic("sam", "the_camera", standing.get_standing("sam"))
	if str(resp.get("reveal_clue", "")) == "":
		failures += 1; print("FAIL: a high-trust interrogation topic should reveal a clue")

	# getting caught trespassing strikes (Medium: suspicion meter)
	consequences.record_catch(23.0)
	if consequences.strikes != 1:
		failures += 1; print("FAIL: getting caught trespassing should add a strike, got %d" % consequences.strikes)

	# a botched risky search strikes again
	consequences.record_risky_search(true, false)
	if consequences.strikes != 2:
		failures += 1; print("FAIL: a botched risky search should add a second strike, got %d" % consequences.strikes)

	# one clue for every other suspect unlocks accusations
	inv.discover_clue("clue_keys")          # alex
	inv.discover_clue("clue_rehearsal")     # jordan
	inv.discover_clue("clue_pills")         # riley
	inv.discover_clue("clue_moved_object")  # morgan
	inv.discover_clue("clue_sketch")        # casey
	if not case_file.accusations_unlocked():
		failures += 1; print("FAIL: accusations should unlock once everyone has at least 1 clue")

	# accuse sam
	var result: Dictionary = case_file.accuse("sam")
	if not result.get("accepted", false) or str(result.get("ending_id", "")) != "ending_sam":
		failures += 1; print("FAIL: accusing sam (2/%s) should be accepted with ending_sam" % str(case_data.SUSPECTS["sam"]["threshold"]))
	game_flow.trigger_ending(str(result.get("ending_id", "")))
	if game_flow.phase != game_flow.Phase.ENDING or game_flow.current_ending_id != "ending_sam":
		failures += 1; print("FAIL: GameFlow should reach Phase.ENDING with ending_sam")

	# the ending's flashback reflects what was actually discovered
	var discovered: Array = []
	for clue_id in case_data.CLUES:
		if inv.is_discovered(clue_id):
			discovered.append(clue_id)
	var flashback: Array = ending_content.build_flashback(discovered)
	if flashback.is_empty():
		failures += 1; print("FAIL: the flashback should include the discovered clues' truths")

	if failures == 0:
		print("PASS: test_full_playthrough")
	quit(failures)
