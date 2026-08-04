extends SceneTree

## One-off tool: adds a DoorTrigger to "campus" inside Crestwood Hall, the University, and the
## Police Station, so all three connect to the outdoor campus hub as an alternative to fast-travel.
##
## Run headless: godot --headless --path godot -s res://tools/add_campus_doors.gd

const TARGETS := [
	{"scene": "res://scenes/dorm/crestwood_hall.tscn", "pos": Vector2(300, 200)},
	{"scene": "res://scenes/locations/university.tscn", "pos": Vector2(400, 200)},
	{"scene": "res://scenes/locations/police_station.tscn", "pos": Vector2(500, 350)},
]


func _initialize() -> void:
	for t in TARGETS:
		_add_door(t["scene"], t["pos"])
	print("ADD_CAMPUS_DOORS_DONE")
	quit()


func _add_door(scene_path: String, pos: Vector2) -> void:
	var packed: PackedScene = load(scene_path)
	var root := packed.instantiate()

	if root.has_node("DoorToCampus"):
		root.get_node("DoorToCampus").free()

	var door := Area2D.new()
	door.name = "DoorToCampus"
	door.set_script(load("res://scripts/player/door_trigger.gd"))
	door.set("dest_id", "campus")
	door.set("dest_label", "the campus")
	door.position = pos
	root.add_child(door)
	door.owner = root

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	shape.shape = circle
	door.add_child(shape)
	shape.owner = root

	var new_packed := PackedScene.new()
	new_packed.pack(root)
	var err := ResourceSaver.save(new_packed, scene_path)
	if err != OK:
		printerr("failed to save %s: %d" % [scene_path, err])
	else:
		print("added campus door to %s" % scene_path)
	root.free()
