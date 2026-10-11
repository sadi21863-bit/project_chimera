extends SceneTree

const DORM := "res://scenes/dorm/crestwood_hall.tscn"

func _initialize() -> void:
	var scene: PackedScene = load(DORM)
	if scene == null:
		print("FAIL: dorm scene could not load")
		quit(1)
		return
	var dorm: Node2D = scene.instantiate()
	root.add_child(dorm)
	await process_frame
	await process_frame
	var failures := 0

	var backdrop: ArchivalBackdrop = dorm.get_node_or_null("Backdrop") as ArchivalBackdrop
	if backdrop == null:
		print("FAIL: Backdrop node missing")
		failures += 1
	else:
		if not backdrop.has_texture():
			print("FAIL: backdrop texture did not load")
			failures += 1
		if not backdrop.covers_room():
			print("FAIL: backdrop does not cover the 1280x720 room")
			failures += 1
		if backdrop.z_index >= 0:
			print("FAIL: backdrop must draw behind gameplay nodes")
			failures += 1

	failures += _check_legacy_hidden(dorm, "Floor/TileBase")
	failures += _check_legacy_hidden(dorm, "Walls/NorthVisual")
	failures += _check_legacy_hidden(dorm, "Walls/SouthVisual")
	failures += _check_legacy_hidden(dorm, "Walls/WestVisual")
	failures += _check_legacy_hidden(dorm, "Walls/EastVisual")
	failures += _check_legacy_hidden(dorm, "CorridorWalls/WestVisual")
	failures += _check_legacy_hidden(dorm, "CorridorWalls/EastVisual")
	failures += _check_legacy_hidden(dorm, "InteriorWalls/UpperCommon_WestVisual")
	failures += _check_legacy_hidden(dorm, "InteriorWalls/UpperCommon_EastVisual")

	failures += _check_preserved(dorm, "Walls/North")
	failures += _check_preserved(dorm, "NavigationRegion2D")
	failures += _check_preserved(dorm, "RoomMarkers")
	failures += _check_preserved(dorm, "DoorToCampus")
	failures += _check_preserved(dorm, "DoorToUniversity")

	if backdrop != null:
		backdrop.set_night(true)
		if not backdrop.is_night_visible():
			print("FAIL: night backdrop did not become visible")
			failures += 1
		backdrop.set_night(false)
		if backdrop.is_night_visible():
			print("FAIL: day backdrop did not become visible")
			failures += 1

	if ArchivalBackdrop.is_night(23.0) != true:
		print("FAIL: 23:00 should be night")
		failures += 1
	if ArchivalBackdrop.is_night(12.0) != false:
		print("FAIL: 12:00 should be day")
		failures += 1
	if ArchivalBackdrop.is_night(4.0) != true:
		print("FAIL: 04:00 should be night")
		failures += 1

	var furniture := dorm.get_node_or_null("Furniture")
	if furniture != null and furniture.get_child_count() > 0:
		print("FAIL: legacy furniture placers were added over the backdrop")
		failures += 1

	if failures == 0:
		print("PASS: test_archival_backdrop")
	dorm.queue_free()
	quit(failures)


func _check_legacy_hidden(dorm: Node, path: String) -> int:
	var node := dorm.get_node_or_null(NodePath(path)) as CanvasItem
	if node == null:
		print("FAIL: missing legacy visual %s" % path)
		return 1
	if node.visible:
		print("FAIL: legacy visual still visible: %s" % path)
		return 1
	return 0


func _check_preserved(dorm: Node, path: String) -> int:
	if dorm.get_node_or_null(NodePath(path)) == null:
		print("FAIL: gameplay node was removed: %s" % path)
		return 1
	return 0
