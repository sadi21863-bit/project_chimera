extends SceneTree

var _phase := 0
var _deadline := 8.0

## Safety net: if the body below throws before quit() is reached, this guarantees the test
## terminates instead of hanging the whole suite. (It used to: `_phase` was set to 1 first, so
## after a compile error the next frames just fell through to `return false` forever.)
func _process(delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		# NOTE: load(), not preload(). preload() resolves at compile time, and at that point
		# autoload identifiers such as SFXHelper (used at tutorial.gd:116) are not yet
		# registered -> "Identifier not found" -> this script fails to compile -> hang.
		var tut_script = load("res://autoload/tutorial.gd")
		if tut_script == null:
			print("FAIL: tutorial.gd failed to load")
			quit(1)
			return true
		var tut = tut_script.new()
		if tut == null:
			print("FAIL: tutorial.gd failed to instantiate")
			quit(1)
			return true
		tut.set("persist_enabled", false)
		root.add_child(tut)
		var failures := 0

		# Test 1: Tutorial starts inactive
		if tut._active:
			failures += 1; print("FAIL: tutorial should start inactive")

		# Test 2: Start activates tutorial
		tut.start()
		if not tut._active:
			failures += 1; print("FAIL: start should activate tutorial")
		if not tut.is_hint_shown("welcome"):
			failures += 1; print("FAIL: welcome hint should be shown on start")

		# Test 3: Clue found triggers hints
		tut.on_clue_found()
		if not tut.is_hint_shown("case_file"):
			failures += 1; print("FAIL: case_file hint should show after clue found")
		if not tut.is_hint_shown("notebook"):
			failures += 1; print("FAIL: notebook hint should show after clue found")

		# Test 4: NPC approach triggers hint
		tut.on_npc_approached()
		if not tut.is_hint_shown("talk"):
			failures += 1; print("FAIL: talk hint should show after NPC approach")

		# Test 5: Interrogation triggers hints
		tut.on_interrogation_started()
		if not tut.is_hint_shown("interrogation_styles"):
			failures += 1; print("FAIL: interrogation_styles hint should show")
		if not tut.is_hint_shown("standing"):
			failures += 1; print("FAIL: standing hint should show")

		# Test 6: Day passed triggers hints
		tut.on_day_passed()
		if not tut.is_hint_shown("travel"):
			failures += 1; print("FAIL: travel hint should show after day passed")
		if not tut.is_hint_shown("time"):
			failures += 1; print("FAIL: time hint should show after day passed")

		# Test 7: Hint content exists
		var hint: Dictionary = tut.get_hint("welcome")
		if hint.is_empty():
			failures += 1; print("FAIL: get_hint('welcome') should return data")
		elif str(hint.get("title", "")) != "Welcome to Crestwood Hall":
			failures += 1; print("FAIL: welcome hint title mismatch")

		# Test 8: Reset clears state
		tut.reset()
		if tut.is_hint_shown("welcome"):
			failures += 1; print("FAIL: reset should clear shown hints")
		if tut._active:
			failures += 1; print("FAIL: reset should deactivate tutorial")

		# Test 9: Hints don't show twice
		tut.start()
		var count_before: int = tut._shown.size()
		tut.on_clue_found()
		var count_after: int = tut._shown.size()
		# Should not add new hints since they're already shown (from reset, they're cleared)
		# Actually after reset, they're cleared, so this should add them again
		if count_after <= count_before:
			failures += 1; print("FAIL: hints should show after reset")

		if failures == 0:
			print("PASS: test_tutorial")
		quit(failures)
		return true

	_deadline -= delta
	if _deadline <= 0.0:
		print("FAIL: test_tutorial timed out (body threw before quit())")
		quit(1)
		return true
	return false
