extends SceneTree

var _failures := 0

func _initialize() -> void:
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await process_frame
	var location_manager := root.get_node("LocationManager")
	var location_host: Node2D = main.get_node("LocationHost")
	var outdoor_host: Node2D = main.get_node("OutdoorWorldHost")
	if location_host.get_child_count() != 1 or location_host.get_child(0).name != "CrestwoodHall":
		_fail("initial dorm missing")
	location_manager.travel("campus")
	await process_frame
	await process_frame
	await process_frame
	if outdoor_host.get_child_count() != 1:
		_fail("outdoor world was not created")
		var world: Node2D = null
	else:
		var world: Node2D = outdoor_host.get_child(0)
		if world.get("detective") == null:
			_fail("outdoor detective missing")
		if location_host.get_child_count() != 0:
			_fail("interior remained active outdoors")
		var world_data: Dictionary = main.get_world_save_data()
		if not bool(world_data.get("outdoor_active", false)):
			_fail("outdoor save state was not active")
		var world_id: int = world.get_instance_id()
		location_manager.travel("courtyard")
		await process_frame
		await process_frame
		if outdoor_host.get_child(0).get_instance_id() != world_id:
			_fail("courtyard replaced the persistent world")
		if world.get("logical_area") != "courtyard":
			_fail("courtyard logical area was not updated")
		location_manager.travel("university")
		await process_frame
		await process_frame
		await process_frame
		if world.visible:
			_fail("outdoor world stayed visible indoors")
		if location_host.get_child_count() != 1 or location_host.get_child(0).name != "University":
			_fail("university interior did not load")
		location_manager.travel("campus")
		await process_frame
		await process_frame
		await process_frame
		if outdoor_host.get_child(0).get_instance_id() != world_id:
			_fail("outdoor world was replaced after interior return")
		if world.get("detective").global_position.distance_to(Vector2(962.0, 590.0)) > 1.0:
			_fail("outdoor return position was not restored")
	if _failures == 0:
		print("PASS: test_outdoor_transitions")
	quit(_failures)


func _fail(message: String) -> void:
	_failures += 1
	print("FAIL: %s" % message)
