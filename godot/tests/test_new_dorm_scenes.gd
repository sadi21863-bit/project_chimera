extends SceneTree

func _initialize():
	print("=== Testing New Dorm Scenes ===")

	var scenes := [
		"res://scenes/dorm/bedroom_1.tscn",
		"res://scenes/dorm/bedroom_2.tscn",
		"res://scenes/dorm/bedroom_3.tscn",
		"res://scenes/dorm/bedroom_4.tscn",
		"res://scenes/dorm/bedroom_5.tscn",
		"res://scenes/dorm/bedroom_6.tscn",
		"res://scenes/dorm/common_room.tscn",
		"res://scenes/dorm/kitchen.tscn",
		"res://scenes/dorm/hallway.tscn",
		"res://scenes/dorm/bathroom.tscn",
		"res://scenes/dorm/daniel_room.tscn",
		"res://scenes/dorm/crestwood_hall.tscn",
	]

	var passed := 0
	var failed := 0

	for scene_path in scenes:
		var scene = load(scene_path)
		if scene == null:
			print("FAIL: %s (could not load)" % scene_path.get_file())
			failed += 1
			continue
		var instance = scene.instantiate()
		if instance == null:
			print("FAIL: %s (could not instantiate)" % scene_path.get_file())
			failed += 1
			continue
		# Scenes spawn search points dynamically. Check for SearchPoint children.
		var sp_count := 0
		for child in instance.get_children():
			if child is SearchPoint:
				sp_count += 1
		# Also check a static SearchPoints container if present
		var container = instance.get_node_or_null("SearchPoints")
		if container:
			sp_count += container.get_child_count()
		print("OK: %s (%d search points)" % [scene_path.get_file(), sp_count])
		passed += 1
		instance.queue_free()

	print("")
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit()
