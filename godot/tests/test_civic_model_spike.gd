extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/prototypes/civic_model_spike.tscn")
	if scene == null:
		print("FAIL: civic model scene could not load")
		quit(1)
		return
	var spike: Node3D = scene.instantiate()
	root.add_child(spike)
	await process_frame
	var failures := 0
	if spike.get_node_or_null("Room") == null:
		print("FAIL: imported room missing")
		failures += 1
	if spike.get_node_or_null("Camera3D") == null:
		print("FAIL: camera missing")
		failures += 1
	if spike.get_node_or_null("KeyLight") == null:
		print("FAIL: key light missing")
		failures += 1
	var room := spike.get_node_or_null("Room")
	var mesh_count := _count_meshes(room) if room != null else 0
	print("Civic room meshes: %d" % mesh_count)
	if mesh_count == 0:
		print("FAIL: imported room has no meshes")
		failures += 1
	if failures == 0:
		print("PASS: test_civic_model_spike")
	spike.queue_free()
	quit(failures)


func _count_meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _count_meshes(child)
	return count
