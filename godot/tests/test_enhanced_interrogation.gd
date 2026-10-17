extends SceneTree

var _phase := 0
var _eid = preload("res://scripts/interrogation/enhanced_interrogation_data.gd")

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var inv = preload("res://autoload/investigation.gd").new(); inv.set("persist_enabled", false)
		var st = preload("res://autoload/standing.gd").new(); st.set("persist_enabled", false)
		var panel = load("res://scenes/ui/enhanced_interrogation_panel.tscn").instantiate()
		root.add_child(panel)
		var failures := 0

		# Test 1: Panel opens with style buttons
		panel.open("riley", inv, st)
		var style_count: int = panel.get_node("Panel/VBox/StyleRow").get_child_count()
		if style_count < 3:
			failures += 1; print("FAIL: should have 3 style buttons, got %d" % style_count)

		# Test 2: Pressure bar exists
		var pressure_bar = panel.get_node("Panel/VBox/PressureRow/PressureBar")
		if pressure_bar == null:
			failures += 1; print("FAIL: pressure bar not found")

		# Test 3: Selecting a topic increases pressure
		var pressure_before: int = panel.get_pressure()
		panel.select_topic("that_night")
		var pressure_after: int = panel.get_pressure()
		if pressure_after <= pressure_before:
			failures += 1; print("FAIL: pressure should increase after topic, got %d -> %d" % [pressure_before, pressure_after])

		# Test 4: Style selection works
		panel._on_style_selected(_eid.Style.EMPATHETIC)
		if panel._selected_style != _eid.Style.EMPATHETIC:
			failures += 1; print("FAIL: style should be EMPATHETIC")

		# Test 5: Enhanced data has branching response
		var result: Dictionary = _eid.get_branching_response("riley", "that_night", _eid.Style.EMPATHETIC, 0.0)
		if result.text.is_empty():
			failures += 1; print("FAIL: riley should have branching response")

		# Test 6: Style modifier works
		var modifier: Dictionary = _eid.get_style_modifier(_eid.Style.CONFRONTATIONAL)
		if modifier.resistance_delta <= 0.0:
			failures += 1; print("FAIL: CONFRONTATIONAL should have positive resistance_delta")

		# Test 7: Follow-up unlock works
		panel._on_style_selected(_eid.Style.EMPATHETIC)
		panel.select_topic("that_night")
		var follow_up_found := false
		for topic_id in panel._unlocked_topics:
			if topic_id != "that_night":
				follow_up_found = true
				break
		if not follow_up_found:
			failures += 1; print("FAIL: that_night should have follow_up unlocked")

		# Test 8: Free text increases pressure
		var p_before: int = panel.get_pressure()
		panel.submit_free_text("tell me the truth")
		var p_after: int = panel.get_pressure()
		if p_after <= p_before:
			failures += 1; print("FAIL: free text should increase pressure")

		# Test 9: Base topics still work
		panel.open("alex", inv, st)
		var topic_count: int = panel.get_node("Panel/VBox/Topics").get_child_count()
		if topic_count < 1:
			failures += 1; print("FAIL: alex should have at least 1 topic button")

		if failures == 0:
			print("PASS: test_enhanced_interrogation")
		quit(failures)
		return true
	return false
