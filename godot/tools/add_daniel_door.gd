extends SceneTree

## One-off tool: adds a "daniel_room" Marker2D + a LockedDoorTrigger (gated on the
## item_master_key clue, taken from Alex's desk) into Crestwood Hall.
##
## Run headless: godot --headless --path godot -s res://tools/add_daniel_door.gd

const SCENE_PATH := "res://scenes/dorm/crestwood_hall.tscn"
const MARKER_POS := Vector2(1080, 580)


func _initialize() -> void:
	var packed: PackedScene = load(SCENE_PATH)
	var root := packed.instantiate()
	var markers: Node2D = root.get_node("RoomMarkers")

	if not markers.has_node("daniel_room"):
		var marker := Marker2D.new()
		marker.name = "daniel_room"
		marker.position = MARKER_POS
		markers.add_child(marker)
		marker.owner = root

	if root.has_node("DoorToDanielroom"):
		root.get_node("DoorToDanielroom").free()

	var door := Area2D.new()
	door.name = "DoorToDanielroom"
	door.set_script(load("res://scripts/player/locked_door_trigger.gd"))
	door.set("dest_id", "daniel_room")
	door.set("dest_label", "Daniel's room")
	door.set("required_clue", "item_master_key")
	door.set("locked_message", "Daniel's door is locked. It probably needs a key.")
	door.position = MARKER_POS
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
	var err := ResourceSaver.save(new_packed, SCENE_PATH)
	if err != OK:
		printerr("failed to save %s: %d" % [SCENE_PATH, err])
	else:
		print("added Daniel's locked door to %s" % SCENE_PATH)
	root.free()
	print("ADD_DANIEL_DOOR_DONE")
	quit()
