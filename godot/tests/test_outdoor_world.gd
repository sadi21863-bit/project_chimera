extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/locations/outdoor_world.tscn")
	if scene == null:
		print("FAIL: outdoor_world could not load")
		quit(1)
		return
	var world: Node2D = scene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var failures := 0
	if world.get("detective") == null:
		print("FAIL: outdoor detective missing")
		failures += 1
	if world.get_node_or_null("Campus") == null:
		print("FAIL: campus missing")
		failures += 1
	if world.get_node_or_null("Courtyard") == null:
		print("FAIL: courtyard missing")
		failures += 1
	if world.get_node_or_null("NavigationBridge") == null:
		print("FAIL: navigation bridge missing")
		failures += 1
	var detective := world.get("detective") as CharacterBody2D
	if detective != null:
		var camera := detective.get_node_or_null("Camera2D") as Camera2D
		if camera == null or camera.limit_right != 2600 or camera.limit_bottom != 900:
			print("FAIL: outdoor camera limits invalid")
			failures += 1
	var east := world.get_node_or_null("Campus/Walls/East") as CollisionShape2D
	var west := world.get_node_or_null("Courtyard/Walls/West") as CollisionShape2D
	if east == null or west == null or not east.disabled or not west.disabled:
		print("FAIL: outdoor boundary opening invalid")
		failures += 1
	var university_portal := world.get_node_or_null("Campus/DoorToUniversity")
	if not university_portal is BuildingPortal:
		print("FAIL: university building portal missing")
		failures += 1
	if world.get_world_bounds() != Rect2(Vector2.ZERO, Vector2(2600.0, 900.0)):
		print("FAIL: outdoor world bounds invalid")
		failures += 1
	if failures == 0:
		print("PASS: test_outdoor_world")
	world.queue_free()
	quit(failures)
