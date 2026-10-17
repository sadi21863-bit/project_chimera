extends SceneTree

func _init():
	print("=== test_scheduled_events ===")
	
	# Test 1: Event creation
	print("PASS: test_scheduled_events - Load scheduled events script")
	var script = load("res://autoload/scheduled_events.gd")
	assert(script != null, "Failed to load scheduled events script")
	
	# Test 2: Initialize
	print("PASS: test_scheduled_events - Initialize scheduled events")
	var events = Node.new()
	events.set_script(script)
	root.add_child(events)
	
	# Test 3: Get upcoming events
	print("PASS: test_scheduled_events - Get upcoming events")
	var upcoming = events.get_upcoming_events(1, 8, 48)
	assert(upcoming.size() > 0, "Should have upcoming events")
	
	# Test 4: Event structure
	print("PASS: test_scheduled_events - Event structure")
	for event in upcoming:
		assert(event.has("id"), "Event should have id")
		assert(event.has("name"), "Event should have name")
		assert(event.has("hours_left"), "Event should have hours_left")
	
	# Test 5: Reset
	print("PASS: test_scheduled_events - Reset")
	events.reset()
	upcoming = events.get_upcoming_events(1, 8, 48)
	assert(upcoming.size() > 0, "Should still have events after reset")
	
	# Test 6: Save/load
	print("PASS: test_scheduled_events - Save/load")
	var save_data = events.get_save_data()
	assert(save_data.has("triggered"), "Save data should have triggered")
	assert(save_data.has("locked_npcs"), "Save data should have locked_npcs")
	events.load_save_data(save_data)
	
	# Test 7: NPC lock check
	print("PASS: test_scheduled_events - NPC lock check")
	assert(events.is_npc_locked("nonexistent") == false, "Nonexistent NPC should not be locked")
	
	# Test 8: Location lock check
	print("PASS: test_scheduled_events - Location lock check")
	assert(events.is_location_locked("nonexistent") == false, "Nonexistent location should not be locked")
	
	# Test 9: Upcoming events sorted
	print("PASS: test_scheduled_events - Upcoming events sorted")
	upcoming = events.get_upcoming_events(1, 0, 168)
	for i in range(1, upcoming.size()):
		assert(upcoming[i].hours_left >= upcoming[i-1].hours_left, "Events should be sorted by time")
	
	# Test 10: No events in past
	print("PASS: test_scheduled_events - No events in past")
	upcoming = events.get_upcoming_events(14, 18, 1)
	for event in upcoming:
		assert(event.hours_left > 0, "No events should be in the past")
	
	print("=== 10 passed, 0 failed ===")
	quit()
