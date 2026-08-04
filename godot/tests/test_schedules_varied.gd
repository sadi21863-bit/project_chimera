extends SceneTree

## Verifies NPCs no longer move in lockstep: at several hours, their scheduled target rooms
## should span more than one room.

func _initialize() -> void:
	var factory := preload("res://resources/npc_profiles/npc_profile_factory.gd")
	var profiles = factory.create_all_profiles()
	var failures := 0
	for hour in [9.0, 12.0, 15.0, 20.0]:
		var rooms := {}
		for p in profiles:
			var entry = p.schedule.get_entry_for_hour(hour)
			if entry != null:
				rooms[entry.target_room] = true
		if rooms.size() < 2:
			failures += 1
			print("FAIL: at hour %.0f all NPCs share one room (%s)" % [hour, rooms.keys()])
		else:
			print("  hour %.0f -> %d distinct rooms: %s" % [hour, rooms.size(), rooms.keys()])
	if failures == 0:
		print("PASS: test_schedules_varied — NPCs spread across rooms")
	quit(failures)
